# NeonTetris 游戏设置与游戏结束优化

## 优化概述

完成两项重要功能：
1. **游戏设置增加网格和幽灵方块的开关**
2. **游戏结束增加弹出输入玩家姓名功能，并记录成绩，上榜庆祝粒子效果**

---

## 功能一：网格和幽灵方块开关

### 1. GameSettings 新增参数

#### 文件：`GameSettings.swift`

```swift
// MARK: 视图设置
/// 网格线开关
@Published var showGrid: Bool {
    didSet { UserDefaults.standard.set(showGrid, forKey: "showGrid") }
}
/// 幽灵方块开关
@Published var showGhostPiece: Bool {
    didSet { UserDefaults.standard.set(showGhostPiece, forKey: "showGhostPiece") }
}
```

#### 特性
- ✅ **持久化存储**：设置保存到 UserDefaults
- ✅ **默认开启**：两个功能默认都是 true
- ✅ **实时生效**：使用 @Published，修改立即生效

### 2. GameSettingsPanel 新增开关

#### 文件：`GameSettingsPanel.swift`

```swift
// 网格线开关
Toggle(isOn: $settings.showGrid) {
    VStack(alignment: .leading, spacing: 2) {
        Text("显示网格线")
            .font(.body)
        Text("显示棋盘网格线")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
.toggleStyle(.switch)

// 幽灵方块开关
Toggle(isOn: $settings.showGhostPiece) {
    VStack(alignment: .leading, spacing: 2) {
        Text("显示幽灵方块")
            .font(.body)
        Text("显示方块落地位置的半透明预览")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
.toggleStyle(.switch)
```

#### UI 改进
- ✅ **分组布局**：视图设置单独分组
- ✅ **说明文字**：每个开关都有详细说明
- ✅ **背景美化**：添加背景色和圆角
- ✅ **窗口扩大**：从 300px 高度增加到 450px

### 3. GameBoardView 条件渲染

#### 文件：`GameBoardView.swift`

```swift
// 绘制网格线（根据设置开关）
if settings.showGrid {
    for row in 0...GameConst.rows {
        // ... 绘制网格线
    }
}

// 绘制幽灵方块（根据设置开关）
if settings.showGhostPiece, let ghost = engine.ghostPiece {
    // ... 绘制幽灵方块
}
```

#### 条件渲染逻辑
- **网格线**：只有 `settings.showGrid == true` 时才绘制
- **幽灵方块**：只有 `settings.showGhostPiece == true` 时才绘制

---

## 功能二：游戏结束姓名输入与庆祝粒子

### 1. OverlayView 增加姓名输入

#### 文件：`OverlayView.swift`

```swift
@State private var playerName: String = ""
@State private var showNameInput: Bool = false
@State private var rank: Int? = nil
@State private var celebrationTriggered: Bool = false

// 游戏结束时检查是否上榜
private func handleGameOver() {
    if let playerRank = leaderboard.getRank(score: engine.score) {
        rank = playerRank
        showNameInput = true
        celebrationTriggered = false
    }
}
```

#### 姓名输入界面
```swift
if showNameInput {
    VStack(spacing: 15) {
        if let rank = rank {
            Text("🎉 恭喜！第 \(rank) 名！")
                .font(.headline)
                .foregroundColor(.yellow)
        }
        
        TextField("输入你的名字", text: $playerName)
            .textFieldStyle(.roundedBorder)
            .frame(width: 200)
        
        Button(action: submitScore) {
            Text("提交成绩")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.config.accentColor)
                .foregroundColor(.black)
                .cornerRadius(8)
        }
        .frame(width: 200)
        .disabled(playerName.isEmpty)
    }
}
```

### 2. LeaderboardManager 新增方法

#### 文件：`LeaderboardManager.swift`

```swift
// MARK: - 获取分数的排名（1-based，nil 表示未进榜）
func getRank(score: Int) -> Int? {
    var rank = 1
    for entry in entries {
        if score >= entry.score {
            return rank
        }
        rank += 1
    }
    // 如果榜单未满，也在榜内
    if entries.count < GameConst.leaderboardMax {
        return rank
    }
    return nil
}

// MARK: - 获取排行榜长度
var count: Int {
    entries.count
}
```

### 3. 粒子系统庆祝效果

#### ParticleTypes.swift 新增 delay 字段

```swift
struct Particle {
    // ... 其他字段
    var delay: Float           // 延迟显示时间（秒）
    
    // 是否存活
    var isAlive: Bool {
        life > 0 && delay <= 0
    }
    
    mutating func update(deltaTime: Float, perlin: PerlinNoise, windForce: CGVector) {
        // 处理延迟
        if delay > 0 {
            delay -= deltaTime
            return
        }
        // ... 正常更新逻辑
    }
}
```

#### ParticleSystem.swift 新增庆祝方法

```swift
// MARK: - 庆祝烟花（中心爆发）
func emitFireworkCelebration(centerX: Float, centerY: Float, isTop3: Bool) {
    if isTop3 {
        // 前三名：多轮爆发
        for round in 0..<3 {
            let delay = Float(round) * 0.3
            // ... 40 个烟花粒子，带延迟
        }
    } else {
        // 普通上榜：单轮爆发
        // ... 30 个烟花粒子
    }
}

// MARK: - 鞭炮庆祝（全屏散布）
func emitFirecrackers(width: Float, height: Float) {
    // 限制鞭炮数量，避免粒子过多
    let maxPositions = 6
    // ... 每个位置 10 个鞭炮粒子
}
```

### 4. 庆祝粒子效果触发

#### OverlayView.swift

```swift
private func submitScore() {
    guard !playerName.isEmpty, let rank = rank else { return }
    
    // 提交分数
    leaderboard.submit(
        name: playerName,
        score: engine.score,
        level: engine.level,
        lines: engine.lines
    )
    
    // 触发庆祝粒子
    triggerCelebration(rank: rank)
    
    // 隐藏输入框
    showNameInput = false
}

private func triggerCelebration(rank: Int) {
    guard !celebrationTriggered else { return }
    celebrationTriggered = true
    
    let boardW = GameConst.boardW
    let boardH = GameConst.boardH
    
    if rank <= 3 {
        // 前三名：大烟花 + 鞭炮
        particles.emitFireworkCelebration(
            centerX: Float(boardW / 2),
            centerY: Float(boardH / 2),
            isTop3: true
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            particles.emitFirecrackers(
                width: Float(boardW),
                height: Float(boardH)
            )
        }
    } else {
        // 上榜：鞭炮庆祝
        particles.emitFirecrackers(
            width: Float(boardW),
            height: Float(boardH)
        )
    }
}
```

---

## 粒子数量控制

### 控制策略

#### 前三名庆祝
- **大烟花**：3 轮 × 40 粒子 = 120 粒子（带延迟）
- **鞭炮**：6 位置 × 10 粒子 = 60 粒子
- **总计**：约 180 粒子（分时爆发）

#### 普通上榜庆祝
- **鞭炮**：6 位置 × 10 粒子 = 60 粒子
- **总计**：约 60 粒子

### 延迟机制
- ✅ **delay 字段**：粒子可以延迟显示
- ✅ **分时爆发**：前三名分 3 轮爆发，避免瞬间卡顿
- ✅ **数量限制**：鞭炮位置限制为 6 个，每个位置 10 个粒子

---

## 编译结果

```bash
** BUILD SUCCEEDED **
```

---

## 用户体验流程

### 网格和幽灵方块开关

1. 用户点击"游戏设置"按钮
2. 看到两个新的 Toggle 开关
3. 点击开关即可实时切换显示效果
4. 设置自动保存，下次启动仍生效

### 游戏结束姓名输入

1. 游戏结束，显示最终分数
2. 如果上榜，显示姓名输入框和排名
3. 用户输入姓名后点击"提交成绩"
4. 触发庆祝粒子效果：
   - **前三名**：大烟花 + 鞭炮
   - **上榜**：鞭炮庆祝
5. 粒子效果美观且不卡顿

---

## 后续优化方向

1. **粒子音效**：庆祝时播放烟花音效
2. **排行榜显示优化**：前三名特殊标记
3. **社交分享**：分享成绩到社交媒体
4. **成就系统**：首次上榜、前三名等成就

---

**优化完成日期**：2026-04-01 14:17 GMT+8
**编译状态**：✅ **BUILD SUCCEEDED**
**优化效果**：🎮 网格/幽灵方块开关 + 🎉 游戏结束姓名输入与庆祝粒子
