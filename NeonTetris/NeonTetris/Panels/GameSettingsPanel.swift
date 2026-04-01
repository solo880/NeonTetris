// ============================================================
// GameSettingsPanel.swift — 游戏设置面板
// 负责：等级/速度/网格/幽灵方块设置
// ============================================================

import SwiftUI

struct GameSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: GameSettings
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("游戏设置")
                    .font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // 起始等级
                    VStack(alignment: .leading, spacing: 10) {
                        Text("起始等级")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Slider(value: Binding(
                            get: { Double(settings.startLevel) },
                            set: { settings.startLevel = Int($0) }
                        ), in: 1...10, step: 1)
                        Text("等级 \(settings.startLevel)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 下落速度
                    VStack(alignment: .leading, spacing: 10) {
                        Text("下落速度")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Slider(value: Binding(
                            get: { Double(settings.speedMultiplier) },
                            set: { settings.speedMultiplier = Int($0) }
                        ), in: 1...10, step: 1)
                        Text("速度 \(settings.speedMultiplier)/10")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 网格线开关
                    VStack(alignment: .leading, spacing: 10) {
                        Text("视图显示")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Toggle(isOn: $settings.showGrid) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("显示网格线")
                                    .font(.body)
                                Text("显示棋盘网格线")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $settings.showGhostPiece) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("显示幽灵方块")
                                    .font(.body)
                                Text("显示方块落地位置的半透明预览")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 重置按钮
                    Button(role: .destructive, action: { settings.resetToDefaults() }) {
                        Text("恢复默认设置")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(width: 400, height: 450)
    }
}

#Preview {
    GameSettingsPanel(settings: GameSettings(), theme: AppTheme())
}
