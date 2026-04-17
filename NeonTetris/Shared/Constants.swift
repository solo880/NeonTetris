// ============================================================
// Constants.swift — 全局常量
// 负责：游戏尺寸、物理参数、UI 常量
// ============================================================

import SwiftUI

// MARK: - 游戏棋盘常量
enum GameConst {
    static let cols       = 10          // 棋盘列数
    static let rows       = 20          // 棋盘行数
    static let blockSize: CGFloat = 34  // 每格像素大小
    static let boardW: CGFloat = CGFloat(cols) * blockSize   // 棋盘宽度
    static let boardH: CGFloat = CGFloat(rows) * blockSize   // 棋盘高度

    // 速度表：等级 1-10 对应每 tick 间隔（秒）
    static let speedTable: [Int: Double] = [
        1: 1.0, 2: 0.85, 3: 0.72, 4: 0.60, 5: 0.50,
        6: 0.40, 7: 0.30, 8: 0.22, 9: 0.15, 10: 0.10
    ]

    // 软降加速倍率
    static let softDropMultiplier: Double = 0.05

    // 锁定延迟（秒）：方块落地后等待时间
    static let lockDelay: Double = 0.5

    // 消行动画时长（秒）
    static let clearAnimDuration: Double = 0.4

    // 排行榜最大条目数
    static let leaderboardMax = 10
}

// MARK: - 分数常量
enum ScoreConst {
    static let single   = 100   // 消1行
    static let double_  = 300   // 消2行
    static let triple   = 500   // 消3行
    static let tetris   = 800   // 消4行（Tetris）
    static let softDrop = 1     // 软降每格
    static let hardDrop = 2     // 硬降每格
}

// MARK: - 粒子常量
enum ParticleConst {
    static let maxParticles = 50000  // 最大粒子数（大幅增加）
    static let ionTrailRate = 8      // 每帧每方块发射离子数（从2增加到8）
    static let airFlowCount = 15     // 移动/下落时空气粒子数（从6增加到15）
    static let spinOutCount = 24     // 旋转甩出粒子数（从12增加到24）
    static let burnCount    = 40     // 行消除燃烧粒子数（每格，从20增加到40）
    static let splashCount  = 20     // 行消除飞溅粒子数（每格，从8增加到20）
}
