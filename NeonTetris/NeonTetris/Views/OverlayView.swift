// ============================================================
// OverlayView.swift — 游戏状态覆盖层
// 负责：开始/暂停/结束界面
// ============================================================

import SwiftUI

struct OverlayView: View {
    @ObservedObject var engine: GameEngine
    @ObservedObject var theme: AppTheme
    var onStart: () -> Void
    
    var body: some View {
        ZStack {
            if engine.gameState == .idle {
                startScreen
            } else if engine.gameState == .paused {
                pauseScreen
            } else if engine.gameState == .gameOver {
                gameOverScreen
            }
        }
    }
    
    private var startScreen: some View {
        VStack(spacing: 30) {
            Text("霓虹俄罗斯方块")
                .font(.system(size: 48, weight: .bold, design: .default))
                .foregroundColor(theme.config.accentColor)
            
            VStack(spacing: 10) {
                Text("快捷键")
                    .font(.headline)
                    .foregroundColor(theme.config.textColor)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("← → 移动 | ↑ 旋转 | ↓ 软降")
                    Text("Space 硬降 | C 暂存 | P 暂停")
                }
                .font(.caption)
                .foregroundColor(theme.config.textColor.opacity(0.7))
            }
            
            Button(action: onStart) {
                Text("开始游戏")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.config.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    private var pauseScreen: some View {
        VStack(spacing: 30) {
            Text("暂停")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(theme.config.accentColor)
            
            Button(action: { engine.togglePause() }) {
                Text("继续游戏")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.config.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    private var gameOverScreen: some View {
        VStack(spacing: 30) {
            Text("游戏结束")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.red)
            
            VStack(spacing: 10) {
                HStack {
                    Text("最终分数")
                    Spacer()
                    Text("\(engine.score)")
                        .font(.system(.title, design: .monospaced))
                }
                HStack {
                    Text("达到等级")
                    Spacer()
                    Text("\(engine.level)")
                        .font(.system(.title, design: .monospaced))
                }
                HStack {
                    Text("消除行数")
                    Spacer()
                    Text("\(engine.lines)")
                        .font(.system(.title, design: .monospaced))
                }
            }
            .foregroundColor(theme.config.textColor)
            .padding()
            .background(theme.config.panelColor)
            .cornerRadius(8)
            
            Button(action: onStart) {
                Text("重新开始")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.config.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
}

#Preview {
    OverlayView(engine: GameEngine(), theme: AppTheme(), onStart: {})
}
