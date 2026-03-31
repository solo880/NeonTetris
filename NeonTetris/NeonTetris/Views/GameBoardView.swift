// ============================================================
// GameBoardView.swift — 游戏棋盘视图
// 负责：棋盘渲染、方块渲染、粒子渲染、输入处理
// ============================================================

import SwiftUI
import AppKit

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
                
                // 绘制粒子（三层离子结构：核心 1/4 → 壳层 1/4 → 外层 2/4）
                for particle in particles.particles {
                    let progress = particle.lifeProgress
                    let size = particle.size * CGFloat(progress)
                    
                    // ========== 第一层：外层（最大，最虚） ==========
                    // 半径：2/4（整个离子圆的一半），透明度：20%
                    let outerSize = size * 2.0  // 2/4 = 0.5，但这里是直径，所以 size * 2.0
                    let outerRect = CGRect(x: particle.position.x - outerSize / 2,
                                          y: particle.position.y - outerSize / 2,
                                          width: outerSize,
                                          height: outerSize)
                    context.fill(
                        Path(ellipseIn: outerRect),
                        with: .color(particle.outerColor.opacity(Double(progress) * 0.20))
                    )
                    
                    // ========== 第二层：壳层（中等，半透） ==========
                    // 半径：1/4（整个离子圆的 1/4），透明度：50%
                    let shellSize = size * 1.0  // 1/4 + 1/4 = 1/2，但壳层是 1/4，所以相对于核心是 1.0
                    let shellRect = CGRect(x: particle.position.x - shellSize / 2,
                                          y: particle.position.y - shellSize / 2,
                                          width: shellSize,
                                          height: shellSize)
                    context.fill(
                        Path(ellipseIn: shellRect),
                        with: .color(particle.shellColor.opacity(Double(progress) * 0.50))
                    )
                    
                    // ========== 第三层：核心（最小，最亮） ==========
                    // 半径：1/4（整个离子圆的 1/4），透明度：80%
                    let coreSize = size * 0.5  // 1/4 相对于整个离子圆，所以是 size * 0.5
                    let coreRect = CGRect(x: particle.position.x - coreSize / 2,
                                         y: particle.position.y - coreSize / 2,
                                         width: coreSize,
                                         height: coreSize)
                    context.fill(
                        Path(ellipseIn: coreRect),
                        with: .color(particle.color.opacity(Double(progress) * 0.80))
                    )
                }
            }
            .frame(width: GameConst.boardW, height: GameConst.boardH)
            .border(theme.config.accentColor, width: 2)
            .overlay(
                KeyboardEventHandler { key in
                    handleKeyPress(key)
                }
                .frame(width: 0, height: 0)
            )
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

// MARK: - 键盘事件处理
struct KeyboardEventHandler: NSViewRepresentable {
    var onKeyDown: (String) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyboardView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyboardView: NSView {
    var onKeyDown: ((String) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        let characters = event.characters ?? ""
        for char in characters {
            onKeyDown?(String(char))
        }
    }
}

#Preview {
    GameBoardView(engine: GameEngine(), theme: AppTheme(), particles: ParticleSystem())
}
