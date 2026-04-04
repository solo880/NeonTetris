// ============================================================
// ContentView.swift — 主容器视图
// 负责：整体布局、状态管理、事件订阅
// ============================================================

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    @StateObject private var theme = AppTheme()
    @StateObject private var settings = GameSettings()
    @StateObject private var particles = ParticleSystem()
    @StateObject private var leaderboard = LeaderboardManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var celebration = CelebrationSystem()  // 独立庆祝粒子层
    
    @State private var soundEngine: SoundEngine?
    @State private var musicPlayer: MusicPlayer?
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var showAudioSettings = false
    @State private var showThemeSettings = false
    @State private var gameWasPlaying = false
    
    // 保存订阅，防止被立即释放
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // 背景
            theme.config.backgroundColor
                .ignoresSafeArea()
            
            // 星空背景动画
            StarfieldBackground()
                .ignoresSafeArea()
            
            // 主游戏布局
            HStack(spacing: 20) {
                // 左面板
                VStack(spacing: 15) {
                    HoldPieceView(engine: engine, theme: theme, localization: localization)
                    ScorePanelView(engine: engine, theme: theme, localization: localization)
                    
                    BlockButton(
                        label: localization.t("游戏设置", "Settings"),
                        systemImage: "gearshape",
                        color: .blockI,
                        action: { showSettings = true }
                    )
                    
                    BlockButton(
                        label: localization.t("排行榜", "Leaderboard"),
                        systemImage: "trophy",
                        color: .blockZ,
                        action: { showLeaderboard = true }
                    )
                    
                    Spacer()
                }
                .frame(width: 150)
                .padding()
                .background(theme.config.panelColor)
                .cornerRadius(12)
                
                // 中心：游戏板
                ZStack {
                    GameBoardView(engine: engine, theme: theme, particles: particles, settings: settings)
                    
                    // 游戏状态覆盖
                    OverlayView(
                        engine: engine,
                        theme: theme,
                        particles: particles,
                        leaderboard: leaderboard,
                        localization: LocalizationManager.shared,
                        celebrationSystem: celebration,
                        soundEngine: soundEngine,
                        onStart: startGame
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 右面板
                VStack(spacing: 15) {
                    NextPiecesView(engine: engine, theme: theme, localization: localization)
                    
                    BlockButton(
                        label: localization.language == .chinese ? "English" : "中文",
                        systemImage: "globe",
                        color: .blockO,
                        action: {
                            localization.language = localization.language == .chinese ? .english : .chinese
                        }
                    )
                    
                    BlockButton(
                        label: localization.t("音频", "Audio"),
                        systemImage: "speaker.wave.2",
                        color: .blockL,
                        action: { showAudioSettings = true }
                    )
                    
                    BlockButton(
                        label: localization.t("主题", "Theme"),
                        systemImage: "paintbrush",
                        color: .blockT,
                        action: { showThemeSettings = true }
                    )
                    
                    Spacer()
                }
                .frame(width: 150)
                .padding()
                .background(theme.config.panelColor)
                .cornerRadius(12)
            }
            .padding(20)
            
            // 🎆 全屏庆祝层（仅在庆祝时显示，覆盖整个界面）
            if celebration.isActive {
                CelebrationOverlayView(system: celebration)
            }
        }
        .environmentObject(engine)
        .environmentObject(theme)
        .environmentObject(settings)
        .environmentObject(particles)
        .onAppear { setupGame() }
        .sheet(isPresented: $showSettings) {
            GameSettingsPanel(settings: settings, theme: theme)
                .environmentObject(engine)
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardPanel(leaderboard: leaderboard, theme: theme)
        }
        .sheet(isPresented: $showAudioSettings) {
            AudioSettingsPanel(soundEngine: soundEngine, musicPlayer: musicPlayer, theme: theme)
        }
        .sheet(isPresented: $showThemeSettings) {
            ThemeSettingsPanel(theme: theme)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            musicPlayer?.stop()
        }
    }
    
    private func setupGame() {
        // 初始化音频引擎
        soundEngine = SoundEngine()
        soundEngine?.enabled = settings.soundEnabled
        soundEngine?.volume = settings.soundVolume
        
        musicPlayer = MusicPlayer()
        musicPlayer?.enabled = settings.musicEnabled
        musicPlayer?.volume = settings.musicVolume
        
        // 订阅游戏事件 — 必须 store 否则立即释放
        soundEngine?.subscribe(to: engine.eventPublisher)
            .store(in: &cancellables)
        
        // 订阅粒子事件
        engine.eventPublisher.sink { [weak particles] event in
            guard let particles = particles else { return }
            switch event {
            case .moveLeft(let piece):
                particles.emitAirFlow(piece: piece, blockSize: GameConst.blockSize, direction: -1)
            case .moveRight(let piece):
                particles.emitAirFlow(piece: piece, blockSize: GameConst.blockSize, direction: 1)
            case .rotate(let piece):
                particles.emitSpinOut(piece: piece, blockSize: GameConst.blockSize, color: piece.type.defaultColor)
            case .softDrop(let piece):
                particles.emitAirFlow(piece: piece, blockSize: GameConst.blockSize, direction: 0)
            case .hardDrop(let piece, let fromY, let toY):
                particles.emitHardDropTrail(piece: piece, fromY: fromY, toY: toY, blockSize: GameConst.blockSize, color: piece.type.defaultColor)
            case .lock(let piece):
                particles.emitLockFlash(piece: piece, blockSize: GameConst.blockSize, color: piece.type.defaultColor)
            case .lineClear(let rows, _):
                particles.emitLineClear(rows: rows, blockSize: GameConst.blockSize, boardValues: engine.board, pieceColors: { $0.defaultColor })
            default:
                break
            }
        }
        .store(in: &cancellables)
        
        musicPlayer?.play()
    }
    
    private func startGame() {
        engine.startGame()
    }
}

// MARK: - 星空背景
struct StarfieldBackground: View {
    @State private var stars: [Star] = []
    
    struct Star {
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        Canvas { context, size in
            for star in stars {
                var path = Path()
                path.addEllipse(in: CGRect(x: star.x, y: star.y, width: 2, height: 2))
                context.fill(path, with: .color(.white.opacity(star.opacity)))
            }
        }
        .onAppear {
            stars = (0..<100).map { _ in
                Star(x: CGFloat.random(in: 0...1000),
                     y: CGFloat.random(in: 0...700),
                     opacity: Double.random(in: 0.3...1.0))
            }
        }
    }
}

#Preview {
    ContentView()
}
