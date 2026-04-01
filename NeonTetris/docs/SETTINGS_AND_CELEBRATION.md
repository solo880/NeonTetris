# NeonTetris 游戏设置与庆祝效果完整优化

## 优化概述

完成两大核心功能：
1. **游戏设置增强**：添加网格线和幽灵方块的开关控制
2. **游戏结束流程优化**：姓名输入、排行榜记录、庆祝粒子效果

---

## 一、游戏设置增强

### 1.1 GameSettings.swift 新增参数

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

### 1.2 GameSettingsPanel.swift 界面优化

#### 新增视图设置区块

```swift
// 网格线开关
VStack(alignment: .leading, spacing: 10) {
    Text("视图显示")
        .font(.subheadline)
        .fontWeight(.semibold)
    
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
}
```

### 1.3 GameBoardView.swift 条件渲染

#### 网格线条件渲染

```swift
// 绘制网格线（根据设置开关）
if settings.showGrid {
    for row in 0...GameConst.rows {
        let y = CGFloat(row) * blockSize
        var path = Path()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: GameConst.boardW, y: y))
        context.stroke(path, with: .color(theme.config.gridLineColor.opacity(0.3)), lineWidth: 0.5)
    }
    for col in 0...GameConst.cols {
        let x = CGFloat(col) * blockSize
        var path = Path()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: GameConst.boardH))
        context.stroke(path, with: .color(theme.config.gridLineColor.opacity(0.3)), lineWidth: 0.5)
    }
}
```

#### 幽灵方块条件渲染

```swift
// 绘制幽灵方块（预览，根据设置开关）
if settings.showGhostPiece, let ghost = engine.ghostPiece {
    for block in ghost.blocks {
        if block.y >= 0 {
            drawGhostBlock(at: (block.x, block.y), in: context, blockSize: blockSize, theme: theme)
        }
    }
}
```

---

## 二、游戏结束流程优化

### 2.1 姓名输入对话框

#### OverlayView.swift 新增状态

```swift
@State private var showNameInput = false
@State private var playerName = ""
@State private var playerRank: Int? = nil
@State private var celebrationTriggered = false
```

#### 自动检测上榜

```swift
.onChange(of: engine.gameState) { newState in
    if newState == .gameOver {
        // 游戏结束，检查是否能进榜
        if leaderboard.canEnter(score: engine.score) {
            showNameInput = true
        }
    } else {
        // 重置状态
        showNameInput = false
        playerName = ""
        playerRank = nil
        celebrationTriggered = false
    }
}
```

#### 姓名输入界面

```swift
private var nameInputDialog: some View {
    VStack(spacing: 20) {
        Text("🎉 恭喜上榜！")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(theme.config.accentColor)
        
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text("你的成绩")
                    .font(.headline)
                
                HStack {
                    Text("分数：\(engine.score)")
                    Spacer()
                    Text("等级：\(engine.level)")
                    Spacer()
                    Text("行数：\(engine.lines)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("请输入你的名字")
                    .font(.subheadline)
                
                TextField("玩家姓名", text: $playerName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .onSubmit {
                        submitScore()
                    }
            }
        }
        .padding()
        
        HStack(spacing: 15) {
            Button("取消") {
                showNameInput = false
            }
            .keyboardShortcut(.cancelAction)
            
            Button("确认") {
                submitScore()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(playerName.isEmpty)
        }
    }
    .padding(30)
    .background(theme.config.panelColor)
    .cornerRadius(16)
    .shadow(radius: 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.5))
}
```

### 2.2 提交分数与排名检测

```swift
private func submitScore() {
    guard !playerName.isEmpty else { return }
    
    // 提交分数
    let rank = leaderboard.submit(
        name: playerName,
        score: engine.score,
        level: engine.level,
        lines: engine.lines
    )
    
    playerRank = rank
    showNameInput = false
    
    // 触发庆祝效果
    if let rank = rank {
        triggerCelebration(rank: rank)
    }
}
```

### 2.3 LeaderboardManager 增强

#### 新增方法

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

---

## 三、庆祝粒子效果

### 3.1 效果分级

| 排名 | 效果 | 粒子数量 | 持续时间 |
|------|------|---------|---------|
| 前三名 | 鞭炮 + 大烟花 | 100+1000 | 2.5s |
| 4-10名 | 鞭炮 | 50 | 1.2s |

### 3.2 鞭炮效果（全屏喷射）

#### 前三名鞭炮

```swift
// 从屏幕四周向中心喷射
for _ in 0..<100 {
    let side = Int.random(in: 0..<4)
    var x: Float, y: Float
    
    switch side {
    case 0: // 上边
        x = Float.random(in: 0...screenW)
        y = 0
    case 1: // 下边
        x = Float.random(in: 0...screenW)
        y = screenH
    case 2: // 左边
        x = 0
        y = Float.random(in: 0...screenH)
    default: // 右边
        x = screenW
        y = Float.random(in: 0...screenH)
    }
    
    // 向中心喷射
    let targetX = Float.random(in: screenW * 0.3...screenW * 0.7)
    let targetY = Float.random(in: screenH * 0.3...screenH * 0.7)
    let dx = (targetX - x) / 60
    let dy = (targetY - y) / 60
    
    let color = Color(red: 1.0, green: 0.8, blue: 0.2)
    particles.add([
        Particle(
            position: CGPoint(x: CGFloat(x), y: CGFloat(y)),
            velocity: CGVector(dx: CGFloat(dx), dy: CGFloat(dy)),
            acceleration: CGVector(dx: 0, dy: 0),
            color: color,
            shellColor: .randomVariant(of: color),
            outerColor: .randomVariant(of: color),
            size: CGFloat.random(in: 2...4),
            life: 1.5,
            maxLife: 1.5,
            type: .firework,
            mass: 0.5,
            friction: 0.98,
            noiseOffset: Float.random(in: 0...100),
            turbulence: 0.3,
            delay: 0
        )
    ])
}
```

### 3.3 大烟花效果（爆炸扩散）

#### 前三名专属

```swift
// 中心爆炸，多种颜色
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    for _ in 0..<20 {
        let centerX = Float.random(in: screenW * 0.2...screenW * 0.8)
        let centerY = Float.random(in: screenH * 0.2...screenH * 0.8)
        
        // 每次爆炸 50 个粒子
        var fireworks: [Particle] = []
        let colors: [Color] = [
            Color(red: 1.0, green: 0.2, blue: 0.2),  // 红
            Color(red: 0.2, green: 1.0, blue: 0.2),  // 绿
            Color(red: 0.2, green: 0.2, blue: 1.0),  // 蓝
            Color(red: 1.0, green: 1.0, blue: 0.2),  // 黄
            Color(red: 1.0, green: 0.2, blue: 1.0),  // 紫
            Color(red: 0.2, green: 1.0, blue: 1.0),  // 青
        ]
        
        for _ in 0..<50 {
            let angle = Float.random(in: 0...Float.pi * 2)
            let speed = Float.random(in: 2...5)
            let color = colors.randomElement()!
            
            fireworks.append(Particle(
                position: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)),
                velocity: CGVector(dx: CGFloat(cos(angle) * speed), dy: CGFloat(sin(angle) * speed)),
                acceleration: CGVector(dx: 0, dy: 0),
                color: color,
                shellColor: .randomVariant(of: color),
                outerColor: .randomVariant(of: color),
                size: CGFloat.random(in: 3...5),
                life: 2.0,
                maxLife: 2.0,
                type: .firework,
                mass: 0.8,
                friction: 0.95,
                noiseOffset: Float.random(in: 0...100),
                turbulence: 0.2,
                delay: 0
            ))
        }
        particles.add(fireworks)
    }
}
```

### 3.4 其他排名鞭炮（简化版）

```swift
// 其他排名：只有鞭炮（更少粒子）
for _ in 0..<50 {
    let x = Float.random(in: 0...screenW)
    let y = Float.random(in: screenH...(screenH + 100))
    let dx = Float.random(in: -2...2)
    let dy = Float.random(in: -5...(-3))
    
    let color = Color(red: 1.0, green: 0.8, blue: 0.2)
    particles.add([
        Particle(
            position: CGPoint(x: CGFloat(x), y: CGFloat(y)),
            velocity: CGVector(dx: CGFloat(dx), dy: CGFloat(dy)),
            acceleration: CGVector(dx: 0, dy: 0),
            color: color,
            shellColor: .randomVariant(of: color),
            outerColor: .randomVariant(of: color),
            size: CGFloat.random(in: 1...3),
            life: 1.2,
            maxLife: 1.2,
            type: .firework,
            mass: 0.3,
            friction: 0.98,
            noiseOffset: Float.random(in: 0...100),
            turbulence: 0.2,
            delay: 0
        )
    ])
}
```

---

## 四、粒子数量控制

### 4.1 总粒子上限

```swift
// ParticleSystem.swift
private let maxParticles = ParticleConst.maxParticles  // 500
```

### 4.2 自动丢弃策略

```swift
func add(_ newParticles: [Particle]) {
    let available = maxParticles - particles.count
    if available <= 0 { return }
    particles.append(contentsOf: newParticles.prefix(available))
}
```

### 4.3 粒子数量统计

| 效果类型 | 单次粒子数 | 触发次数 | 总粒子数 |
|---------|-----------|---------|---------|
| 前三名鞭炮 | 100 | 1 | 100 |
| 前三名烟花 | 50×20 | 1 | 1000 |
| 其他鞭炮 | 50 | 1 | 50 |

**注意**：由于粒子上限 500，实际效果会自动截断，保证性能稳定。

---

## 五、用户体验流程

### 5.1 完整流程

```
游戏结束
    ↓
检测是否能进榜
    ↓
[能进榜]
    ↓
弹出姓名输入对话框
    ↓
用户输入姓名
    ↓
提交分数到排行榜
    ↓
获取排名
    ↓
[前三名]
    ↓
鞭炮 + 大烟花庆祝
    ↓
用户点击"重新开始"
    ↓
重置游戏状态

[其他排名]
    ↓
鞭炮庆祝（简化版）
    ↓
用户点击"重新开始"
    ↓
重置游戏状态
```

### 5.2 键盘快捷键

| 快捷键 | 功能 |
|-------|------|
| Enter | 确认提交 |
| Escape | 取消输入 |

---

## 编译结果

```bash
** BUILD SUCCEEDED **
```

---

## 后续优化方向

1. **音效增强**：添加庆祝音效
2. **截图分享**：保存成绩截图到相册
3. **社交分享**：分享到社交媒体
4. **成就系统**：添加成就徽章
5. **主题解锁**：前三名解锁特殊主题

---

**优化完成日期**：2026-04-01 14:30 GMT+8
**编译状态**：✅ **BUILD SUCCEEDED**
**优化效果**：🎮 游戏设置增强 + 🎉 庆祝效果优化
