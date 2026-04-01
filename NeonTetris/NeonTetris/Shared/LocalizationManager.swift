// ============================================================
// LocalizationManager.swift — 语言管理器
// 负责：中英文切换
// ============================================================

import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case chinese = "zh"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "zh"
        self.language = AppLanguage(rawValue: saved) ?? .chinese
    }
    
    func t(_ zh: String, _ en: String) -> String {
        language == .chinese ? zh : en
    }
}
