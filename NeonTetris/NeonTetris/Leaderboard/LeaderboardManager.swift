// ============================================================
// LeaderboardManager.swift — 排行榜数据管理
// 负责：读写 txt 文件、提交分数、查询排名
// ============================================================

import SwiftUI
import Combine

// MARK: - 排行榜管理器（全局单例）
class LeaderboardManager: ObservableObject {
    static let shared = LeaderboardManager()

    @Published var entries: [LeaderboardEntry] = []

    // txt 文件路径（存放在 Application Support）
    private var filePath: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = dir.appendingPathComponent("NeonTetris", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("leaderboard.txt")
    }

    private init() { load() }

    // MARK: - 加载排行榜
    func load() {
        guard let content = try? String(contentsOf: filePath, encoding: .utf8) else {
            entries = []
            return
        }
        entries = content
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .compactMap { LeaderboardEntry.from(line: $0) }
            .sorted()
            .prefix(GameConst.leaderboardMax)
            .map { $0 }
    }

    // MARK: - 保存排行榜
    private func save() {
        let header = "# NeonTetris 排行榜\n# 格式：名称|分数|等级|行数|时间戳\n"
        let lines = entries.map { $0.txtLine }.joined(separator: "\n")
        try? (header + lines).write(to: filePath, atomically: true, encoding: .utf8)
    }

    // MARK: - 提交新分数，返回排名（1-based，nil 表示未进榜）
    @discardableResult
    func submit(name: String, score: Int, level: Int, lines: Int) -> Int? {
        let entry = LeaderboardEntry(
            playerName: name, score: score, level: level, lines: lines, date: Date()
        )
        entries.append(entry)
        entries.sort()
        entries = Array(entries.prefix(GameConst.leaderboardMax))
        save()

        // 返回排名
        return entries.firstIndex(where: { $0.id == entry.id }).map { $0 + 1 }
    }

    // MARK: - 检查分数是否能进榜
    func canEnter(score: Int) -> Bool {
        if entries.count < GameConst.leaderboardMax { return true }
        return score > (entries.last?.score ?? 0)
    }
    
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

    // MARK: - 清空排行榜
    func clear() {
        entries = []
        save()
    }
}
