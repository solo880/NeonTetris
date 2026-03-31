# NeonTetris 粒子效果平衡优化

## 优化目标

平衡游戏中不同动作的粒子效果，突出行消除的视觉反馈

**优化方向**：
- **行消除**：增加离子数量 1 倍（×2），增加寿命 30%（视觉高潮）
- **其他动作**：减少离子数量 50%，减少寿命 20%（视觉低调）

---

## 核心改进

### 1. 行消除粒子效果增强 ✅

#### 离子数量增加 1 倍

```swift
// 原来的优化版本（20% 的原始数量）
let burnCountReduced = max(1, ParticleConst.burnCount / 5)      // 40 / 5 = 8
let splashCountReduced = max(1, ParticleConst.splashCount / 5)  // 20 / 5 = 4

// 新的增强版本（40% 的原始数量，即 20% 的 2 倍）
let burnCountIncreased = ParticleConst.burnCount / 5 * 2        // 40 / 5 * 2 = 16
let splashCountIncreased = ParticleConst.splashCount / 5 * 2    // 20 / 5 * 2 = 8
```

#### 寿命增加 30%

```swift
// 原来的缩短版本
particle.maxLife = particle.maxLife * 0.5  // 缩短 50%

// 新的增加版本
particle.maxLife = particle.maxLife * 1.3  // 增加 30%
```

#### 行消除粒子统计

| 指标 | 原始值 | 优化前 | 优化后 | 变化 |
|------|--------|--------|--------|------|
| 燃烧火花数/格 | 40 | 8 | 16 | +100% |
| 飞溅粒子数/格 | 20 | 4 | 8 | +100% |
| 单行总粒子数 | 600 | 120 | 240 | +100% |
| 四行总粒子数 | 2400 | 480 | 960 | +100% |
| 粒子寿命 | 1.8-2.0s | 0.9-1.0s | 2.34-2.6s | +130% |

**效果**：行消除时粒子效果华丽，视觉高潮明显

### 2. 其他动作粒子效果减弱 ✅

#### 离子数量减少 50%

所有其他动作的粒子数量都减少 50%：

```swift
// 移动（ionTrail）
for _ in 0..<(ParticleConst.ionTrailRate / 2) {  // 原来 ionTrailRate，现在 / 2
    newParticles.append(particle)
}

// 移动（airFlow）
for _ in 0..<(ParticleConst.airFlowCount / 2) {  // 原来 airFlowCount，现在 / 2
    newParticles.append(particle)
}

// 旋转（spinOut）
for i in 0..<(ParticleConst.spinOutCount / 2) {  // 原来 spinOutCount，现在 / 2
    newParticles.append(particle)
}

// 锁定（lockFlash）
for _ in 0..<3 {  // 原来 6，现在 3
    newParticles.append(particle)
}

// 硬降（hardDropTrail）
if row % 2 == 0 {  // 原来每行 1 个，现在每 2 行 1 个
    newParticles.append(particle)
}
```

#### 寿命减少 20%

```swift
// 所有其他动作的粒子
particle.maxLife = particle.maxLife * 0.8  // 减少 20%
particle.life = particle.maxLife
```

#### 其他动作粒子统计

| 动作 | 粒子类型 | 原始数量 | 优化后数量 | 减少比例 | 原始寿命 | 优化后寿命 | 减少比例 |
|------|---------|---------|-----------|---------|---------|-----------|---------|
| 移动 | ionTrail | 2/帧 | 1/帧 | -50% | 1.5s | 1.2s | -20% |
| 移动 | airFlow | 6/帧 | 3/帧 | -50% | 1.0s | 0.8s | -20% |
| 旋转 | spinOut | 12/帧 | 6/帧 | -50% | 1.2s | 0.96s | -20% |
| 锁定 | lockFlash | 6/块 | 3/块 | -50% | 0.6s | 0.48s | -20% |
| 硬降 | hardDropTrail | 1/行 | 0.5/行 | -50% | 1.2s | 0.96s | -20% |

**效果**：其他动作的粒子效果低调，不会分散注意力

### 3. 视觉层级对比 ✅

#### 粒子密度对比

```
行消除：████████████████  (240 粒子/行)
移动：  ██                (1-3 粒子/帧)
旋转：  ██                (6 粒子/帧)
锁定：  ██                (3 粒子/块)
硬降：  ██                (0.5 粒子/行)
```

#### 粒子寿命对比

```
行消除：████████████████████████████  (2.34-2.6s)
移动：  ████████████                  (1.2s)
旋转：  ██████████                    (0.96s)
锁定：  ████████                      (0.48s)
硬降：  ██████████                    (0.96s)
```

---

## 代码实现

### 行消除粒子生成

```swift
/// 行消除：燃烧+飞溅（增加数量 1 倍，增加寿命 30%）
func emitLineClear(rows: [Int], blockSize: CGFloat, boardValues: [[Int]], pieceColors: (PieceType) -> Color) {
    var newParticles: [Particle] = []
    for row in rows {
        for col in 0..<GameConst.cols {
            let cx = Float(CGFloat(col) * blockSize + blockSize / 2)
            let cy = Float(CGFloat(row) * blockSize + blockSize / 2)
            
            // 燃烧火花：增加数量 1 倍（8 → 16），增加寿命 30%
            let burnCountIncreased = ParticleConst.burnCount / 5 * 2
            for _ in 0..<burnCountIncreased {
                var particle = ParticleFactory.burnSpark(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4)
                particle.maxLife = particle.maxLife * 1.3
                particle.life = particle.maxLife
                particle.position.x += CGFloat.random(in: -30...30)
                particle.position.y += CGFloat.random(in: -30...30)
                newParticles.append(particle)
            }
            
            // 离子飞溅：增加数量 1 倍（4 → 8），增加寿命 30%
            let splashCountIncreased = ParticleConst.splashCount / 5 * 2
            for _ in 0..<splashCountIncreased {
                var particle = ParticleFactory.ionSplash(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4)
                particle.maxLife = particle.maxLife * 1.3
                particle.life = particle.maxLife
                particle.position.x += CGFloat.random(in: -30...30)
                particle.position.y += CGFloat.random(in: -30...30)
                newParticles.append(particle)
            }
        }
    }
    add(newParticles)
}
```

### 其他动作粒子生成

```swift
/// 移动空气流动 - 减少 50%，寿命减少 20%
func emitAirFlow(piece: TetrominoPiece, blockSize: CGFloat, direction: Float) {
    var newParticles: [Particle] = []
    for block in piece.blocks {
        guard block.y >= 0 else { continue }
        let cx = Float(CGFloat(block.x) * blockSize + blockSize / 2)
        let cy = Float(CGFloat(block.y) * blockSize + blockSize / 2)
        for _ in 0..<(ParticleConst.airFlowCount / 2) {
            var particle = ParticleFactory.airFlow(x: cx, y: cy, direction: direction)
            particle.maxLife = particle.maxLife * 0.8
            particle.life = particle.maxLife
            newParticles.append(particle)
        }
    }
    add(newParticles)
}
```

---

## 优化效果对比

### 优化前
- 行消除：120 粒子/行，0.9-1.0s 寿命
- 其他动作：正常数量，正常寿命
- 视觉层级不明显

### 优化后
- ✅ 行消除：240 粒子/行，2.34-2.6s 寿命（视觉高潮）
- ✅ 其他动作：50% 数量，80% 寿命（视觉低调）
- ✅ 视觉层级明显，行消除更突出

---

## 参数总结

### 行消除粒子参数

| 参数 | 优化前 | 优化后 | 变化 |
|------|--------|--------|------|
| 燃烧火花数/格 | 8 | 16 | +100% |
| 飞溅粒子数/格 | 4 | 8 | +100% |
| 单行总粒子数 | 120 | 240 | +100% |
| 粒子寿命 | 0.9-1.0s | 2.34-2.6s | +130% |

### 其他动作粒子参数

| 动作 | 粒子类型 | 数量变化 | 寿命变化 |
|------|---------|---------|---------|
| 移动 | ionTrail | -50% | -20% |
| 移动 | airFlow | -50% | -20% |
| 旋转 | spinOut | -50% | -20% |
| 锁定 | lockFlash | -50% | -20% |
| 硬降 | hardDropTrail | -50% | -20% |

---

## 代码改动

### 文件修改

1. **ParticleSystem.swift**
   - 修改 `emitLineClear()` 方法（增加数量和寿命）
   - 修改 `emitIonTrail()` 方法（减少数量和寿命）
   - 修改 `emitAirFlow()` 方法（减少数量和寿命）
   - 修改 `emitSpinOut()` 方法（减少数量和寿命）
   - 修改 `emitLockFlash()` 方法（减少数量和寿命）
   - 修改 `emitHardDropTrail()` 方法（减少数量和寿命）

### 编译结果
✅ **BUILD SUCCEEDED**

---

## 性能影响

- **行消除粒子**：增加 100%（120 → 240）
- **其他动作粒子**：减少 50%
- **总体粒子数**：基本平衡（行消除增加，其他减少）
- **帧率**：应能保持 60fps（现代 Mac）

---

## 后续优化方向

1. **可配置参数**：让用户自定义粒子效果强度
2. **难度相关**：高难度时增加粒子效果
3. **连击反馈**：连续消除时增加粒子效果
4. **特殊效果**：Tetris（四行消除）时增加特殊粒子效果

---

**优化完成日期**：2026-04-01 01:52 GMT+8
**编译状态**：✅ **BUILD SUCCEEDED**
**优化效果**：🎮 视觉层级明显、行消除突出、游戏流畅
