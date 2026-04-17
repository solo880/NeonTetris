// ============================================================
// GameSettingsPanel.swift — 游戏设置面板
// 负责：等级/速度/网格/幽灵方块设置，支持中英文
// ============================================================

import SwiftUI

struct GameSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: GameSettings
    @ObservedObject var theme: AppTheme
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(localization.t("游戏设置", "Settings"))
                    .font(.headline)
                Spacer()
                Button(localization.t("关闭", "Close")) { dismiss() }
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // 起始等级
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.t("起始等级", "Start Level"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Slider(value: Binding(
                            get: { Double(settings.startLevel) },
                            set: { settings.startLevel = Int($0) }
                        ), in: 1...10, step: 1)
                        Text(localization.t("等级", "Level") + " \(settings.startLevel)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 下落速度
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.t("下落速度", "Drop Speed"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Slider(value: Binding(
                            get: { Double(settings.speedMultiplier) },
                            set: { settings.speedMultiplier = Int($0) }
                        ), in: 1...10, step: 1)
                        Text(localization.t("速度", "Speed") + " \(settings.speedMultiplier)/10")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 性能设置
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.t("性能设置", "Performance"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Toggle(localization.t("GPU 友好模式（减少光晕叠层）", "GPU Friendly (reduce glow layers)"), isOn: $settings.gpuFriendly)
                        Picker(localization.t("目标帧率", "FPS Target"), selection: $settings.fpsTarget) {
                            Text("60").tag(60)
                            Text("120").tag(120)
                        }
                        .pickerStyle(.segmented)
                        Text(localization.t("在低性能设备上建议开启 GPU 友好模式；根据显示器选择 60/120 FPS 目标。", "Enable GPU friendly on low-end; choose 60/120 depending on display"))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)

                    // 庆祝强度
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.t("庆祝强度", "Celebration Intensity"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Picker("", selection: $settings.celebrationIntensity) {
                            Text("普通").tag(GameSettings.CelebrationIntensity.normal)
                            Text("华丽").tag(GameSettings.CelebrationIntensity.fancy)
                            Text("极限").tag(GameSettings.CelebrationIntensity.extreme)
                        }
                        .pickerStyle(.segmented)
                        Text(localization.t("影响烟花/鞭炮数量、频率和寿命", "Affect fireworks/crackers amount, rate and lifetime"))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)

                    // 视图显示
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.t("视图显示", "Display"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Toggle(isOn: $settings.showGrid) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localization.t("显示网格线", "Show Grid"))
                                    .font(.body)
                                Text(localization.t("显示棋盘网格线", "Display board grid lines"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $settings.showGhostPiece) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localization.t("显示幽灵方块", "Show Ghost Piece"))
                                    .font(.body)
                                Text(localization.t("显示方块落地位置的半透明预览", "Show landing preview"))
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
                    DestructiveBlockButton(
                        label: localization.t("恢复默认设置", "Reset to Defaults"),
                        action: { settings.resetToDefaults() }
                    )
                    .padding()
                    
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
