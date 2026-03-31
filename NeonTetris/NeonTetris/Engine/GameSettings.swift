// ============================================================
// GameSettings.swift — 游戏设置数据模型
// 负责：等级/速度/音效/音乐设置的持久化存储
// ============================================================

import SwiftUI
import Combine

// MARK: - 游戏设置（持久化到 UserDefaults）
class GameSettings: ObservableObject {

    // MARK: 游戏参数
    /// 起始等级（1-10）
    @Published var startLevel: Int {
        didSet { UserDefaults.standard.set(startLevel, forKey: "startLevel") }
    }
    /// 下落速度倍率（1-10，叠加在等级速度上）
    @Published var speedMultiplier: Int {
        didSet { UserDefaults.standard.set(speedMultiplier, forKey: "speedMultiplier") }
    }

    // MARK: 音效设置
    /// 音效开关
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    /// 音效音量（0.0-1.0）
    @Published var soundVolume: Float {
        didSet { UserDefaults.standard.set(soundVolume, forKey: "soundVolume") }
    }

    // MARK: 背景音乐设置
    /// 背景音乐开关
    @Published var musicEnabled: Bool {
        didSet { UserDefaults.standard.set(musicEnabled, forKey: "musicEnabled") }
    }
    /// 背景音乐音量（0.0-1.0）
    @Published var musicVolume: Float {
        didSet { UserDefaults.standard.set(musicVolume, forKey: "musicVolume") }
    }
    /// 自选音乐文件路径（nil 表示使用内置 BGM）
    @Published var customMusicPath: String? {
        didSet { UserDefaults.standard.set(customMusicPath, forKey: "customMusicPath") }
    }

    // MARK: 初始化（从 UserDefaults 读取）
    init() {
        let ud = UserDefaults.standard
        self.startLevel       = ud.object(forKey: "startLevel")       as? Int   ?? 1
        self.speedMultiplier  = ud.object(forKey: "speedMultiplier")  as? Int   ?? 5
        self.soundEnabled     = ud.object(forKey: "soundEnabled")     as? Bool  ?? true
        self.soundVolume      = ud.object(forKey: "soundVolume")      as? Float ?? 0.8
        self.musicEnabled     = ud.object(forKey: "musicEnabled")     as? Bool  ?? true
        self.musicVolume      = ud.object(forKey: "musicVolume")      as? Float ?? 0.5
        self.customMusicPath  = ud.string(forKey: "customMusicPath")
    }

    /// 重置为默认值
    func resetToDefaults() {
        startLevel      = 1
        speedMultiplier = 5
        soundEnabled    = true
        soundVolume     = 0.8
        musicEnabled    = true
        musicVolume     = 0.5
        customMusicPath = nil
    }
}
