// ============================================================
// Shaders.metal — Metal 着色器
// 负责：GPU 粒子渲染、辉光后处理、色差扭曲
// ============================================================

#include <metal_stdlib>
using namespace metal;

// ============================================================
// MARK: - 数据结构（与 Swift 端对齐）
// ============================================================

// GPU 粒子结构体（与 Swift 的 GPUParticle 完全对齐）
struct GPUParticle {
    float2 position;    // 屏幕坐标 (x, y)
    float2 velocity;    // 速度 (vx, vy)
    float4 color;       // 颜色 (r, g, b, a)
    float  size;        // 粒子大小（像素）
    float  life;        // 剩余生命 0~1
    float  decay;       // 每帧衰减量
    float  gravity;     // 重力加速度
    float  rotation;    // 自旋角度（弧度）
    float  rotSpeed;    // 自旋速度
    uint   kind;        // 粒子类型（0~8）
    float  padding;     // 对齐填充
};

// 顶点着色器输出
struct ParticleVertex {
    float4 position [[position]]; // 裁剪空间坐标
    float4 color;                 // 颜色（含 alpha）
    float  pointSize [[point_size]]; // 点大小
    float  rotation;              // 自旋角度
    uint   kind;                  // 粒子类型
};

// 后处理顶点
struct PostVertex {
    float4 position [[position]];
    float2 texCoord;
};

// Uniform 参数
struct ParticleUniforms {
    float2 viewportSize;  // 视口尺寸
    float  time;          // 当前时间（秒）
    float  padding;
};

// 辉光参数
struct BloomUniforms {
    float  threshold;     // 辉光阈值
    float  intensity;     // 辉光强度
    float  radius;        // 辉光半径
    float  padding;
};

// 色差参数
struct ChromaUniforms {
    float  strength;      // 色差强度
    float2 center;        // 色差中心点
    float  padding;
};

// ============================================================
// MARK: - GPU 粒子更新（Compute Shader）
// ============================================================

kernel void updateParticles(
    device GPUParticle* particles [[buffer(0)]],
    constant uint& count          [[buffer(1)]],
    uint id [[thread_position_in_grid]]
) {
    if (id >= count) return;
    
    GPUParticle p = particles[id];
    if (p.life <= 0.0) return;
    
    // 更新位置
    p.position += p.velocity;
    
    // 应用重力
    p.velocity.y += p.gravity;
    
    // 水平阻力（不同粒子类型不同阻力）
    float drag = 0.97;
    if (p.kind == 1) drag = 0.92;  // airFlow 更快消散
    if (p.kind == 6) drag = 0.99;  // firework 飞得更远
    p.velocity.x *= drag;
    
    // 更新自旋
    p.rotation += p.rotSpeed;
    
    // 衰减生命
    p.life -= p.decay;
    if (p.life < 0.0) p.life = 0.0;
    
    // 更新 alpha（非线性衰减，末尾快速消失）
    float lifeRatio = p.life;
    float alpha = lifeRatio * lifeRatio;  // 平方衰减，更自然
    p.color.a = alpha;
    
    // 粒子大小随生命缩小
    p.size *= 0.998;
    
    particles[id] = p;
}

// ============================================================
// MARK: - 粒子顶点着色器
// ============================================================

vertex ParticleVertex particleVertex(
    device const GPUParticle* particles [[buffer(0)]],
    constant ParticleUniforms& uniforms [[buffer(1)]],
    uint vid [[vertex_id]]
) {
    GPUParticle p = particles[vid];
    
    // 将屏幕坐标转换为 NDC（归一化设备坐标）
    float2 ndc = (p.position / uniforms.viewportSize) * 2.0 - 1.0;
    ndc.y = -ndc.y;  // 翻转 Y 轴（Metal 坐标系）
    
    ParticleVertex out;
    out.position = float4(ndc, 0.0, 1.0);
    out.color = p.color;
    out.pointSize = max(p.size * p.life + 1.0, 1.0);
    out.rotation = p.rotation;
    out.kind = p.kind;
    
    return out;
}

// ============================================================
// MARK: - 粒子片元着色器（七彩华丽效果）
// ============================================================

fragment float4 particleFragment(
    ParticleVertex in [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    // 将点坐标转换为 -1~1 范围
    float2 uv = pointCoord * 2.0 - 1.0;
    float dist = length(uv);
    
    float4 color = in.color;
    
    // 根据粒子类型选择不同的形状和效果
    switch (in.kind) {
        
        case 0: {
            // ionTrail — 离子拖尾：柔和圆形，带辉光
            if (dist > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.3, 1.0, dist);
            // 中心更亮（辉光核心）
            float glow = exp(-dist * dist * 3.0);
            color.rgb = mix(color.rgb, float3(1.0), glow * 0.5);
            color.a *= alpha;
            break;
        }
        
        case 1: {
            // airFlow — 空气流动：细长椭圆，带方向感
            // 旋转 UV
            float c = cos(in.rotation), s = sin(in.rotation);
            float2 ruv = float2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
            float d = length(float2(ruv.x * 2.5, ruv.y));  // 椭圆
            if (d > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.4, 1.0, d);
            color.a *= alpha * 0.7;
            break;
        }
        
        case 2: {
            // spinOut — 旋转甩出：星形粒子
            float angle = atan2(uv.y, uv.x) + in.rotation;
            float star = abs(cos(angle * 4.0)) * 0.4 + 0.6;
            float d = dist / star;
            if (d > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.5, 1.0, d);
            // 彩虹色调
            float hue = fmod(angle / (M_PI_F * 2.0) + 0.5, 1.0);
            float3 rainbow = float3(
                abs(hue * 6.0 - 3.0) - 1.0,
                2.0 - abs(hue * 6.0 - 2.0),
                2.0 - abs(hue * 6.0 - 4.0)
            );
            rainbow = saturate(rainbow);
            color.rgb = mix(color.rgb, rainbow, 0.4);
            color.a *= alpha;
            break;
        }
        
        case 3: {
            // burnSpark — 燃烧火花：不规则形状
            float noise = fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            float d = dist + noise * 0.3;
            if (d > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.2, 1.0, d);
            // 火焰色：中心白，外围橙红
            float3 fireColor = mix(float3(1.0, 0.9, 0.5), float3(1.0, 0.2, 0.0), dist);
            color.rgb = mix(color.rgb, fireColor, 0.7);
            color.a *= alpha;
            break;
        }
        
        case 4: {
            // ionSplash — 离子飞溅：菱形
            float d = abs(uv.x) + abs(uv.y);
            if (d > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.3, 1.0, d);
            // 七彩渐变
            float3 neonColor = float3(
                0.5 + 0.5 * sin(in.rotation),
                0.5 + 0.5 * sin(in.rotation + 2.094),
                0.5 + 0.5 * sin(in.rotation + 4.189)
            );
            color.rgb = mix(color.rgb, neonColor, 0.5);
            color.a *= alpha;
            break;
        }
        
        case 5: {
            // lockFlash — 锁定闪光：十字星形
            float cross = min(abs(uv.x), abs(uv.y));
            float d = dist - (1.0 - cross) * 0.5;
            if (d > 0.3) discard_fragment();
            float alpha = 1.0 - smoothstep(0.0, 0.3, d);
            // 白色闪光
            color.rgb = mix(color.rgb, float3(1.0), 0.8);
            color.a *= alpha;
            break;
        }
        
        case 6: {
            // firework — 烟花：圆形带尾迹
            if (dist > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.0, 1.0, dist);
            // 辉光效果
            float glow = exp(-dist * dist * 2.0);
            color.rgb += float3(glow * 0.8);
            color.a *= alpha;
            break;
        }
        
        case 7: {
            // firecracker — 鞭炮：小方块
            float2 box = abs(uv) - 0.7;
            float d = length(max(box, 0.0));
            if (d > 0.3) discard_fragment();
            float alpha = 1.0 - smoothstep(0.0, 0.3, d);
            color.a *= alpha;
            break;
        }
        
        case 8: {
            // hardDropTrail — 硬降拖尾：细长竖条
            float2 ruv = float2(uv.x * 3.0, uv.y);
            float d = length(ruv);
            if (d > 1.0) discard_fragment();
            float alpha = 1.0 - smoothstep(0.2, 1.0, d);
            color.a *= alpha * 0.6;
            break;
        }
        
        default: {
            if (dist > 1.0) discard_fragment();
            float alpha = 1.0 - dist;
            color.a *= alpha;
            break;
        }
    }
    
    // 防止 alpha 超出范围
    color.a = saturate(color.a);
    if (color.a < 0.01) discard_fragment();
    
    return color;
}

// ============================================================
// MARK: - 后处理：辉光（Bloom）
// ============================================================

// 辉光提取：只保留亮度超过阈值的像素
fragment float4 bloomExtract(
    PostVertex in [[stage_in]],
    texture2d<float> sceneTexture [[texture(0)]],
    constant BloomUniforms& uniforms [[buffer(0)]]
) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float4 color = sceneTexture.sample(s, in.texCoord);
    
    // 计算亮度
    float brightness = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    
    // 超过阈值才保留
    if (brightness > uniforms.threshold) {
        return color;
    }
    return float4(0.0);
}

// 高斯模糊（水平方向）
fragment float4 bloomBlurH(
    PostVertex in [[stage_in]],
    texture2d<float> inputTexture [[texture(0)]],
    constant BloomUniforms& uniforms [[buffer(0)]]
) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    
    float2 texelSize = 1.0 / float2(inputTexture.get_width(), inputTexture.get_height());
    float4 result = float4(0.0);
    
    // 9-tap 高斯核
    float weights[9] = {0.0093, 0.028, 0.065, 0.121, 0.175, 0.121, 0.065, 0.028, 0.0093};
    float offsets[9] = {-4, -3, -2, -1, 0, 1, 2, 3, 4};
    
    for (int i = 0; i < 9; i++) {
        float2 offset = float2(offsets[i] * texelSize.x * uniforms.radius, 0.0);
        result += inputTexture.sample(s, in.texCoord + offset) * weights[i];
    }
    
    return result;
}

// 高斯模糊（垂直方向）
fragment float4 bloomBlurV(
    PostVertex in [[stage_in]],
    texture2d<float> inputTexture [[texture(0)]],
    constant BloomUniforms& uniforms [[buffer(0)]]
) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    
    float2 texelSize = 1.0 / float2(inputTexture.get_width(), inputTexture.get_height());
    float4 result = float4(0.0);
    
    float weights[9] = {0.0093, 0.028, 0.065, 0.121, 0.175, 0.121, 0.065, 0.028, 0.0093};
    float offsets[9] = {-4, -3, -2, -1, 0, 1, 2, 3, 4};
    
    for (int i = 0; i < 9; i++) {
        float2 offset = float2(0.0, offsets[i] * texelSize.y * uniforms.radius);
        result += inputTexture.sample(s, in.texCoord + offset) * weights[i];
    }
    
    return result;
}

// 辉光合成：原图 + 模糊辉光
fragment float4 bloomComposite(
    PostVertex in [[stage_in]],
    texture2d<float> sceneTexture [[texture(0)]],
    texture2d<float> bloomTexture [[texture(1)]],
    constant BloomUniforms& uniforms [[buffer(0)]]
) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    
    float4 scene = sceneTexture.sample(s, in.texCoord);
    float4 bloom = bloomTexture.sample(s, in.texCoord);
    
    // 加法混合（辉光叠加）
    float4 result = scene + bloom * uniforms.intensity;
    
    // 色调映射（防止过曝）
    result.rgb = result.rgb / (result.rgb + 1.0);
    result.a = 1.0;
    
    return result;
}

// ============================================================
// MARK: - 后处理：色差扭曲（Chromatic Aberration）
// ============================================================

fragment float4 chromaticAberration(
    PostVertex in [[stage_in]],
    texture2d<float> inputTexture [[texture(0)]],
    constant ChromaUniforms& uniforms [[buffer(0)]]
) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    
    // 从中心点向外偏移，RGB 三通道各自偏移不同量
    float2 dir = in.texCoord - uniforms.center;
    float dist = length(dir);
    float2 offset = normalize(dir) * dist * uniforms.strength;
    
    float r = inputTexture.sample(s, in.texCoord + offset * 1.0).r;
    float g = inputTexture.sample(s, in.texCoord).g;
    float b = inputTexture.sample(s, in.texCoord - offset * 1.0).b;
    float a = inputTexture.sample(s, in.texCoord).a;
    
    return float4(r, g, b, a);
}

// ============================================================
// MARK: - 后处理顶点着色器（全屏四边形）
// ============================================================

vertex PostVertex postVertex(
    uint vid [[vertex_id]]
) {
    // 全屏四边形（两个三角形）
    float2 positions[6] = {
        float2(-1, -1), float2( 1, -1), float2(-1,  1),
        float2(-1,  1), float2( 1, -1), float2( 1,  1)
    };
    float2 texCoords[6] = {
        float2(0, 1), float2(1, 1), float2(0, 0),
        float2(0, 0), float2(1, 1), float2(1, 0)
    };
    
    PostVertex out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}
