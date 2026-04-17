// ============================================================
// GameSettings.swift — 游戏设置数据模型
// 负责：等级/速度/音效/音乐/网格/幽灵方块设置的持久化存储
// ============================================================

import SwiftUI
import Combine

// MARK: - 游戏设置（持久化到 UserDefaults）
class GameSettings: ObservableObject {

    // MARK: 庆祝强度
    enum CelebrationIntensity: String, CaseIterable, Codable {
        case normal = "普通"
        case fancy  = "华丽"
        case extreme = "极限"
    }
    @Published var celebrationIntensity: CelebrationIntensity {
        didSet { UserDefaults.standard.set(celebrationIntensity.rawValue, forKey: "celebrationIntensity") }
    }
    // GPU 友好模式（减少叠层光晕绘制层）
    @Published var gpuFriendly: Bool {
        didSet { UserDefaults.standard.set(gpuFriendly, forKey: "gpuFriendly") }
    }
    // FPS 目标（60 / 120）
    @Published var fpsTarget: Int {
        didSet { UserDefaults.standard.set(fpsTarget, forKey: "fpsTarget") }
    }

    // MARK: 游戏参数
    /// 起始等级（1-10）
    @Published var startLevel: Int {
        didSet { UserDefaults.standard.set(startLevel, forKey: "startLevel") }
    }
    /// 下落速度倍率（1-10，叠加在等级速度上）
    @Published var speedMultiplier: Int {
        didSet { UserDefaults.standard.set(speedMultiplier, forKey: "speedMultiplier") }
    }
    
    // MARK: 视图设置
    /// 网格线开关
    @Published var showGrid: Bool {
        didSet { UserDefaults.standard.set(showGrid, forKey: "showGrid") }
    }
    /// 幽灵方块开关
    @Published var showGhostPiece: Bool {
        didSet { UserDefaults.standard.set(showGhostPiece, forKey: "showGhostPiece") }
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
        // 庆祝强度
        if let raw = ud.string(forKey: "celebrationIntensity"), let v = CelebrationIntensity(rawValue: raw) { self.celebrationIntensity = v } else { self.celebrationIntensity = .fancy }
        self.gpuFriendly      = ud.object(forKey: "gpuFriendly")      as? Bool  ?? false
        let t                 = ud.object(forKey: "fpsTarget")         as? Int   ?? 60
        self.fpsTarget        = (t == 120) ? 120 : 60
        self.startLevel       = ud.object(forKey: "startLevel")       as? Int   ?? 1
        self.speedMultiplier  = ud.object(forKey: "speedMultiplier")  as? Int   ?? 5
        self.showGrid         = ud.object(forKey: "showGrid")          as? Bool  ?? true
        self.showGhostPiece  = ud.object(forKey: "showGhostPiece")   as? Bool  ?? true
        self.soundEnabled     = ud.object(forKey: "soundEnabled")     as? Bool  ?? true
        self.soundVolume      = ud.object(forKey: "soundVolume")      as? Float ?? 0.8
        self.musicEnabled     = ud.object(forKey: "musicEnabled")     as? Bool  ?? true
        self.musicVolume      = ud.object(forKey: "musicVolume")      as? Float ?? 0.5
        self.customMusicPath  = ud.string(forKey: "customMusicPath")
    }

    /// 重置为默认值
    func resetToDefaults() {
        celebrationIntensity = .fancy
        gpuFriendly     = false
        fpsTarget       = 60
        startLevel      = 1
        speedMultiplier = 5
        showGrid        = true
        showGhostPiece  = true
        soundEnabled    = true
        soundVolume     = 0.8
        musicEnabled    = true
        musicVolume     = 0.5
        customMusicPath = nil
    }
}
