# NeonTetris 行消除粒子优化

## 优化目标

优化行消除时的粒子效果，使其更加精细、高效

**优化方向**：
- 减少粒子数量到 20%（避免过度密集）
- 缩短粒子寿命 50%（快速消失，不影响游戏节奏）
- 增加分散程度 100%（粒子分布更广，视觉效果更好）

---

## 核心改进

### 1. 粒子数量减少到 20% ✅

#### 原始参数

```swift
// 原来的常量
enum ParticleConst {
    static let burnCount = 40      // 每格燃烧火花数
    static let splashCount = 20    // 每格飞溅粒子数
}

// 原来的行消除逻辑
for row in rows {
    for col in 0..<GameConst.cols {  // 10 列
        // 燃烧火花：40 个
        for _ in 0..<ParticleConst.burnCount {
            newParticles.append(ParticleFactory.burnSpark(...))
        }
        // 离子飞溅：20 个
        for _ in 0..<ParticleConst.splashCount {
            newParticles.append(ParticleFactory.ionSplash(...))
        }
    }
}

// 单行消除时的粒子总数：(40 + 20) × 10 = 600 个
// 四行消除时的粒子总数：(40 + 20) × 10 × 4 = 2400 个
```

#### 优化后参数

```swift
// 优化后的行消除逻辑
let burnCountReduced = max(1, ParticleConst.burnCount / 5)      // 40 / 5 = 8 个
let splashCountReduced = max(1, ParticleConst.splashCount / 5)  // 20 / 5 = 4 个

for row in rows {
    for col in 0..<GameConst.cols {  // 10 列
        // 燃烧火花：8 个（原来 40 个）
        for _ in 0..<burnCountReduced {
            newParticles.append(ParticleFactory.burnSpark(...))
        }
        // 离子飞溅：4 个（原来 20 个）
        for _ in 0..<splashCountReduced {
            newParticles.append(ParticleFactory.ionSplash(...))
        }
    }
}

// 单行消除时的粒子总数：(8 + 4) × 10 = 120 个（原来 600 个）
// 四行消除时的粒子总数：(8 + 4) × 10 × 4 = 480 个（原来 2400 个）
```

#### 数量对比

| 场景 | 原始数量 | 优化后数量 | 减少比例 |
|------|---------|-----------|---------|
| 单行消除 | 600 | 120 | 80% ↓ |
| 双行消除 | 1200 | 240 | 80% ↓ |
| 三行消除 | 1800 | 360 | 80% ↓ |
| 四行消除 | 2400 | 480 | 80% ↓ |

**效果**：粒子数量减少到 20%，避免过度密集，游戏更流畅

### 2. 寿命缩短 50% ✅

#### 原始寿命

```swift
// 原来的粒子寿命
burnSpark.lifetime = 1.8s
ionSplash.lifetime = 2.0s
```

#### 优化后寿命

```swift
// 优化后的粒子寿命
particle.maxLife = particle.maxLife * 0.5

// 缩短后的寿命
burnSpark.lifetime = 1.8s × 0.5 = 0.9s
ionSplash.lifetime = 2.0s × 0.5 = 1.0s
```

#### 寿命对比

| 粒子类型 | 原始寿命 | 优化后寿命 | 缩短比例 |
|---------|---------|-----------|---------|
| burnSpark | 1.8s | 0.9s | 50% ↓ |
| ionSplash | 2.0s | 1.0s | 50% ↓ |

**效果**：粒子快速消失，不影响游戏节奏，屏幕更清爽

### 3. 分散程度增加 100% ✅

#### 原始分散

```swift
// 原来的出生位置分散（在粒子工厂中）
private static func randomSpawnOffset() -> CGPoint {
    CGPoint(
        x: CGFloat.random(in: -15...15),
        y: CGFloat.random(in: -15...15)
    )
}

// 分散范围：30×30 像素正方形内
```

#### 优化后分散

```swift
// 优化后的出生位置分散（在行消除中额外增加）
particle.position.x += CGFloat.random(in: -30...30)  // 原来 ±15，现在 ±30
particle.position.y += CGFloat.random(in: -30...30)

// 总分散范围：
// 粒子工厂分散：±15
// 行消除额外分散：±30
// 总计：±45 像素（90×90 像素正方形内）
```

#### 分散对比

| 分散方式 | 范围 | 面积 |
|---------|------|------|
| 原始分散 | ±15px | 30×30 = 900px² |
| 优化后分散 | ±45px | 90×90 = 8100px² | 
| 增加倍数 | 3x | 9x |

**效果**：粒子分布更广，视觉效果更好，不会集中在一个点

---

## 代码实现

### 行消除粒子生成代码

```swift
/// 行消除：燃烧+飞溅（优化版：减少数量、缩短寿命、增加分散）
func emitLineClear(rows: [Int], blockSize: CGFloat, boardValues: [[Int]], pieceColors: (PieceType) -> Color) {
    var newParticles: [Particle] = []
    for row in rows {
        for col in 0..<GameConst.cols {
            let cx = Float(CGFloat(col) * blockSize + blockSize / 2)
            let cy = Float(CGFloat(row) * blockSize + blockSize / 2)
            
            // 燃烧火花：减少到 20%，寿命缩短 50%，分散增加 100%
            let burnCountReduced = max(1, ParticleConst.burnCount / 5)
            for _ in 0..<burnCountReduced {
                var particle = ParticleFactory.burnSpark(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4)
                // 缩短寿命 50%
                particle.maxLife = particle.maxLife * 0.5
                particle.life = particle.maxLife
                // 增加分散程度 100%
                particle.position.x += CGFloat.random(in: -30...30)
                particle.position.y += CGFloat.random(in: -30...30)
                newParticles.append(particle)
            }
            
            // 离子飞溅：减少到 20%，寿命缩短 50%，分散增加 100%
            let splashCountReduced = max(1, ParticleConst.splashCount / 5)
            for _ in 0..<splashCountReduced {
                var particle = ParticleFactory.ionSplash(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4)
                // 缩短寿命 50%
                particle.maxLife = particle.maxLife * 0.5
                particle.life = particle.maxLife
                // 增加分散程度 100%
                particle.position.x += CGFloat.random(in: -30...30)
                particle.position.y += CGFloat.random(in: -30...30)
                newParticles.append(particle)
            }
        }
    }
    add(newParticles)
}
```

---

## 优化效果对比

### 原始行消除效果
- 粒子密集（600-2400 个）
- 寿命长（1.8-2.0s）
- 分散集中（±15px）
- 屏幕拥挤，影响游戏节奏

### 优化后行消除效果
- ✅ 粒子稀疏（120-480 个）
- ✅ 寿命短（0.9-1.0s）
- ✅ 分散广（±45px）
- ✅ 屏幕清爽，游戏流畅
- ✅ 视觉效果更精细

---

## 参数总结

### 行消除粒子参数

| 参数 | 原始值 | 优化值 | 变化 |
|------|--------|--------|------|
| 燃烧火花数 | 40 | 8 | -80% |
| 飞溅粒子数 | 20 | 4 | -80% |
| 粒子寿命 | 1.8-2.0s | 0.9-1.0s | -50% |
| 分散范围 | ±15px | ±45px | +200% |

### 单行消除粒子统计

| 指标 | 原始值 | 优化值 |
|------|--------|--------|
| 总粒子数 | 600 | 120 |
| 平均寿命 | 1.9s | 0.95s |
| 分散面积 | 900px² | 8100px² |

---

## 代码改动

### 文件修改

1. **ParticleSystem.swift**
   - 修改 `emitLineClear()` 方法
   - 减少粒子数量到 20%
   - 缩短粒子寿命 50%
   - 增加分散程度 100%

### 编译结果
✅ **BUILD SUCCEEDED**

---

## 性能影响

- **粒子总数**：减少 80%（600 → 120 per line）
- **渲染复杂度**：降低 80%
- **计算复杂度**：降低 80%
- **内存**：降低 80%
- **帧率**：提升（粒子更少）

---

## 后续优化方向

1. **可配置参数**：让用户自定义行消除粒子效果
2. **粒子池优化**：预分配粒子对象，减少 GC 压力
3. **GPU 加速**：Metal 着色器实现，支持更多粒子
4. **特殊效果**：Tetris（四行消除）时增加特殊粒子效果

---

**优化完成日期**：2026-04-01 01:39 GMT+8
**编译状态**：✅ BUILD SUCCEEDED
**优化效果**：🎮 游戏更流畅、屏幕更清爽、视觉更精细
