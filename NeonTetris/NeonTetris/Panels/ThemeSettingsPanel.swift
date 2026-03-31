// ============================================================
// ThemeSettingsPanel.swift — 主题设置面板
// 负责：暗色/亮色/自定义主题切换和编辑
// ============================================================

import SwiftUI

struct ThemeSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("主题设置")
                    .font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 预设主题选择
                    VStack(alignment: .leading, spacing: 10) {
                        Text("预设主题")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Picker("主题", selection: $theme.mode) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
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
                            Text("自定义颜色")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ColorPickerRow(label: "背景色", hex: $theme.customConfig.backgroundColorHex)
                            Divider()
                            ColorPickerRow(label: "棋盘色", hex: $theme.customConfig.boardColorHex)
                            Divider()
                            ColorPickerRow(label: "网格线", hex: $theme.customConfig.gridLineColorHex)
                            Divider()
                            ColorPickerRow(label: "强调色", hex: $theme.customConfig.accentColorHex)
                            Divider()
                            ColorPickerRow(label: "文字色", hex: $theme.customConfig.textColorHex)
                            Divider()
                            ColorPickerRow(label: "面板色", hex: $theme.customConfig.panelColorHex)
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // 粒子配色方案
                        VStack(alignment: .leading, spacing: 10) {
                            Text("粒子配色")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Picker("方案", selection: $theme.customConfig.particleScheme) {
                                ForEach(ParticleColorScheme.allCases, id: \.self) { scheme in
                                    Text(scheme.rawValue).tag(scheme)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // 操作按钮
                        VStack(spacing: 10) {
                            Button("应用自定义主题") {
                                theme.applyCustom()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            
                            Button("重置为暗色", role: .destructive) {
                                theme.resetCustomToDark()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(6)
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
