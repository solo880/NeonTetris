# NeonTetris2 — 代码架构文档

## 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI 视图层                        │
│  (ContentView, GameBoardView, Panels, Overlays)         │
└────────────────┬────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼──────┐  ┌──────▼────────┐
│  GameEngine  │  │ ParticleSystem │
│  (MVVM)      │  │  (ObservableObj)
└───────┬──────┘  └──────┬────────┘
        │                 │
        │    ┌────────────┴────────────┐
        │    │                         │
┌───────▼────────────┐  ┌─────────────▼──────┐
│  游戏逻辑层         │  │  粒子/特效层       │
│  - 状态机          │  │  - 粒子工厂        │
│  - 碰撞检测        │  │  - 粒子池管理      │
│  - 消行系统        │  │  - 事件响应        │
└────────┬───────────┘  └────────────────────┘
         │
    ┌────┴────┐
    │          │
┌───▼──┐  ┌───▼──────┐
│ 音效 │  │ 主题系统 │
│ 系统 │  │ 排行榜   │
└──────┘  └──────────┘
```

---

## 核心模块详解

### 1. GameEngine（游戏引擎）

**职责**：
- 游戏状态管理（idle/playing/paused/clearing/gameOver）
- 主循环驱动（重力 Timer）
- 输入处理（移动/旋转/下落/暂存）
- 碰撞检测和消行逻辑
- 事件发布（供粒子系统和音效订阅）

**关键方法**：
```swift
func startGame()              // 开始游戏
func tick()                   // 重力 tick（每帧调用）
func moveLeft/Right()         // 移动
func rotate()                 // 旋转（含 SRS 踢墙）
func hardDrop()               // 硬降
func holdPiece()              // 暂存
func checkLineClear()         // 消行检测
```

**事件流**：
```
GameEngine.eventPublisher
  ├─ moveLeft/Right
  ├─ rotate/rotateFail
  ├─ softDrop/hardDrop
  ├─ lock
  ├─ lineClear
  ├─ hold
  ├─ levelUp
  ├─ gameOver
  └─ wallHit
```

---

### 2. ParticleSystem（粒子系统）

**职责**：
- 粒子池管理（最多 8000 个）
- 粒子更新（每帧调用 update()）
- 事件响应（生成对应粒子）
- 粒子渲染数据提供

**粒子类型**：
| 类型 | 触发条件 | 数量 | 特点 |
|------|---------|------|------|
| ionTrail | 方块自带 | 2/帧 | 离子拖尾 |
| airFlow | 移动/下落 | 6 | 空气流动 |
| spinOut | 旋转 | 12 | 甩出效果 |
| burnSpark | 行消除 | 20/格 | 燃烧火花 |
| ionSplash | 行消除 | 8/格 | 离子飞溅 |
| lockFlash | 锁定 | 6/块 | 锁定闪光 |
| hardDropTrail | 硬降 | 路径上 | 硬降拖尾 |
| firework | 排行榜前3 | 30/个 | 烟花 |
| firecracker | 排行榜4-10 | 15/个 | 鞭炮 |

---

### 3. SoundEngine（音效引擎）

**职责**：
- 音效预加载（AVAudioPCMBuffer）
- 音效播放（AVAudioPlayerNode）
- 合成音效生成（无音频文件时）
- 事件订阅和响应

**音效映射**：
```swift
.move       → 440Hz 短促音
.rotate     → 300-600Hz 扫频
.hardDrop   → 150Hz 重击音
.clear1-4   → 和弦（递增）
.gameOver   → 400-100Hz 下降扫频
```

---

### 4. AppTheme（主题系统）

**职责**：
- 主题切换（暗/亮/自定义）
- 颜色管理和持久化
- 自定义主题编辑
- 主题导出/导入

**主题配置**：
```swift
struct ThemeConfig {
    var backgroundColorHex: String
    var boardColorHex: String
    var gridLineColorHex: String
    var accentColorHex: String
    var textColorHex: String
    var panelColorHex: String
    var pieceColorHexMap: [Int: String]  // 各方块颜色
    var particleScheme: ParticleColorScheme
}
```

**粒子配色方案**：
- rainbow（彩虹）
- neon（霓虹）
- fire（火焰）
- ice（冰晶）
- gold（黄金）
- custom（自定义）

---

### 5. LeaderboardManager（排行榜系统）

**职责**：
- 排行榜数据读写（txt 文件）
- 分数提交和排名查询
- 前10名管理

**数据格式**：
```
# NeonTetris2 排行榜
# 格式：名称|分数|等级|行数|时间戳
玩家1|98500|10|320|1711900000
```

**存储位置**：
```
~/Library/Application Support/NeonTetris2/leaderboard.txt
```

---

## 数据流

### 游戏循环
```
Timer (60fps)
  ↓
GameBoardView.displayTimer
  ↓
ParticleSystem.update()
  ↓
Canvas 重绘
```

### 输入处理
```
KeyPress Event
  ↓
GameBoardView.handleKeyPress()
  ↓
GameEngine.moveLeft/Right/rotate/etc()
  ↓
GameEngine.eventPublisher.send()
  ↓
┌─────────────────┬──────────────────┐
│                 │                  │
ParticleSystem    SoundEngine    MusicPlayer
(生成粒子)        (播放音效)      (背景音乐)
```

### 消行流程
```
GameEngine.checkLineClear()
  ↓
clearingRows = [...]
  ↓
startClearAnimation()
  ↓
clearProgress: 0 → 1 (0.4s)
  ↓
finishLineClear()
  ├─ 删除满行
  ├─ 插入空行
  ├─ 更新分数/等级
  ├─ 发送 levelUp 事件
  └─ spawnPiece()
```

---

## 性能优化

### 1. 粒子系统
- **上限控制**：最多 8000 个粒子
- **对象池**：复用 Particle 结构体
- **值类型**：Particle 是 struct，避免引用计数开销
- **批量更新**：每帧一次 update()

### 2. 渲染优化
- **Canvas 缓存**：SwiftUI Canvas 自动缓存
- **网格线透明度**：0.3 降低视觉复杂度
- **幽灵方块**：仅绘制边框，不填充

### 3. 音效优化
- **预加载**：启动时加载所有音效
- **合成音效**：无需磁盘 I/O
- **音效池**：AVAudioPlayerNode 复用

---

## 扩展点

### 1. 添加新粒子类型
```swift
// 1. 在 ParticleKind 中添加
case myEffect

// 2. 在 ParticleFactory 中添加工厂方法
static func myEffect(...) -> Particle { ... }

// 3. 在 ParticleSystem 中添加发射方法
func emitMyEffect(...) { ... }

// 4. 在 GameEngine 中订阅事件并调用
```

### 2. 添加新主题
```swift
// 在 ThemeConfig 中添加预设
static let myTheme = ThemeConfig(...)

// 在 ThemeMode 中添加
case myTheme = "我的主题"
```

### 3. 添加新音效
```swift
// 在 SoundEffect 中添加
case mySound = "mySound"

// 在 SoundEngine.synthesize() 中添加生成逻辑
case .mySound: return generateTone(...)

// 在事件订阅中添加映射
case .myEvent: self.play(.mySound)
```

---

## 调试技巧

### 1. 查看粒子数量
```swift
print("粒子数: \(particles.particles.count)")
```

### 2. 禁用粒子效果
```swift
// 在 ParticleSystem.add() 中
// particles.append(contentsOf: newParticles.prefix(0))
```

### 3. 查看游戏状态
```swift
print("状态: \(engine.gameState)")
print("分数: \(engine.score), 等级: \(engine.level)")
```

### 4. 测试主题
```swift
theme.mode = .custom
theme.customConfig.accentColorHex = "FF00FF"
theme.applyCustom()
```

---

## 已知限制

1. **粒子上限**：8000 个（CPU 版本）
   - 升级方案：使用 Metal GPU 渲染，支持 20000+ 个

2. **音效合成**：简单的正弦波
   - 升级方案：使用预录制的音频文件

3. **单机排行榜**：本地 txt 文件
   - 升级方案：云端排行榜同步

4. **macOS 专用**：不支持 iOS/iPadOS
   - 升级方案：使用 SwiftUI 跨平台代码

---

## 参考资源

- [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [AVFoundation 音频编程](https://developer.apple.com/documentation/avfoundation)
- [Tetris 官方规则](https://tetris.com/play-tetris)
- [SRS 旋转系统](https://tetris.fandom.com/wiki/SRS)
