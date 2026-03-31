// ============================================================
// GameSettingsPanel.swift — 游戏设置面板
// 负责：等级/速度设置
// ============================================================

import SwiftUI

struct GameSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: GameSettings
    @ObservedObject var theme: AppTheme
    @EnvironmentObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("游戏设置")
                    .font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("起始等级")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(settings.startLevel) },
                        set: { settings.startLevel = Int($0) }
                    ), in: 1...10, step: 1)
                    Text("等级 \(settings.startLevel)")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("下落速度")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(settings.speedMultiplier) },
                        set: { settings.speedMultiplier = Int($0) }
                    ), in: 1...10, step: 1)
                    Text("速度 \(settings.speedMultiplier)/10")
                        .foregroundColor(.secondary)
                }
                
                Button(role: .destructive, action: { settings.resetToDefaults() }) {
                    Text("恢复默认设置")
                        .frame(maxWidth: .infinity)
                }
                
                Spacer()
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    GameSettingsPanel(settings: GameSettings(), theme: AppTheme())
}
