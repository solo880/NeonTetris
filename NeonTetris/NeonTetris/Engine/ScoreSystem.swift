// ============================================================
// ScoreSystem.swift — 分数/等级/速度计算系统
// 负责：消行得分、等级升级、速度计算
// ============================================================

import Foundation

// MARK: - 分数系统
struct ScoreSystem {

    // MARK: - 消行得分计算
    /// 根据消行数和当前等级计算得分
    static func points(lines: Int, level: Int) -> Int {
        let base: Int
        switch lines {
        case 1: base = ScoreConst.single
        case 2: base = ScoreConst.double_
        case 3: base = ScoreConst.triple
        case 4: base = ScoreConst.tetris
        default: base = 0
        }
        return base * level  // 等级越高，得分越多
    }

    // MARK: - 等级计算
    /// 根据总消行数计算当前等级（每10行升一级，最高10级）
    static func level(totalLines: Int, startLevel: Int) -> Int {
        let earned = totalLines / 10
        return min(startLevel + earned, 10)
    }

    // MARK: - 速度计算
    /// 根据等级和速度倍率计算 tick 间隔（秒）
    static func tickInterval(level: Int, speedMultiplier: Int) -> Double {
        let base = GameConst.speedTable[level] ?? 0.5
        // speedMultiplier 1-10，1最慢（×1.5），10最快（×0.5）
        let factor = 1.5 - Double(speedMultiplier - 1) * (1.0 / 9.0)
        return max(base * factor, 0.05)  // 最快不低于 50ms
    }

    // MARK: - 软降得分
    static func softDropPoints(cells: Int) -> Int {
        cells * ScoreConst.softDrop
    }

    // MARK: - 硬降得分
    static func hardDropPoints(cells: Int) -> Int {
        cells * ScoreConst.hardDrop
    }
}
