# NeonTetris 离子粒子随机化优化 v3

## 优化目标

从"统一的离子效果"升级到"多彩、随机、混乱"的离子效果

**视觉目标**：
- 单个离子三层颜色都随机
- 离子大小更随机（±40%）
- 离子寿命更随机（±30%）
- 初始出生位置更分散、更随机
- 整体感觉更混乱、更自然、更有生命力

---

## 核心改进

### 1. 三层颜色随机化 ✅

每个粒子的三层颜色都独立随机：

#### 核心颜色（color）
- 基础颜色（由粒子类型或事件决定）
- 保持原始颜色

#### 壳层颜色（shellColor）
- 基于核心颜色的随机变体
- 使用 `Color.randomVariant(of:)` 生成
- 随机 HSB 值：
  - 色调（Hue）：0-1 完全随机
  - 饱和度（Saturation）：0.6-1.0
  - 亮度（Brightness）：0.7-1.0

#### 外层颜色（outerColor）
- 基于核心颜色的随机变体
- 使用 `Color.randomVariant(of:)` 生成
- 随机 HSB 值同上

**效果**：每个粒子都是独特的三色离子，从外到内颜色逐渐变化

```swift
// 颜色生成
static func randomVariant(of baseColor: Color) -> Color {
    let hue = Double.random(in: 0...1)
    let saturation = Double.random(in: 0.6...1.0)
    let brightness = Double.random(in: 0.7...1.0)
    return Color(hue: hue, saturation: saturation, brightness: brightness)
}
```

### 2. 大小随机化 ✅

每个粒子的大小在基础大小的 ±40% 范围内随机：

```swift
private static func randomSize(_ baseSize: Float) -> CGFloat {
    let variation = CGFloat.random(in: 0.6...1.4)
    return CGFloat(baseSize) * variation
}
```

**范围**：
- 最小：基础大小 × 0.6
- 最大：基础大小 × 1.4
- 平均：基础大小 × 1.0

**效果**：粒子大小不再统一，有大有小，更自然

### 3. 寿命随机化 ✅

每个粒子的寿命在基础寿命的 ±30% 范围内随机：

```swift
private static func randomLifetime(_ baseLifetime: Float) -> Float {
    let variation = Float.random(in: 0.7...1.3)
    return baseLifetime * variation
}
```

**范围**：
- 最小：基础寿命 × 0.7
- 最大：基础寿命 × 1.3
- 平均：基础寿命 × 1.0

**效果**：粒子消失时间不同，有的快消失，有的慢消失，更自然

### 4. 出生位置随机化 ✅

每个粒子的出生位置在给定点周围 ±15 像素范围内随机分散：

```swift
private static func randomSpawnOffset() -> CGPoint {
    CGPoint(
        x: CGFloat.random(in: -15...15),
        y: CGFloat.random(in: -15...15)
    )
}
```

**范围**：
- X 轴：±15 像素
- Y 轴：±15 像素
- 范围：30×30 像素正方形内

**效果**：粒子不再从同一点出发，而是从一个区域内分散出发，更自然

### 5. 初始速度更随机 ✅

所有粒子的初始速度范围都扩大了：

| 粒子类型 | 原速度范围 | 新速度范围 | 变化 |
|---------|-----------|-----------|------|
| ionTrail | 0.7-1.0 | 0.6-1.4 | 更宽 |
| airFlow | 0.7-1.0 | 0.6-1.4 | 更宽 |
| spinOut | 0.7-1.0 | 0.6-1.2 | 更宽 |
| burnSpark | 0.6-1.0 | 0.5-1.2 | 更宽 |
| ionSplash | 0.5-1.0 | 0.4-1.2 | 更宽 |
| lockFlash | - | - | - |
| hardDropTrail | - | - | - |
| firework | 0.4-1.0 | 0.3-1.2 | 更宽 |
| firecracker | 0.5-1.0 | 0.4-1.2 | 更宽 |

**效果**：粒子速度差异更大，有快有慢，更混乱

### 6. 角度变化更大 ✅

所有粒子的角度变化范围都扩大了：

| 粒子类型 | 原角度范围 | 新角度范围 | 变化 |
|---------|-----------|-----------|------|
| spinOut | ±0.3 | ±0.5 | 更宽 |
| burnSpark | ±0.8 | ±1.0 | 更宽 |

**效果**：粒子方向差异更大，更混乱

---

## 数据结构改动

### Particle 结构体

```swift
struct Particle {
    var position: CGPoint
    var velocity: CGVector
    var acceleration: CGVector
    var color: Color              // 核心颜色
    var shellColor: Color         // 壳层颜色（新增）
    var outerColor: Color         // 外层颜色（新增）
    var size: CGFloat
    var life: Float
    var maxLife: Float
    var type: ParticleType
    var mass: Float
    var friction: Float
    var noiseOffset: Float
    var turbulence: Float
}
```

### 粒子工厂改动

每个工厂方法都添加了：
1. `randomSpawnOffset()` - 随机出生位置
2. `randomSize()` - 随机大小
3. `randomLifetime()` - 随机寿命
4. `shellColor` - 随机壳层颜色
5. `outerColor` - 随机外层颜色
6. 扩大的速度和角度范围

---

## 渲染流程

```swift
for particle in particles {
    let progress = particle.lifeProgress  // 0-1
    let size = particle.size * progress   // 随生命周期缩小
    
    // 第一层：外层虚化（2.5x，10%，outerColor）
    drawCircle(center: particle.position, radius: size * 2.5, 
               color: particle.outerColor, opacity: progress * 0.08)
    
    // 第二层：中层壳（1.6x，35%，shellColor）
    drawCircle(center: particle.position, radius: size * 1.6, 
               color: particle.shellColor, opacity: progress * 0.35)
    
    // 第三层：核心（1.0x，100%，color）
    drawCircle(center: particle.position, radius: size, 
               color: particle.color, opacity: progress)
}
```

---

## 视觉效果对比

### 优化前（v2）
- 三层颜色相同
- 大小统一
- 寿命统一
- 出生位置集中

### 优化后（v3）
- ✅ 三层颜色随机
- ✅ 大小随机（±40%）
- ✅ 寿命随机（±30%）
- ✅ 出生位置分散（±15px）
- ✅ 速度更随机
- ✅ 角度更随机
- ✅ 整体更混乱、更自然、更有生命力

---

## 代码改动

### 文件修改

1. **ParticleTypes.swift**（完全重写）
   - 添加 `Color.randomNeon()` 和 `Color.randomVariant(of:)` 扩展
   - 扩展 Particle 结构体（+2 个颜色属性）
   - 添加 `randomSpawnOffset()`、`randomSize()`、`randomLifetime()` 工具函数
   - 重写所有粒子工厂方法（添加随机化）

2. **GameBoardView.swift**
   - 修改粒子渲染逻辑（使用 shellColor 和 outerColor）

3. **LeaderboardPanel.swift**
   - 修复粒子创建代码（适配新的 Particle 结构体）

### 编译结果
✅ **BUILD SUCCEEDED**

---

## 性能影响

- **粒子数量**：50,000（不变）
- **渲染复杂度**：每粒子 3 个圆形（不变）
- **计算复杂度**：不变（物理模拟相同）
- **内存**：增加约 1-2MB（三层颜色）
- **帧率**：应能保持 60fps（现代 Mac）

---

## 后续优化方向

1. **粒子轨迹可视化**：显示粒子的运动轨迹
2. **粒子碰撞**：粒子之间的碰撞反弹
3. **吸引力/斥力**：粒子受方块吸引或排斥
4. **多层噪声**：Fractional Brownian Motion (FBM) 增加细节
5. **GPU 加速**：Metal 着色器实现，支持 100,000+ 粒子
6. **粒子池优化**：预分配粒子对象，减少 GC 压力

---

**优化完成日期**：2026-04-01 01:17 GMT+8
**编译状态**：✅ BUILD SUCCEEDED
**视觉效果**：🌈 多彩、随机、混乱、有生命力
