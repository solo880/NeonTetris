// ============================================================
// ScorePanelView.swift — 计分面板
// 自动根据主题对比分配文字/阴影，确保暗/亮模式清晰可读
// ============================================================

import SwiftUI

struct ScorePanelView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    @ObservedObject var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localization.t("游戏数据", "Game Data"))
                .font(.title2.bold())
                .foregroundStyle(theme.config.accentColor)
                .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)

            row(title: localization.t("等级", "Level"), value: "\(engine.level)")
            row(title: localization.t("行数", "Lines"), value: "\(engine.lines)")
            row(title: localization.t("得分", "Score"), value: "\(engine.score)")

            Divider()
                .overlay(theme.config.gridLineColor)

            HStack {
                Text(localization.t("状态", "Status"))
                Spacer()
                Text(stateString)
                    .font(.caption)
                    .foregroundStyle(stateColor)
            }
            .font(.headline)
            .foregroundStyle(theme.config.textColor)
        }
        .padding(12)
        .background(theme.config.panelColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.config.gridLineColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
        .font(.headline)
        .foregroundStyle(theme.config.textColor)
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
        engine: GameEngine(settings: GameSettings()),
        theme: AppTheme(),
        localization: LocalizationManager.shared
    )
}
