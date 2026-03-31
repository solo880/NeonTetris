// ============================================================
// ScorePanelView.swift — 分数/等级/速度显示面板
// 负责：实时显示游戏数据
// ============================================================

import SwiftUI

struct ScorePanelView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            Text("游戏数据")
                .font(.headline)
                .foregroundColor(theme.config.textColor)
            
            HStack {
                Text("分数")
                    .foregroundColor(theme.config.textColor.opacity(0.7))
                Spacer()
                Text("\(engine.score)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(theme.config.accentColor)
            }
            
            HStack {
                Text("等级")
                    .foregroundColor(theme.config.textColor.opacity(0.7))
                Spacer()
                Text("\(engine.level)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(theme.config.accentColor)
            }
            
            HStack {
                Text("消行")
                    .foregroundColor(theme.config.textColor.opacity(0.7))
                Spacer()
                Text("\(engine.lines)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(theme.config.accentColor)
            }
            
            Divider()
                .background(theme.config.gridLineColor)
            
            HStack {
                Text("状态")
                    .foregroundColor(theme.config.textColor.opacity(0.7))
                Spacer()
                Text(stateString)
                    .font(.caption)
                    .foregroundColor(stateColor)
            }
        }
        .padding()
        .background(theme.config.panelColor)
        .cornerRadius(8)
    }
    
    private var stateString: String {
        switch engine.gameState {
        case .idle: return "未开始"
        case .playing: return "游戏中"
        case .paused: return "暂停"
        case .clearing: return "消行中"
        case .gameOver: return "游戏结束"
        }
    }
    
    private var stateColor: Color {
        switch engine.gameState {
        case .idle: return .gray
        case .playing: return .green
        case .paused: return .yellow
        case .clearing: return .blue
        case .gameOver: return .red
        }
    }
}

#Preview {
    ScorePanelView(engine: GameEngine(), theme: AppTheme())
}
