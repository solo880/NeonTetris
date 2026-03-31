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
            
            Form {
                Section("预设主题") {
                    Picker("主题", selection: $theme.mode) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                if theme.mode == .custom {
                    Section("自定义颜色") {
                        ColorPickerRow(label: "背景色", hex: $theme.customConfig.backgroundColorHex)
                        ColorPickerRow(label: "棋盘色", hex: $theme.customConfig.boardColorHex)
                        ColorPickerRow(label: "网格线", hex: $theme.customConfig.gridLineColorHex)
                        ColorPickerRow(label: "强调色", hex: $theme.customConfig.accentColorHex)
                        ColorPickerRow(label: "文字色", hex: $theme.customConfig.textColorHex)
                        ColorPickerRow(label: "面板色", hex: $theme.customConfig.panelColorHex)
                    }
                    
                    Section("粒子配色") {
                        Picker("方案", selection: $theme.customConfig.particleScheme) {
                            ForEach(ParticleColorScheme.allCases, id: \.self) { scheme in
                                Text(scheme.rawValue).tag(scheme)
                            }
                        }
                    }
                    
                    Section {
                        Button("应用自定义主题") {
                            theme.applyCustom()
                        }
                        Button("重置为暗色", role: .destructive) {
                            theme.resetCustomToDark()
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 600)
    }
}

// MARK: - 颜色选择器行
struct ColorPickerRow: View {
    let label: String
    @Binding var hex: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            ZStack {
                Color(hex: hex)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .border(Color.gray, width: 1)
            }
            .onTapGesture {
                // 打开颜色选择器（macOS NSColorPanel）
                let panel = NSColorPanel.shared
                panel.color = NSColor(Color(hex: hex))
                panel.orderFront(nil)
            }
            TextField("", text: $hex)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    ThemeSettingsPanel(theme: AppTheme())
}
