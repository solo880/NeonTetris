// ============================================================
// OverlayView.swift — 游戏状态覆盖层
// 负责：开始/暂停/结束界面、输入姓名、触发庆祝效果
// ============================================================

import SwiftUI

struct OverlayView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    @ObservedObject var particles: ParticleSystem
    @ObservedObject var leaderboard: LeaderboardManager
    @ObservedObject var localization: LocalizationManager
    @ObservedObject var celebrationSystem: CelebrationSystem
    var onStart: () -> Void
    
    @State private var showNameInput = false
    @State private var playerName = ""
    @State private var playerRank: Int? = nil
    @State private var celebrationTriggered = false
    
    // 用于获取屏幕尺寸
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            if engine.gameState == .idle {
                startScreen
            } else if engine.gameState == .paused {
                pauseScreen
            } else if engine.gameState == .gameOver {
                gameOverScreen
            }
            
            // 姓名输入对话框
            if showNameInput {
                nameInputDialog
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    screenSize = geo.size
                }
                .onChange(of: geo.size) { newSize in
                    screenSize = newSize
                }
            }
        )
        .onChange(of: engine.gameState) { newState in
            if newState == .gameOver {
                // 游戏结束，检查是否能进榜
                if leaderboard.canEnter(score: engine.score) {
                    showNameInput = true
                }
            } else {
                // 重置状态
                showNameInput = false
                playerName = ""
                playerRank = nil
                celebrationTriggered = false
            }
        }
    }
    
    private var startScreen: some View {
        VStack(spacing: 30) {
            Text(localization.t("霓虹俄罗斯方块", "Neon Tetris"))
                .font(.system(size: 48, weight: .bold, design: .default))
                .foregroundStyle(.linearGradient(colors: [.orange,.blue,.purple,.green,.red], startPoint: .topTrailing, endPoint: .bottomTrailing))
            
            VStack(spacing: 10) {
                Text(localization.t("快捷键", "Controls"))
                    .font(.headline)
                    .foregroundColor(theme.config.textColor)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(localization.t("← → 移动 | ↑ 旋转 | ↓ 软降", "← → Move | ↑ Rotate | ↓ Soft Drop"))
                    Text(localization.t("Space 硬降 | C 暂存 | P 暂停", "Space Hard Drop | C Hold | P Pause"))
                }
                .font(.caption)
                .foregroundColor(theme.config.textColor.opacity(0.7))
            }
            
            Button(action: onStart) {
                Text(localization.t("开始游戏", "Start Game"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.config.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    private var pauseScreen: some View {
        VStack(spacing: 30) {
            Text(localization.t("暂停", "Paused"))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(theme.config.accentColor)
            
            Button(action: { engine.togglePause() }) {
                Text(localization.t("继续游戏", "Resume"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.config.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    private var gameOverScreen: some View {
        VStack(spacing: 30) {
            Text(localization.t("游戏结束", "Game Over"))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.red)
            
            VStack(spacing: 10) {
                HStack {
                    Text(localization.t("最终分数", "Score"))
                    Spacer()
                    Text("\(engine.score)")
                        .font(.system(.title, design: .monospaced))
                }
                HStack {
                    Text(localization.t("达到等级", "Level"))
                    Spacer()
                    Text("\(engine.level)")
                        .font(.system(.title, design: .monospaced))
                }
                HStack {
                    Text(localization.t("消除行数", "Lines"))
                    Spacer()
                    Text("\(engine.lines)")
                        .font(.system(.title, design: .monospaced))
                }
            }
            .foregroundColor(theme.config.textColor)
            .padding()
            .background(theme.config.panelColor)
            .cornerRadius(8)
            
            Button(action: onStart) {
                Text(localization.t("重新开始", "Restart"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.config.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .keyboardShortcut("r")
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    // MARK: - 姓名输入对话框
    private var nameInputDialog: some View {
        VStack(spacing: 20) {
            Text(localization.t("🎉 恭喜上榜！", "🎉 New High Score!"))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(theme.config.accentColor)
            
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(localization.t("你的成绩", "Your Score"))
                        .font(.headline)
                    
                    HStack {
                        Text("分数：\(engine.score)")
                        Spacer()
                        Text("等级：\(engine.level)")
                        Spacer()
                        Text("行数：\(engine.lines)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(localization.t("请输入你的名字", "Enter Your Name"))
                        .font(.subheadline)
                    
                    TextField(localization.t("玩家姓名", "Player Name"), text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                        .onSubmit {
                            submitScore()
                        }
                }
            }
            .padding()
            
            HStack(spacing: 15) {
                Button(localization.t("取消", "Cancel")) {
                    showNameInput = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button(localization.t("确认", "Confirm")) {
                    submitScore()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(playerName.isEmpty)
            }
        }
        .padding(30)
        .background(theme.config.panelColor)
        .cornerRadius(16)
        .shadow(radius: 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
    }
    
    // MARK: - 提交分数
    private func submitScore() {
        guard !playerName.isEmpty else { return }
        
        // 提交分数
        let rank = leaderboard.submit(
            name: playerName,
            score: engine.score,
            level: engine.level,
            lines: engine.lines
        )
        
        playerRank = rank
        showNameInput = false
        
        // 触发庆祝效果
        if let rank = rank {
            triggerCelebration(rank: rank)
        }
    }
    
    // MARK: - 触发庆祝效果（使用独立庆祝层）
    private func triggerCelebration(rank: Int) {
        guard !celebrationTriggered else { return }
        celebrationTriggered = true
        
        // 使用独立的全屏庆祝层
        CelebrationTrigger.trigger(
            rank: rank,
            system: celebrationSystem,
            screenSize: screenSize
        )
    }
}

#Preview {
    OverlayView(
        engine: GameEngine(),
        theme: AppTheme(),
        particles: ParticleSystem(),
        leaderboard: LeaderboardManager.shared,
        localization: LocalizationManager.shared,
        celebrationSystem: CelebrationSystem(),
        onStart: {}
    )
}
