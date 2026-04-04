// ============================================================
// ScorePanelView.swift — 分数/等级/速度显示面板
// 负责：实时显示游戏数据，支持中英文
// ============================================================

import SwiftUI

struct ScorePanelView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    @ObservedObject var localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text(localization.t("游戏数据", "Game Data"))
                .font(.headline)
                .foregroundColor(.black)
                .outlineShadow(color: .white)
            
            HStack {
                Text(localization.t("分数", "Score"))
                    .foregroundColor(.black)
                    .outlineShadow(color: .white)
                Spacer()
                Text("\(engine.score)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(stateColor)
                    .outlineShadow(color: .white)
            }
            
            HStack {
                Text(localization.t("等级", "Level"))
                    .foregroundColor(.black)
                    .outlineShadow(color: .white)
                Spacer()
                Text("\(engine.level)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(stateColor)
                    .outlineShadow(color: .white)
            }
            
            HStack {
                Text(localization.t("速度", "Speed"))
                    .foregroundColor(.black)
                    .outlineShadow(color: .white)
                Spacer()
                Text(String(format: "%.1f", engine.currentSpeed))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(stateColor)
                    .outlineShadow(color: .white)
            }
            
            HStack {
                Text(localization.t("消行", "Lines"))
                    .foregroundColor(.black)
                    .outlineShadow(color: .white)
                Spacer()
                Text("\(engine.lines)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(stateColor)
                    .outlineShadow(color: .white)
            }
            
            Divider()
                .background(theme.config.gridLineColor)
            
            HStack {
                Text(localization.t("状态", "Status"))
                    .foregroundColor(.black)
                    .outlineShadow(color: .white)
                Spacer()
                Text(stateString)
                    .font(.caption)
                    .foregroundColor(stateColor)
                    .outlineShadow(color: .white)
            }
        }
        .padding()
        .background(theme.config.panelColor)
        .cornerRadius(8)
    }
    
    private var stateString: String {
        switch engine.gameState {
        case .idle: return localization.t("未开始", "Idle")
        case .playing: return localization.t("游戏中", "Playing")
        case .paused: return localization.t("暂停", "Paused")
        case .clearing: return localization.t("消行中", "Clearing")
        case .gameOver: return localization.t("游戏结束", "Game Over")
        }
    }
    
    private var stateColor: Color {
        switch engine.gameState {
        case .idle: return .gray
        case .playing: return .green
        case .paused: return .blue
        case .clearing: return .yellow
        case .gameOver: return .red
        }
    }
}

#Preview {
    ScorePanelView(
        engine: GameEngine(),
        theme: AppTheme(),
        localization: LocalizationManager.shared
    )
}
