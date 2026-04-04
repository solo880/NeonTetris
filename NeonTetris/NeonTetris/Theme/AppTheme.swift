// ============================================================
// AppTheme.swift — 主题管理器
// 负责：主题切换、自定义主题持久化、颜色选择器
// ============================================================

import SwiftUI
import Combine

// MARK: - 主题管理器（全局单例，通过 EnvironmentObject 注入）
class AppTheme: ObservableObject {

    @Published var mode: ThemeMode = .dark {
        didSet {
            applyMode()
            saveCustomIfNeeded()
        }
    }

    @Published var config: ThemeConfig = .dark

    // 自定义主题（用户编辑中的副本）
    @Published var customConfig: ThemeConfig = .dark

    // MARK: - 初始化（从 UserDefaults 恢复）
    init() {
        loadSaved()
    }

    // MARK: - 切换模式
    private func applyMode() {
        switch mode {
        case .dark:   config = .dark
        case .light:  config = .light
        case .custom: config = customConfig
        }
        UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
    }

    // MARK: - 应用自定义主题
    func applyCustom() {
        config = customConfig
        mode = .custom
        saveCustom()
    }

    // MARK: - 重置自定义主题为暗色基础
    func resetCustomToDark() {
        customConfig = .dark
        if mode == .custom { config = customConfig }
    }

    // MARK: - 持久化
    private func saveCustomIfNeeded() {
        if mode == .custom { saveCustom() }
    }

    private func saveCustom() {
        if let data = try? JSONEncoder().encode(customConfig) {
            UserDefaults.standard.set(data, forKey: "customTheme")
        }
    }

    private func loadSaved() {
        // 恢复自定义主题
        if let data = UserDefaults.standard.data(forKey: "customTheme"),
           let saved = try? JSONDecoder().decode(ThemeConfig.self, from: data) {
            customConfig = saved
        }
        // 恢复主题模式
        if let raw = UserDefaults.standard.string(forKey: "themeMode"),
           let savedMode = ThemeMode(rawValue: raw) {
            mode = savedMode
        }
        applyMode()
    }

    // MARK: - 导出主题为 JSON 字符串
    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(customConfig),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    // MARK: - 从 JSON 字符串导入主题
    @discardableResult
    func importJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let imported = try? JSONDecoder().decode(ThemeConfig.self, from: data) else {
            return false
        }
        customConfig = imported
        if mode == .custom { config = customConfig }
        saveCustom()
        return true
    }
}
