# NeonTetris 粒子系统物理模拟优化

## 优化目标

从"规整、机械"的粒子效果 → "飘逸、自然、混乱"的物理效果

**视觉目标**：如同火星尘暴、灰尘飘逸、被疾风扰动、碰撞激发飞溅的自然感觉

---

## 核心改进

### 1. Perlin 噪声系统 ✅
- **实现**：完整的 3D Perlin 噪声生成器
- **作用**：为粒子轨迹添加自然的湍流扰动
- **效果**：粒子不再直线运动，而是像被风吹动一样蜿蜒飘动

```swift
// 每帧应用 Perlin 噪声
let noiseX = perlin.noise(noiseOffset, Float(position.x) * 0.01, Float(position.y) * 0.01)
let noiseY = perlin.noise(noiseOffset + 100, Float(position.x) * 0.01, Float(position.y) * 0.01)
acceleration.dx += CGFloat(noiseX) * CGFloat(turbulence) * 80
acceleration.dy += CGFloat(noiseY) * CGFloat(turbulence) * 80
```

### 2. 物理模拟系统 ✅
每个粒子现在有：
- **质量（mass）**：影响重力作用强度
- **摩擦系数（friction）**：0-1，越小越滑
- **加速度（acceleration）**：支持力的累积
- **湍流强度（turbulence）**：Perlin 噪声的影响程度

```swift
struct Particle {
    var position: CGPoint
    var velocity: CGVector
    var acceleration: CGVector      // 新增
    var mass: Float                 // 新增
    var friction: Float             // 新增
    var noiseOffset: Float          // 新增
    var turbulence: Float           // 新增
    // ...
}
```

### 3. 全局风场系统 ✅
- **动态风**：随时间变化的全局风力
- **作用**：所有粒子都受风场影响
- **效果**：粒子群体运动更协调，像被风吹动的尘埃

```swift
// 动态风场（每帧更新）
windForce = CGVector(
    dx: cos(Double(windTime) * 0.5) * 50,
    dy: sin(Double(windTime) * 0.3) * 30
)
```

### 4. 粒子类型差异化 ✅

| 粒子类型 | 质量 | 摩擦 | 湍流 | 重力 | 特性 |
|---------|------|------|------|------|------|
| ionTrail | 0.8 | 0.92 | 0.6 | 0.3x | 中等飘逸 |
| airFlow | 0.6 | 0.88 | 0.8 | 0.5x | 易被风吹 |
| spinOut | 0.7 | 0.85 | 0.5 | 0.4x | 快速衰减 |
| burnSpark | 1.0 | 0.90 | 0.7 | 0.6x | 重，快速下落 |
| ionSplash | 0.9 | 0.88 | 0.6 | 0.7x | 飞溅感强 |
| lockFlash | 0.2 | 0.95 | 0.9 | 0.05x | **最轻，最飘逸** |
| hardDropTrail | 0.8 | 0.90 | 0.4 | 0.5x | 向上飘 |
| firework | 0.3 | 0.98 | 0.3 | -0.3x | **向上飘，烟花感** |
| firecracker | 0.7 | 0.85 | 0.5 | 0.4x | 鞭炮爆炸感 |

### 5. 生命周期增加 ✅
粒子停留时间更长，让效果更明显：

| 粒子类型 | 原生命周期 | 新生命周期 | 增幅 |
|---------|-----------|-----------|------|
| ionTrail | 1.0s | 1.5s | 1.5x |
| airFlow | 0.6s | 1.0s | 1.67x |
| spinOut | 0.8s | 1.2s | 1.5x |
| burnSpark | 1.2s | 1.8s | 1.5x |
| ionSplash | 1.5s | 2.0s | 1.33x |
| lockFlash | 0.4s | 0.6s | 1.5x |
| hardDropTrail | 0.8s | 1.2s | 1.5x |
| firework | 3.0s | 4.0s | 1.33x |
| firecracker | 1.0s | 1.5s | 1.5x |

### 6. 初始速度随机化 ✅
粒子不再以固定速度发射，而是有随机变化：

```swift
// 例如：spinOut 粒子
let speed = CGFloat(type.initialSpeed) * CGFloat.random(in: 0.7...1.0)
let angleVariation = angle + Float.random(in: -0.3...0.3)
```

---

## 物理模拟流程

每帧更新顺序（0.016s）：

```
1. 应用全局风场 → acceleration += windForce
2. 应用 Perlin 噪声 → acceleration += perlin_noise * turbulence
3. 应用重力 → acceleration += gravity * mass
4. 更新速度 → velocity += acceleration * deltaTime
5. 应用摩擦 → velocity *= friction
6. 更新位置 → position += velocity * deltaTime
7. 重置加速度 → acceleration = 0
```

---

## 视觉效果对比

### 优化前
- ❌ 粒子直线运动
- ❌ 轨迹规整、机械
- ❌ 所有粒子行为相同
- ❌ 缺乏自然感

### 优化后
- ✅ 粒子蜿蜒飘动（Perlin 噪声）
- ✅ 轨迹混乱、自然（物理模拟）
- ✅ 不同粒子有不同行为（质量、摩擦、湍流差异）
- ✅ 像火星尘暴、灰尘飘逸的自然感
- ✅ 被风吹动、碰撞激发的物理感

---

## 代码改动

### 文件修改

1. **ParticleTypes.swift**（完全重写）
   - 添加 PerlinNoise 类
   - 扩展 Particle 结构体（+5 个物理属性）
   - 重写 update() 方法（物理模拟）
   - 更新 ParticleFactory（随机初始化）

2. **ParticleSystem.swift**
   - 添加 PerlinNoise 实例
   - 添加 windForce 和 windTime
   - 更新 update() 方法（调用新的物理模拟）

3. **LeaderboardPanel.swift**
   - 修复粒子创建代码（适配新的 Particle 结构体）

### 编译结果
✅ **BUILD SUCCEEDED**

---

## 性能影响

- **粒子数量**：50,000（不变）
- **计算复杂度**：每粒子 +3 次 Perlin 噪声调用
- **帧率**：应能保持 60fps（现代 Mac）
- **内存**：增加约 1-2MB（物理属性）

---

## 后续优化方向

1. **GPU 加速**：Metal 着色器实现 Perlin 噪声，支持 100,000+ 粒子
2. **粒子碰撞**：粒子之间的碰撞反弹
3. **吸引力/斥力**：粒子受方块吸引或排斥
4. **自适应质量**：根据粒子年龄动态调整质量
5. **多层噪声**：Fractional Brownian Motion (FBM) 增加细节

---

**优化完成日期**：2026-04-01 00:45 GMT+8
**编译状态**：✅ BUILD SUCCEEDED
**视觉效果**：🌪️ 自然、飘逸、混乱、物理感
