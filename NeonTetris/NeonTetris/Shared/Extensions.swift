// ============================================================
// Extensions.swift — Swift/SwiftUI 扩展工具
// 负责：Color 工具、CGFloat 工具、数组扩展
// ============================================================

import SwiftUI

// MARK: - Color 扩展
extension Color {
    /// 从十六进制字符串创建颜色（如 "FF375F"）
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    /// 转换为十六进制字符串
    var hexString: String {
        let components = NSColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "%02X%02X%02X", r, g, b)
    }

    /// 亮化颜色
    func lightened(by amount: CGFloat = 0.2) -> Color {
        let nsColor = NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h),
                     saturation: Double(s),
                     brightness: Double(min(b + amount, 1.0)),
                     opacity: Double(a))
    }

    /// 暗化颜色
    func darkened(by amount: CGFloat = 0.2) -> Color {
        let nsColor = NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h),
                     saturation: Double(s),
                     brightness: Double(max(b - amount, 0.0)),
                     opacity: Double(a))
    }

    /// 转换为 SIMD4<Float>（供 Metal 使用）
    var simd4: SIMD4<Float> {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.white
        return SIMD4<Float>(
            Float(nsColor.redComponent),
            Float(nsColor.greenComponent),
            Float(nsColor.blueComponent),
            Float(nsColor.alphaComponent)
        )
    }
}

// MARK: - CGFloat 扩展
extension CGFloat {
    /// 线性插值
    func lerp(to target: CGFloat, t: CGFloat) -> CGFloat {
        self + (target - self) * t
    }
}

// MARK: - Double 扩展
extension Double {
    /// 映射到指定范围
    func mapped(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
        let normalized = (self - from.lowerBound) / (from.upperBound - from.lowerBound)
        return to.lowerBound + normalized * (to.upperBound - to.lowerBound)
    }
}

// MARK: - Array 扩展
extension Array {
    /// 安全下标访问
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
