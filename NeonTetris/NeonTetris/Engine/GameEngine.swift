// ============================================================
// GameEngine.swift — 核心游戏引擎
// 负责：游戏状态机、主循环、输入处理、事件发布
// ============================================================

import SwiftUI
import Combine

// MARK: - 游戏状态枚举
enum GameState {
    case idle       // 未开始
    case playing    // 游戏中
    case paused     // 暂停
    case clearing   // 消行动画中
    case gameOver   // 游戏结束
}

// MARK: - 游戏事件（供粒子系统和音效订阅）
enum GameEvent {
    case moveLeft(piece: TetrominoPiece)
    case moveRight(piece: TetrominoPiece)
    case rotate(piece: TetrominoPiece)
    case rotateFail                         // 旋转失败（撞墙）
    case softDrop(piece: TetrominoPiece)
    case hardDrop(piece: TetrominoPiece, fromY: Int, toY: Int)
    case lock(piece: TetrominoPiece)
    case lineClear(rows: [Int], count: Int) // 消行（行索引列表，消行数）
    case hold                               // 暂存
    case gameOver
    case levelUp(level: Int)
    case wallHit(piece: TetrominoPiece, left: Bool)
}

// MARK: - 核心游戏引擎
@MainActor
class GameEngine: ObservableObject {

    // MARK: - 棋盘状态（0=空，1-7=方块类型）
    @Published var board: [[Int]] = Array(
        repeating: Array(repeating: 0, count: GameConst.cols),
        count: GameConst.rows
    )

    // MARK: - 方块状态
    @Published var currentPiece: TetrominoPiece?    // 当前下落方块
    @Published var ghostPiece: TetrominoPiece?      // 幽灵方块（落点预览）
    @Published var heldPiece: PieceType?            // 暂存方块
    @Published var nextPieces: [PieceType] = []     // 下一个方块队列（显示3个）
    @Published var canHold: Bool = true             // 是否可以暂存（每次锁定后重置）

    // MARK: - 游戏数据
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var lines: Int = 0          // 总消行数
    @Published var gameState: GameState = .idle
    
    // MARK: - 计算属性
    /// 当前下落间隔（秒）
    var currentDropInterval: Double {
        ScoreSystem.tickInterval(level: level, speedMultiplier: settings.speedMultiplier)
    }
    /// 当前速度（格/秒）
    var currentSpeed: Double {
        1.0 / currentDropInterval
    }

    // MARK: - 消行动画状态
    @Published var clearingRows: [Int] = []         // 正在消除的行索引
    @Published var clearProgress: Double = 0.0      // 消行动画进度 0-1

    // MARK: - 事件流（供外部订阅）
    let eventPublisher = PassthroughSubject<GameEvent, Never>()

    // MARK: - 私有状态
    private var bag: [PieceType] = []               // 7-bag 随机袋
    private var gravityTimer: Timer?                // 重力计时器
    private var lockTimer: Timer?                   // 锁定延迟计时器
    private var clearTimer: Timer?                  // 消行动画计时器
    private var isLocking: Bool = false             // 是否在锁定延迟中
    private var lockResetCount: Int = 0             // 锁定重置次数（最多15次）
    private var hardDropStartY: Int = 0             // 硬降起始行（用于粒子）

    // MARK: - 设置引用（外部传入，共享实例）
    var settings: GameSettings {
        didSet {
            subscribeToSettings()
        }
    }
    
    // MARK: - 私有属性
    private var settingsCancellable: AnyCancellable?
    
    /// 订阅设置变化
    private func subscribeToSettings() {
        settingsCancellable?.cancel()
        settingsCancellable = settings.$speedMultiplier
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onSpeedChanged()
            }
        settingsCancellable = settings.$startLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onLevelChanged()
            }
    }
    
    /// 速度设置变化时，重启重力计时器
    private func onSpeedChanged() {
        guard gameState == .playing else { return }
        startGravity()
    }
    
    /// 等级设置变化时，更新当前等级（游戏未开始时）
    private func onLevelChanged() {
        guard gameState == .idle else { return }
        level = settings.startLevel
    }

    // MARK: - 初始化
    init(settings: GameSettings = GameSettings()) {
        self.settings = settings
        refillBag()
        refillBag()  // 预填充两袋保证 nextPieces 足够
        
        // 监听设置变化
        subscribeToSettings()
    }

    // MARK: - 开始游戏
    func startGame() {
        // 重置所有状态
        board = Array(repeating: Array(repeating: 0, count: GameConst.cols), count: GameConst.rows)
        score = 0
        lines = 0
        level = settings.startLevel
        heldPiece = nil
        canHold = true
        clearingRows = []
        bag = []
        nextPieces = []
        refillBag(); refillBag()

        gameState = .playing
        spawnPiece()
        startGravity()
    }

    // MARK: - 暂停/继续
    func togglePause() {
        switch gameState {
        case .playing:
            gameState = .paused
            stopGravity()
        case .paused:
            gameState = .playing
            startGravity()
        default:
            break
        }
    }

    // MARK: - 停止游戏
    func stopGame() {
        stopGravity()
        stopLockTimer()
        stopClearTimer()
        gameState = .idle
    }

    // =========================================================
    // MARK: - 输入处理
    // =========================================================

    /// 左移
    func moveLeft() {
        guard gameState == .playing, let piece = currentPiece else { return }
        var moved = piece; moved.x -= 1
        if isValid(moved) {
            currentPiece = moved
            updateGhost()
            resetLockIfNeeded()
            eventPublisher.send(.moveLeft(piece: moved))
        } else {
            eventPublisher.send(.wallHit(piece: piece, left: true))
        }
    }

    /// 右移
    func moveRight() {
        guard gameState == .playing, let piece = currentPiece else { return }
        var moved = piece; moved.x += 1
        if isValid(moved) {
            currentPiece = moved
            updateGhost()
            resetLockIfNeeded()
            eventPublisher.send(.moveRight(piece: moved))
        } else {
            eventPublisher.send(.wallHit(piece: piece, left: false))
        }
    }

    /// 旋转（顺时针）
    func rotate() {
        guard gameState == .playing, let piece = currentPiece else { return }
        let newRot = (piece.rotation + 1) % 4
        var rotated = piece; rotated.rotation = newRot

        // SRS 踢墙
        let kicks = TetrominoDefinitions.wallKicks(type: piece.type, from: piece.rotation, to: newRot)
        for (dx, dy) in kicks {
            var kicked = rotated
            kicked.x += dx; kicked.y -= dy
            if isValid(kicked) {
                currentPiece = kicked
                updateGhost()
                resetLockIfNeeded()
                eventPublisher.send(.rotate(piece: kicked))
                return
            }
        }
        eventPublisher.send(.rotateFail)
    }

    /// 软降（加速下落）
    func softDrop() {
        guard gameState == .playing, let piece = currentPiece else { return }
        var dropped = piece; dropped.y += 1
        if isValid(dropped) {
            currentPiece = dropped
            score += ScoreSystem.softDropPoints(cells: 1)
            eventPublisher.send(.softDrop(piece: dropped))
        } else {
            // 已到底，触发锁定
            triggerLock()
        }
    }

    /// 硬降（瞬间落到底）
    func hardDrop() {
        guard gameState == .playing, let piece = currentPiece else { return }
        hardDropStartY = piece.y
        var dropped = piece
        while isValid({ var p = dropped; p.y += 1; return p }()) {
            dropped.y += 1
        }
        let distance = dropped.y - piece.y
        score += ScoreSystem.hardDropPoints(cells: distance)
        currentPiece = dropped
        eventPublisher.send(.hardDrop(piece: dropped, fromY: hardDropStartY, toY: dropped.y))
        lockPiece()  // 硬降立即锁定，无延迟
    }

    /// 暂存/交换方块
    func holdPiece() {
        guard gameState == .playing, canHold, let piece = currentPiece else { return }
        canHold = false
        stopLockTimer()

        if let held = heldPiece {
            // 交换暂存
            heldPiece = piece.type
            spawnPiece(type: held)
        } else {
            // 首次暂存
            heldPiece = piece.type
            spawnPiece()
        }
        eventPublisher.send(.hold)
    }

    // =========================================================
    // MARK: - 重力系统
    // =========================================================

    private func startGravity() {
        stopGravity()
        let interval = ScoreSystem.tickInterval(level: level, speedMultiplier: settings.speedMultiplier)
        gravityTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopGravity() {
        gravityTimer?.invalidate()
        gravityTimer = nil
    }

    /// 重力 tick：方块下落一格
    private func tick() {
        guard gameState == .playing, let piece = currentPiece else { return }
        var dropped = piece; dropped.y += 1
        if isValid(dropped) {
            currentPiece = dropped
        } else {
            // 到底，开始锁定延迟
            if !isLocking {
                startLockTimer()
            }
        }
    }

    // =========================================================
    // MARK: - 锁定系统
    // =========================================================

    private func startLockTimer() {
        isLocking = true
        lockTimer = Timer.scheduledTimer(withTimeInterval: GameConst.lockDelay, repeats: false) { [weak self] _ in
            self?.lockPiece()
        }
    }

    private func stopLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
        isLocking = false
        lockResetCount = 0
    }

    /// 锁定延迟重置（移动/旋转时重置，最多15次）
    private func resetLockIfNeeded() {
        guard isLocking, lockResetCount < 15 else { return }
        // 检查方块是否仍在底部
        guard let piece = currentPiece else { return }
        var below = piece; below.y += 1
        if !isValid(below) {
            lockResetCount += 1
            stopLockTimer()
            startLockTimer()
        } else {
            // 方块已不在底部，取消锁定
            stopLockTimer()
        }
    }

    private func triggerLock() {
        guard !isLocking else { return }
        startLockTimer()
    }

    /// 执行锁定：将方块写入棋盘
    private func lockPiece() {
        guard let piece = currentPiece else { return }
        stopLockTimer()
        stopGravity()

        // 写入棋盘
        for block in piece.blocks {
            if block.y >= 0 && block.y < GameConst.rows && block.x >= 0 && block.x < GameConst.cols {
                board[block.y][block.x] = piece.type.rawValue
            }
        }

        eventPublisher.send(.lock(piece: piece))
        canHold = true
        currentPiece = nil
        ghostPiece = nil

        // 检查消行
        checkLineClear()
    }

    // =========================================================
    // MARK: - 消行系统
    // =========================================================

    private func checkLineClear() {
        let fullRows = (0..<GameConst.rows).filter { row in
            board[row].allSatisfy { $0 != 0 }
        }

        if fullRows.isEmpty {
            // 无消行，直接生成下一个方块
            checkTopOut()
            return
        }

        // 开始消行动画
        clearingRows = fullRows
        clearProgress = 0.0
        gameState = .clearing
        stopGravity()

        // 发送消行事件（在清空前发送，粒子系统需要行信息）
        eventPublisher.send(.lineClear(rows: fullRows, count: fullRows.count))

        // 启动消行动画计时器
        startClearAnimation()
    }

    private func startClearAnimation() {
        let step = 0.05  // 每帧进度步长
        clearTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.clearProgress += step
            if self.clearProgress >= 1.0 {
                self.finishLineClear()
            }
        }
    }

    private func stopClearTimer() {
        clearTimer?.invalidate()
        clearTimer = nil
    }

    private func finishLineClear() {
        stopClearTimer()

        let count = clearingRows.count
        let sorted = clearingRows.sorted(by: >)

        // 删除满行，插入空行
        for row in sorted { board.remove(at: row) }
        for _ in 0..<count {
            board.insert(Array(repeating: 0, count: GameConst.cols), at: 0)
        }

        // 更新分数和等级
        let oldLevel = level
        lines += count
        score += ScoreSystem.points(lines: count, level: level)
        level = ScoreSystem.level(totalLines: lines, startLevel: settings.startLevel)

        if level > oldLevel {
            eventPublisher.send(.levelUp(level: level))
        }

        // 清理状态
        clearingRows = []
        clearProgress = 0.0
        gameState = .playing

        // 生成下一个方块
        checkTopOut()
    }

    // =========================================================
    // MARK: - 顶部溢出检测
    // =========================================================

    private func checkTopOut() {
        // 检查棋盘顶部两行是否有方块
        let topFilled = (0..<2).contains { row in
            board[row].contains { $0 != 0 }
        }
        if topFilled {
            triggerGameOver()
        } else {
            spawnPiece()
            startGravity()
        }
    }

    private func triggerGameOver() {
        stopGravity()
        stopLockTimer()
        gameState = .gameOver
        eventPublisher.send(.gameOver)
    }

    // =========================================================
    // MARK: - 方块生成
    // =========================================================

    private func spawnPiece(type: PieceType? = nil) {
        let pieceType = type ?? dequeue()
        let startX = GameConst.cols / 2 - 2  // 居中生成
        let startY = 0

        let piece = TetrominoPiece(type: pieceType, x: startX, y: startY, rotation: 0)
        currentPiece = piece
        updateGhost()
    }

    /// 从队列取出下一个方块
    private func dequeue() -> PieceType {
        if nextPieces.isEmpty { refillBag() }
        let next = nextPieces.removeFirst()
        if nextPieces.count < 3 { refillBag() }
        return next
    }

    /// 7-bag 随机算法：每7个方块包含所有类型各一次
    private func refillBag() {
        let newBag = PieceType.allCases.shuffled()
        nextPieces.append(contentsOf: newBag)
    }

    // =========================================================
    // MARK: - 幽灵方块
    // =========================================================

    private func updateGhost() {
        guard let piece = currentPiece else { ghostPiece = nil; return }
        var ghost = piece
        while isValid({ var p = ghost; p.y += 1; return p }()) {
            ghost.y += 1
        }
        ghostPiece = ghost
    }

    // =========================================================
    // MARK: - 碰撞检测
    // =========================================================

    func isValid(_ piece: TetrominoPiece) -> Bool {
        for block in piece.blocks {
            if block.x < 0 || block.x >= GameConst.cols { return false }
            if block.y >= GameConst.rows { return false }
            if block.y >= 0 && board[block.y][block.x] != 0 { return false }
        }
        return true
    }
}
