// ============================================================
// ThemeConfig.swift — 主题配置数据结构
// 负责：主题颜色/粒子配色方案定义
// ============================================================

import SwiftUI

// MARK: - 粒子配色方案
enum ParticleColorScheme: String, CaseIterable, Codable {
    case rainbow    = "彩虹"       // 七彩随机
    case neon       = "霓虹"       // 霓虹色系
    case fire       = "火焰"       // 红橙黄
    case ice        = "冰晶"       // 蓝白青
    case gold       = "黄金"       // 金黄色系
    case custom     = "自定义"     // 用户自定义

    /// 该方案的代表色列表
    var colors: [Color] {
        switch self {
        case .rainbow: return [.red, .orange, .yellow, .green, Color(hex:"00F5FF"), .blue, .purple]
        case .neon:    return [Color(hex:"FF2D55"), Color(hex:"FF9F0A"), Color(hex:"FFE600"),
                               Color(hex:"00FF7F"), Color(hex:"00F5FF"), Color(hex:"0A84FF"), Color(hex:"BF00FF")]
        case .fire:    return [Color(hex:"FF2D55"), Color(hex:"FF6B00"), Color(hex:"FF9F0A"),
                               Color(hex:"FFE600"), Color(hex:"FFFFFF")]
        case .ice:     return [Color(hex:"00F5FF"), Color(hex:"0A84FF"), Color(hex:"BF5AF2"),
                               Color(hex:"FFFFFF"), Color(hex:"E0F7FF")]
        case .gold:    return [Color(hex:"FFD700"), Color(hex:"FFA500"), Color(hex:"FFE600"),
                               Color(hex:"FFFACD"), Color(hex:"FF8C00")]
        case .custom:  return [.white]  // 由用户自定义
        }
    }
}

// MARK: - 主题配置
struct ThemeConfig: Codable, Equatable {
    // 基础颜色
    var backgroundColorHex: String
    var boardColorHex: String
    var gridLineColorHex: String
    var accentColorHex: String
    var textColorHex: String
    var panelColorHex: String

    // 各方块颜色（key: PieceType.rawValue）
    var pieceColorHexMap: [Int: String]

    // 粒子配色方案
    var particleScheme: ParticleColorScheme

    // MARK: - 便捷颜色访问
    var backgroundColor: Color { Color(hex: backgroundColorHex) }
    var boardColor: Color       { Color(hex: boardColorHex) }
    var gridLineColor: Color    { Color(hex: gridLineColorHex) }
    var accentColor: Color      { Color(hex: accentColorHex) }
    var textColor: Color        { Color(hex: textColorHex) }
    var panelColor: Color       { Color(hex: panelColorHex) }

    func pieceColor(for type: PieceType) -> Color {
        if let hex = pieceColorHexMap[type.rawValue] { return Color(hex: hex) }
        return type.defaultColor
    }

    // MARK: - 预设主题：暗色
    static let dark = ThemeConfig(
        backgroundColorHex: "0A0A1A",
        boardColorHex:      "0D0D2B",
        gridLineColorHex:   "1A1A3A",
        accentColorHex:     "00F5FF",
        textColorHex:       "E0E0FF",
        panelColorHex:      "12122A",
        pieceColorHexMap:   [:],
        particleScheme:     .neon
    )

    // MARK: - 预设主题：亮色
    static let light = ThemeConfig(
        backgroundColorHex: "F0F4FF",
        boardColorHex:      "FFFFFF",
        gridLineColorHex:   "D0D8F0",
        accentColorHex:     "0A84FF",
        textColorHex:       "1A1A2E",
        panelColorHex:      "E8EEFF",
        pieceColorHexMap:   [
            PieceType.I.rawValue: "00B4CC",
            PieceType.O.rawValue: "E6C800",
            PieceType.T.rawValue: "9900CC",
            PieceType.S.rawValue: "00CC66",
            PieceType.Z.rawValue: "CC2244",
            PieceType.J.rawValue: "0066CC",
            PieceType.L.rawValue: "CC7700"
        ],
        particleScheme:     .rainbow
    )
}

// MARK: - 主题模式
enum ThemeMode: String, CaseIterable, Codable {
    case dark   = "暗色"
    case light  = "亮色"
    case custom = "自定义"
}
