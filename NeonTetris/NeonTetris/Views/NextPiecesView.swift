// ============================================================
// NextPiecesView.swift — 下一个方块预览面板
// 负责：显示接下来的3个方块
// ============================================================

import SwiftUI

struct NextPiecesView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 10) {
            Text("下一个")
                .font(.headline)
                .foregroundColor(theme.config.textColor)
            
            ForEach(0..<min(3, engine.nextPieces.count), id: \.self) { index in
                ZStack {
                    theme.config.boardColor
                        .cornerRadius(8)
                    
                    Canvas { context, size in
                        let blockSize: CGFloat = 16
                        let type = engine.nextPieces[index]
                        let blocks = TetrominoDefinitions.blocks(type: type, rotation: 0, x: 1, y: 1)
                        for block in blocks {
                            let x = CGFloat(block.x) * blockSize + (size.width - 4 * blockSize) / 2
                            let y = CGFloat(block.y) * blockSize + (size.height - 4 * blockSize) / 2
                            let rect = CGRect(x: x, y: y, width: blockSize - 1, height: blockSize - 1)
                            let color = theme.config.pieceColor(for: type)
                            context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color))
                        }
                    }
                }
                .frame(height: 70)
            }
        }
        .padding()
        .background(theme.config.panelColor)
        .cornerRadius(8)
    }
}

#Preview {
    NextPiecesView(engine: GameEngine(), theme: AppTheme())
}
