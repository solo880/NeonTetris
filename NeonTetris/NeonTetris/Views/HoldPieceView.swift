// ============================================================
// HoldPieceView.swift — 暂存方块显示面板
// 负责：显示暂存的方块、暂存状态
// ============================================================

import SwiftUI

struct HoldPieceView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 10) {
            Text("暂存")
                .font(.headline)
                .foregroundColor(theme.config.textColor)
            
            ZStack {
                theme.config.boardColor
                    .cornerRadius(8)
                
                if let held = engine.heldPiece {
                    Canvas { context, size in
                        let blockSize: CGFloat = 20
                        let blocks = TetrominoDefinitions.blocks(type: held, rotation: 0, x: 1, y: 1)
                        for block in blocks {
                            let x = CGFloat(block.x) * blockSize + (size.width - 4 * blockSize) / 2
                            let y = CGFloat(block.y) * blockSize + (size.height - 4 * blockSize) / 2
                            let rect = CGRect(x: x, y: y, width: blockSize - 2, height: blockSize - 2)
                            let color = theme.config.pieceColor(for: held)
                            context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
                        }
                    }
                } else {
                    Text("空")
                        .foregroundColor(theme.config.textColor.opacity(0.5))
                }
            }
            .frame(height: 100)
            
            Text(engine.canHold ? "可暂存" : "已暂存")
                .font(.caption)
                .foregroundColor(engine.canHold ? .green : .gray)
        }
        .padding()
        .background(theme.config.panelColor)
        .cornerRadius(8)
    }
}

#Preview {
    HoldPieceView(engine: GameEngine(), theme: AppTheme())
}
