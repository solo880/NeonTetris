// ============================================================
// TetrominoTypes.swift — 方块类型定义
// 负责：7种方块形状、SRS旋转系统、踢墙表、颜色映射
// ============================================================

import SwiftUI

// MARK: - 方块类型枚举
enum PieceType: Int, CaseIterable, Codable {
    case I = 1, O, T, S, Z, J, L

    /// 方块的标准霓虹颜色
    var defaultColor: Color {
        switch self {
        case .I: return Color(hex: "00F5FF")  // 青色
        case .O: return Color(hex: "FFE600")  // 黄色
        case .T: return Color(hex: "BF00FF")  // 紫色
        case .S: return Color(hex: "00FF7F")  // 绿色
        case .Z: return Color(hex: "FF2D55")  // 红色
        case .J: return Color(hex: "0A84FF")  // 蓝色
        case .L: return Color(hex: "FF9F0A")  // 橙色
        }
    }

    /// 方块的辉光颜色（比主色更亮）
    var glowColor: Color { defaultColor.lightened(by: 0.3) }

    /// 方块名称（用于显示）
    var name: String {
        switch self {
        case .I: return "I"; case .O: return "O"; case .T: return "T"
        case .S: return "S"; case .Z: return "Z"; case .J: return "J"
        case .L: return "L"
        }
    }
}

// MARK: - 方块格子坐标
struct Block: Equatable {
    var x: Int
    var y: Int
}

// MARK: - 活动方块（当前下落中的方块）
struct TetrominoPiece: Equatable {
    var type: PieceType     // 方块类型
    var x: Int              // 棋盘列坐标（左上角）
    var y: Int              // 棋盘行坐标（左上角）
    var rotation: Int       // 旋转状态 0-3

    /// 获取当前所有格子的绝对坐标
    var blocks: [Block] {
        TetrominoDefinitions.blocks(type: type, rotation: rotation, x: x, y: y)
    }
}

// MARK: - 方块形状定义（SRS 标准旋转系统）
enum TetrominoDefinitions {
    // 每种方块的4个旋转状态，每个状态4个格子的相对坐标 [col, row]
    private static let shapes: [PieceType: [[(Int, Int)]]] = [
        .I: [
            [(0,1),(1,1),(2,1),(3,1)],  // 0°
            [(2,0),(2,1),(2,2),(2,3)],  // 90°
            [(0,2),(1,2),(2,2),(3,2)],  // 180°
            [(1,0),(1,1),(1,2),(1,3)]   // 270°
        ],
        .O: [
            [(1,0),(2,0),(1,1),(2,1)],
            [(1,0),(2,0),(1,1),(2,1)],
            [(1,0),(2,0),(1,1),(2,1)],
            [(1,0),(2,0),(1,1),(2,1)]
        ],
        .T: [
            [(1,0),(0,1),(1,1),(2,1)],
            [(1,0),(1,1),(2,1),(1,2)],
            [(0,1),(1,1),(2,1),(1,2)],
            [(1,0),(0,1),(1,1),(1,2)]
        ],
        .S: [
            [(1,0),(2,0),(0,1),(1,1)],
            [(1,0),(1,1),(2,1),(2,2)],
            [(1,1),(2,1),(0,2),(1,2)],
            [(0,0),(0,1),(1,1),(1,2)]
        ],
        .Z: [
            [(0,0),(1,0),(1,1),(2,1)],
            [(2,0),(1,1),(2,1),(1,2)],
            [(0,1),(1,1),(1,2),(2,2)],
            [(1,0),(0,1),(1,1),(0,2)]
        ],
        .J: [
            [(0,0),(0,1),(1,1),(2,1)],
            [(1,0),(2,0),(1,1),(1,2)],
            [(0,1),(1,1),(2,1),(2,2)],
            [(1,0),(1,1),(0,2),(1,2)]
        ],
        .L: [
            [(2,0),(0,1),(1,1),(2,1)],
            [(1,0),(1,1),(1,2),(2,2)],
            [(0,1),(1,1),(2,1),(0,2)],
            [(0,0),(1,0),(1,1),(1,2)]
        ]
    ]

    /// 获取指定方块在指定旋转状态下的绝对坐标
    static func blocks(type: PieceType, rotation: Int, x: Int, y: Int) -> [Block] {
        guard let rotations = shapes[type] else { return [] }
        let rot = rotations[rotation % 4]
        return rot.map { Block(x: x + $0.0, y: y + $0.1) }
    }

    // MARK: - SRS 踢墙偏移表（非I方块）
    // 格式：[当前旋转 -> 目标旋转]: [(dx, dy)]
    static let wallKickData: [String: [(Int, Int)]] = [
        "0->1": [(0,0),(-1,0),(-1,1),(0,-2),(-1,-2)],
        "1->0": [(0,0),(1,0),(1,-1),(0,2),(1,2)],
        "1->2": [(0,0),(1,0),(1,-1),(0,2),(1,2)],
        "2->1": [(0,0),(-1,0),(-1,1),(0,-2),(-1,-2)],
        "2->3": [(0,0),(1,0),(1,1),(0,-2),(1,-2)],
        "3->2": [(0,0),(-1,0),(-1,-1),(0,2),(-1,2)],
        "3->0": [(0,0),(-1,0),(-1,-1),(0,2),(-1,2)],
        "0->3": [(0,0),(1,0),(1,1),(0,-2),(1,-2)]
    ]

    // MARK: - SRS I方块踢墙偏移表
    static let wallKickDataI: [String: [(Int, Int)]] = [
        "0->1": [(0,0),(-2,0),(1,0),(-2,-1),(1,2)],
        "1->0": [(0,0),(2,0),(-1,0),(2,1),(-1,-2)],
        "1->2": [(0,0),(-1,0),(2,0),(-1,2),(2,-1)],
        "2->1": [(0,0),(1,0),(-2,0),(1,-2),(-2,1)],
        "2->3": [(0,0),(2,0),(-1,0),(2,1),(-1,-2)],
        "3->2": [(0,0),(-2,0),(1,0),(-2,-1),(1,2)],
        "3->0": [(0,0),(1,0),(-2,0),(1,-2),(-2,1)],
        "0->3": [(0,0),(-1,0),(2,0),(-1,2),(2,-1)]
    ]

    /// 获取踢墙偏移列表
    static func wallKicks(type: PieceType, from: Int, to: Int) -> [(Int, Int)] {
        let key = "\(from % 4)->\(to % 4)"
        if type == .I {
            return wallKickDataI[key] ?? [(0, 0)]
        }
        return wallKickData[key] ?? [(0, 0)]
    }
}
