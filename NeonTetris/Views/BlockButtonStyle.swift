// ============================================================
// BlockButtonStyle.swift — 方块按钮样式
// 负责：让所有按钮背景显示为拉长的游戏方块
// ============================================================

import SwiftUI

// MARK: - 方块按钮样式
struct BlockButtonStyle: ButtonStyle {
    var color: Color = .blue
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {
            // 左侧方块
            BlockSegment(color: effectiveColor, opacity: configuration.isPressed ? 0.7 : 1.0)
            // 中间部分
            BlockSegment(color: effectiveColor, opacity: configuration.isPressed ? 0.7 : 1.0)
               
            BlockSegment(color: effectiveColor, opacity: configuration.isPressed ? 0.7 : 1.0)
            BlockSegment(color: effectiveColor, opacity: configuration.isPressed ? 0.7 : 1.0)
        }
        .frame(height: 36)
        .cornerRadius(18)
        .overlay(
            // 高光效果
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 18)
                .frame(width: 120)
                //.offset(y: 3)
               .cornerRadius(18),
            alignment: .top
        )
        .overlay(
            configuration.label
                .foregroundColor(effectiveColor.idealTextColor())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
        )
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var effectiveColor: Color {
        if isDestructive {
            return .red
        }
        return color
    }
}

// MARK: - 方块片段
struct BlockSegment: View {
    var color: Color
    var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // 底层（深色）
            color.opacity(0.7 * opacity)
            // 主体
            color.opacity(opacity)
                .overlay(
                    // 左上高光
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 3, height: 3)
                        .offset(x: 2, y: 2),
                    alignment: .topLeading
                )
        }
        .frame(width: 34, height: 34)
    }
}

// MARK: - 预览按钮组件（用于游戏面板按钮）
struct BlockButton: View {
    var label: String
    var systemImage: String? = nil
    var color: Color = .blue
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let image = systemImage {
                    Image(systemName: image)
                }
                Text(label)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BlockButtonStyle(color: color))
    }
}

// MARK: - 危险按钮组件
struct DestructiveBlockButton: View {
    var label: String
    var systemImage: String? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let image = systemImage {
                    Image(systemName: image)
                }
                Text(label)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BlockButtonStyle(isDestructive: true))
    }
}

// MARK: - 方块预设颜色
extension Color {
    static let blockI = Color(red: 0.0, green: 0.9, blue: 1.0)      // 青色 I
    static let blockO = Color(red: 1.0, green: 0.9, blue: 0.0)      // 黄色 O
    static let blockT = Color(red: 0.7, green: 0.2, blue: 0.9)      // 紫色 T
    static let blockS = Color(red: 0.2, green: 0.9, blue: 0.2)      // 绿色 S
    static let blockZ = Color(red: 1.0, green: 0.2, blue: 0.2)      // 红色 Z
    static let blockJ = Color(red: 0.0, green: 0.3, blue: 1.0)      // 蓝色 J
    static let blockL = Color(red: 1.0, green: 0.5, blue: 0.0)      // 橙色 L
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        BlockButton(label: "游戏设置", systemImage: "gearshape", color: .blockT, action: {})
        BlockButton(label: "排行榜", systemImage: "trophy", color: .blockO, action: {})
        BlockButton(label: "音频", systemImage: "speaker.wave.2", color: .blockI, action: {})
        BlockButton(label: "主题", systemImage: "paintbrush", color: .blockS, action: {})
        DestructiveBlockButton(label: "删除", systemImage: "trash", action: {})
    }
    .padding()
    .frame(width: 200)
}
