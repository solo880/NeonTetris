// ============================================================
// LeaderboardEntry.swift — 排行榜条目数据模型
// 负责：排行榜条目的数据结构和 txt 序列化
// ============================================================

import Foundation

// MARK: - 排行榜条目
struct LeaderboardEntry: Identifiable, Comparable {
    let id = UUID()
    var playerName: String  // 玩家名称
    var score: Int          // 分数
    var level: Int          // 达到的等级
    var lines: Int          // 消除行数
    var date: Date          // 日期

    // 按分数降序排列
    static func < (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.score > rhs.score
    }

    // MARK: - txt 序列化（格式：名称|分数|等级|行数|时间戳）
    var txtLine: String {
        let ts = Int(date.timeIntervalSince1970)
        return "\(playerName)|\(score)|\(level)|\(lines)|\(ts)"
    }

    // MARK: - 从 txt 行解析
    static func from(line: String) -> LeaderboardEntry? {
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 5,
              let score = Int(parts[1]),
              let level = Int(parts[2]),
              let lines = Int(parts[3]),
              let ts    = Double(parts[4]) else { return nil }
        return LeaderboardEntry(
            playerName: parts[0],
            score: score,
            level: level,
            lines: lines,
            date: Date(timeIntervalSince1970: ts)
        )
    }

    // MARK: - 格式化日期显示
    var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
