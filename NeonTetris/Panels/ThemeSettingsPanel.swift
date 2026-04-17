// ============================================================
// ThemeSettingsPanel.swift — 主题设置面板
// 负责：暗色/亮色/自定义主题切换和编辑，支持中英文
// ============================================================

import SwiftUI

struct ThemeSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme: AppTheme
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(localization.t("主题设置", "Theme Settings"))
                    .font(.headline)
                Spacer()
                Button(localization.t("关闭", "Close")) { dismiss() }
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 预设主题选择
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.t("预设主题", "Preset Themes"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Picker(localization.t("主题", "Theme"), selection: $theme.mode) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Text(themeModeName(mode)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 自定义颜色编辑
                    if theme.mode == .custom {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(localization.t("自定义颜色", "Custom Colors"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ColorPickerRow(label: localization.t("背景色", "Background"), hex: $theme.customConfig.backgroundColorHex)
                            Divider()
                            ColorPickerRow(label: localization.t("棋盘色", "Board"), hex: $theme.customConfig.boardColorHex)
                            Divider()
                            ColorPickerRow(label: localization.t("网格线", "Grid Lines"), hex: $theme.customConfig.gridLineColorHex)
                            Divider()
                            ColorPickerRow(label: localization.t("强调色", "Accent"), hex: $theme.customConfig.accentColorHex)
                            Divider()
                            ColorPickerRow(label: localization.t("文字色", "Text"), hex: $theme.customConfig.textColorHex)
                            Divider()
                            ColorPickerRow(label: localization.t("面板色", "Panel"), hex: $theme.customConfig.panelColorHex)
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // 粒子配色方案
                        VStack(alignment: .leading, spacing: 10) {
                            Text(localization.t("粒子配色", "Particle Colors"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Picker(localization.t("方案", "Scheme"), selection: $theme.customConfig.particleScheme) {
                                ForEach(ParticleColorScheme.allCases, id: \.self) { scheme in
                                    Text(particleSchemeName(scheme)).tag(scheme)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // 操作按钮
                        VStack(spacing: 10) {
                            BlockButton(
                                label: localization.t("应用自定义主题", "Apply Custom Theme"),
                                color: .blockI,
                                action: { theme.applyCustom() }
                            )
                            
                            DestructiveBlockButton(
                                label: localization.t("重置为暗色", "Reset to Dark"),
                                action: { theme.resetCustomToDark() }
                            )
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(width: 500, height: 700)
    }
    
    private func themeModeName(_ mode: ThemeMode) -> String {
        switch mode {
        case .dark: return localization.t("暗色", "Dark")
        case .light: return localization.t("亮色", "Light")
        case .cyberpunk: return localization.t("赛博朋克", "Cyberpunk")
        case .ocean: return localization.t("海洋", "Ocean")
        case .forest: return localization.t("森林", "Forest")
        case .sunset: return localization.t("日落", "Sunset")
        case .candy: return localization.t("糖果", "Candy")
        case .custom: return localization.t("自定义", "Custom")
        }
    }
    
    private func particleSchemeName(_ scheme: ParticleColorScheme) -> String {
        switch scheme {
        case .neon: return localization.t("霓虹", "Neon")
        case .fire: return localization.t("火焰", "Fire")
        case .ice: return localization.t("冰晶", "Ice")
        case .rainbow: return localization.t("彩虹", "Rainbow")
        case .gold: return localization.t("黄金", "Gold")
        case .custom: return localization.t("自定义", "Custom")
        }
    }
}

// MARK: - 颜色选择器行（改进版 - 独立状态）
struct ColorPickerRow: View {
    let label: String
    @Binding var hex: String
    @State private var selectedColor: NSColor = .white
    @State private var colorPanelTimer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .frame(width: 60, alignment: .leading)
            
            // 颜色预览块（可点击打开颜色选择器）
            ZStack {
                Color(hex: hex)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
                    .border(Color.gray, width: 1)
            }
            .onTapGesture {
                selectedColor = NSColor(Color(hex: hex))
                openColorPanel()
            }
            
            // 十六进制输入框
            TextField("", text: $hex)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .onChange(of: hex) { newValue in
                    // 验证十六进制格式
                    let cleanHex = newValue.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                    if cleanHex.count == 6 || cleanHex.isEmpty {
                        hex = "#" + cleanHex
                    }
                }
            
            Spacer()
        }
        .onDisappear {
            // 清理计时器
            colorPanelTimer?.invalidate()
            colorPanelTimer = nil
        }
    }
    
    private func openColorPanel() {
        let panel = NSColorPanel.shared
        panel.color = selectedColor
        
        // 清理旧的计时器
        colorPanelTimer?.invalidate()
        
        // 使用 Timer 监听颜色变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var lastColor = self.selectedColor
            colorPanelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] _ in
                let newColor = panel.color
                if newColor != lastColor {
                    lastColor = newColor
                    self.selectedColor = newColor
                    self.updateHexFromColor(newColor)
                }
                
                // 检查面板是否关闭
                if !panel.isVisible {
                    self.colorPanelTimer?.invalidate()
                    self.colorPanelTimer = nil
                }
            }
        }
        
        panel.orderFront(nil)
    }
    
    private func updateHexFromColor(_ color: NSColor) {
        if let rgbColor = color.usingColorSpace(.sRGB) {
            let red = Int(rgbColor.redComponent * 255)
            let green = Int(rgbColor.greenComponent * 255)
            let blue = Int(rgbColor.blueComponent * 255)
            hex = String(format: "#%02X%02X%02X", red, green, blue)
        }
    }
}

#Preview {
    ThemeSettingsPanel(theme: AppTheme())
}
