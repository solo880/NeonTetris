// ============================================================
// ContentView. swift — 主容器视图 (重构版)
// 负责：整体布局、状态管理、事件订阅
// 改进：使用 .sheet(item:) 模式替代 .sheet(isPresented:)
// ============================================================

import SwiftUI
import Combine

// MARK: - Sheet 类型枚举（使用 Identifiable）
enum GameSheet: Identifiable, Equatable {
    case settings
    case leaderboard
    case audioSettings
    case themeSettings
    
    var id: String {
        switch self {
        case .settings: return "settings"
        case .leaderboard: return "leaderboard"
        case .audioSettings: return "audioSettings"
        case .themeSettings: return "themeSettings"
        }
    }
    
    static func == (lhs: GameSheet, rhs: GameSheet) -> Bool {
        lhs.id == rhs.id
    }
}

struct ContentView: View {
    // MARK: - 共享的 Settings 实例（避免重复创建导致状态不同步）
    @StateObject private var sharedSettings: GameSettings
    
    // MARK: - 依赖对象
    @StateObject private var theme = AppTheme()
    @StateObject private var engine: GameEngine
    @StateObject private var particles = ParticleSystem()
    @StateObject private var leaderboard = LeaderboardManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var celebration = CelebrationSystem()
    
    // MARK: - 音频
    @State private var soundEngine: SoundEngine?
    @State private var musicPlayer: MusicPlayer?
    
    // MARK: - Sheet 状态（使用 Identifiable 替代 isPresented）
    @State private var activeSheet: GameSheet? = nil
    
    // MARK: - 订阅管理
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化（简化）
    init() {
        let settings = GameSettings()
        _sharedSettings = StateObject(wrappedValue: settings)
        _engine = StateObject(wrappedValue: GameEngine(settings: settings))
    }
    
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
                leftPanel
                
                // 中心：游戏板
                ZStack {
                    GameBoardView(
                        engine: engine,
                        theme: theme,
                        particles: particles,
                        settings: sharedSettings
                    )
                    
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
                rightPanel
            }
            .padding(20)
            
            // 庆祝层
            if celebration.isActive {
                CelebrationOverlayView(system: celebration)
                    .onAppear { celebration.configurePerformance(fpsTarget: sharedSettings.fpsTarget) }
                    .onChange(of: sharedSettings.fpsTarget) { celebration.configurePerformance(fpsTarget: $0) }
            }
        }
        .environmentObject(engine)
        .environmentObject(theme)
        .environmentObject(sharedSettings)
        .environmentObject(particles)
        .onAppear { setupGame() }
        .sheet(item: $activeSheet) { sheet in
            sheetView(for: sheet)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .animation(.easeInOut(duration: 0.3), value: theme.mode)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeSheet)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            musicPlayer?.stop()
        }
    }
    
    // MARK: - 左面板
    private var leftPanel: some View {
        VStack(spacing: 15) {
            HoldPieceView(engine: engine, theme: theme, localization: localization)
            ScorePanelView(engine: engine, theme: theme, localization: localization)
            
            BlockButton(
                label: localization.t("游戏设置", "Settings"),
                systemImage: "gearshape",
                color: .blockI,
                action: { activeSheet = .settings }
            )
            
            BlockButton(
                label: localization.t("排行榜", "Leaderboard"),
                systemImage: "trophy",
                color: .blockZ,
                action: { activeSheet = .leaderboard }
            )
            
            Spacer()
        }
        .frame(width: 150)
        .padding()
        .background(theme.config.panelColor)
        .cornerRadius(12)
    }
    
    // MARK: - 右面板
    private var rightPanel: some View {
        VStack(spacing: 15) {
            NextPiecesView(engine: engine, theme: theme, localization: localization)
            
            BlockButton(
                label: localization.language == .chinese ? "切换到英文" : "Switch to Chinese",
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
                action: { activeSheet = .audioSettings }
            )
            
            BlockButton(
                label: localization.t("主题", "Theme"),
                systemImage: "paintbrush",
                color: .blockT,
                action: { activeSheet = .themeSettings }
            )
            
            Spacer()
        }
        .frame(width: 150)
        .padding()
        .background(theme.config.panelColor)
        .cornerRadius(12)
    }
    
    // MARK: - Sheet 视图（使用 item 模式）
    @ViewBuilder
    private func sheetView(for sheet: GameSheet) -> some View {
        switch sheet {
        case .settings:
            GameSettingsPanel(settings: sharedSettings, theme: theme)
                .environmentObject(engine)
        case .leaderboard:
            LeaderboardPanel(leaderboard: leaderboard, theme: theme)
        case .audioSettings:
            AudioSettingsPanel(
                soundEngine: soundEngine,
                musicPlayer: musicPlayer,
                theme: theme
            )
        case .themeSettings:
            ThemeSettingsPanel(theme: theme)
        }
    }
    
    // MARK: - 游戏设置
    private func setupGame() {
        soundEngine = SoundEngine()
        soundEngine?.enabled = sharedSettings.soundEnabled
        soundEngine?.volume = sharedSettings.soundVolume
        
        musicPlayer = MusicPlayer()
        musicPlayer?.enabled = sharedSettings.musicEnabled
        musicPlayer?.volume = sharedSettings.musicVolume
        
        subscribeToEvents()
        musicPlayer?.play()
    }
    
    private func subscribeToEvents() {
        soundEngine?.subscribe(to: engine.eventPublisher)
            .store(in: &cancellables)
        
        engine.eventPublisher.sink { [weak particles] event in
            guard let particles = particles else { return }
            handleGameEvent(event, particles: particles)
        }
        .store(in: &cancellables)
    }
    
    private func handleGameEvent(_ event: GameEvent, particles: ParticleSystem) {
        let blockSize = GameConst.blockSize
        
        switch event {
        case .moveLeft(let piece):
            particles.emitAirFlow(piece: piece, blockSize: blockSize, direction: -1)
        case .moveRight(let piece):
            particles.emitAirFlow(piece: piece, blockSize: blockSize, direction: 1)
        case .rotate(let piece):
            particles.emitSpinOut(piece: piece, blockSize: blockSize, color: piece.type.defaultColor)
        case .softDrop(let piece):
            particles.emitAirFlow(piece: piece, blockSize: blockSize, direction: 0)
        case .hardDrop(let piece, let fromY, let toY):
            particles.emitHardDropTrail(piece: piece, fromY: fromY, toY: toY, blockSize: blockSize, color: piece.type.defaultColor)
        case .lock(let piece):
            particles.emitLockFlash(piece: piece, blockSize: blockSize, color: piece.type.defaultColor)
        case .lineClear(let rows, _):
            particles.emitLineClear(rows: rows, blockSize: blockSize, boardValues: engine.board, pieceColors: { $0.defaultColor })
        default:
            break
        }
    }
    
    private func startGame() {
        engine.startGame()
    }
}

// MARK: - 星空背景（内联）
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
                Star(
                    x: CGFloat.random(in: 0...1000),
                    y: CGFloat.random(in: 0...700),
                    opacity: Double.random(in: 0.3...1.0)
                )
            }
        }
    }
}

#Preview {
    ContentView()
}