// ============================================================
// GameBoardView.swift — 游戏棋盘视图
// 负责：棋盘渲染、方块渲染、粒子渲染、输入处理
// ============================================================

import SwiftUI

struct GameBoardView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    @ObservedObject var particles: ParticleSystem
    
    @State private var displayTimer: Timer?
    
    var body: some View {
        ZStack {
            // 棋盘背景
            theme.config.boardColor
            
            Canvas { context, size in
                let blockSize = GameConst.blockSize
                
                // 绘制网格线
                for row in 0...GameConst.rows {
                    let y = CGFloat(row) * blockSize
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: GameConst.boardW, y: y))
                    context.stroke(path, with: .color(theme.config.gridLineColor.opacity(0.3)), lineWidth: 0.5)
                }
                for col in 0...GameConst.cols {
                    let x = CGFloat(col) * blockSize
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: GameConst.boardH))
                    context.stroke(path, with: .color(theme.config.gridLineColor.opacity(0.3)), lineWidth: 0.5)
                }
                
                // 绘制已锁定的方块
                for row in 0..<GameConst.rows {
                    for col in 0..<GameConst.cols {
                        let value = engine.board[row][col]
                        if value > 0, let type = PieceType(rawValue: value) {
                            drawBlock(at: (col, row), type: type, in: context, blockSize: blockSize, theme: theme)
                        }
                    }
                }
                
                // 绘制幽灵方块（预览）
                if let ghost = engine.ghostPiece {
                    for block in ghost.blocks {
                        if block.y >= 0 {
                            drawGhostBlock(at: (block.x, block.y), in: context, blockSize: blockSize, theme: theme)
                        }
                    }
                }
                
                // 绘制当前方块
                if let piece = engine.currentPiece {
                    for block in piece.blocks {
                        if block.y >= 0 {
                            drawBlock(at: (block.x, block.y), type: piece.type, in: context, blockSize: blockSize, theme: theme)
                        }
                    }
                }
                
                // 绘制消行动画
                if !engine.clearingRows.isEmpty {
                    let progress = engine.clearProgress
                    for row in engine.clearingRows {
                        let y = CGFloat(row) * blockSize
                        let rect = CGRect(x: 0, y: y, width: GameConst.boardW, height: blockSize)
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: 0),
                            with: .color(.yellow.opacity(0.5 * (1.0 - progress)))
                        )
                    }
                }
                
                // 绘制粒子
                for particle in particles.particles {
                    let rect = CGRect(x: CGFloat(particle.x) - CGFloat(particle.size) / 2,
                                     y: CGFloat(particle.y) - CGFloat(particle.size) / 2,
                                     width: CGFloat(particle.size),
                                     height: CGFloat(particle.size))
                    let color = Color(red: Double(particle.r), green: Double(particle.g), blue: Double(particle.b))
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(Double(particle.alpha)))
                    )
                }
            }
            .frame(width: GameConst.boardW, height: GameConst.boardH)
            .border(theme.config.accentColor, width: 2)
        }
        .onAppear { startDisplayLoop() }
        .onDisappear { stopDisplayLoop() }
    }
    
    private func startDisplayLoop() {
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            particles.update()
        }
    }
    
    private func stopDisplayLoop() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "a", "A": engine.moveLeft()
        case "d", "D": engine.moveRight()
        case "w", "W": engine.rotate()
        case "s", "S": engine.softDrop()
        case " ": engine.hardDrop()
        case "c", "C": engine.holdPiece()
        case "p", "P": engine.togglePause()
        default: break
        }
    }
    
    private func drawBlock(at pos: (Int, Int), type: PieceType, in context: GraphicsContext, blockSize: CGFloat, theme: AppTheme) {
        let x = CGFloat(pos.0) * blockSize
        let y = CGFloat(pos.1) * blockSize
        let rect = CGRect(x: x + 1, y: y + 1, width: blockSize - 2, height: blockSize - 2)
        
        let color = theme.config.pieceColor(for: type)
        
        // 方块主体
        context.fill(
            Path(roundedRect: rect, cornerRadius: 4),
            with: .color(color)
        )
        
        // 辉光边框
        context.stroke(
            Path(roundedRect: rect, cornerRadius: 4),
            with: .color(color.lightened(by: 0.3)),
            lineWidth: 1.5
        )
        
        // 内部高光
        let highlight = CGRect(x: x + 3, y: y + 3, width: blockSize - 8, height: blockSize / 3)
        context.fill(
            Path(roundedRect: highlight, cornerRadius: 2),
            with: .color(.white.opacity(0.3))
        )
    }
    
    private func drawGhostBlock(at pos: (Int, Int), in context: GraphicsContext, blockSize: CGFloat, theme: AppTheme) {
        let x = CGFloat(pos.0) * blockSize
        let y = CGFloat(pos.1) * blockSize
        let rect = CGRect(x: x + 1, y: y + 1, width: blockSize - 2, height: blockSize - 2)
        
        context.stroke(
            Path(roundedRect: rect, cornerRadius: 4),
            with: .color(theme.config.accentColor.opacity(0.5)),
            lineWidth: 1
        )
    }
}

#Preview {
    GameBoardView(engine: GameEngine(), theme: AppTheme(), particles: ParticleSystem())
}
