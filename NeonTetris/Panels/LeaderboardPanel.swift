// ============================================================
// LeaderboardPanel.swift — 排行榜面板
// 负责：显示前十名、显示庆祝动画，支持中英文
// ============================================================

import SwiftUI

struct LeaderboardPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var leaderboard: LeaderboardManager
    @ObservedObject var theme: AppTheme
    @ObservedObject var localization = LocalizationManager.shared
    
    @State private var showFireworks = false
    @State private var showFirecrackers = false
    
    var body: some View {
        ZStack {
            theme.config.backgroundColor
            
            Canvas { context, size in
                // 粒子效果在下面渲染
            }
            
            VStack(spacing: 20) {
                // 标题
                Text(localization.t("排行榜", "Leaderboard"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.config.accentColor)
                    .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                
                // 排行榜列表
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(leaderboard.entries.enumerated()), id: \.offset) { index, entry in
                            HStack {
                                // 排名
                                Text("\(index + 1)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(rankColor(index: index))
                                    .frame(width: 40)
                                
                                // 名字
                                Text(entry.playerName)
                                    .font(.title3)
                                    .foregroundColor(theme.config.textColor)
                                
                                Spacer()
                                
                                // 分数
                                Text("\(entry.score)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.config.accentColor)
                                
                                // 等级
                                Text("Lv.\(entry.level)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.config.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(theme.config.panelColor.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.config.gridLineColor, lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
                
                // 关闭按钮
                BlockButton(
                    label: localization.t("关闭", "Close"),
                    color: .blockJ,
                    action: { dismiss() }
                )
                .frame(width: 120, height: 44)
            }
            .padding()
        }
    }
    
    private func rankColor(index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return theme.config.accentColor
        }
    }
}

// MARK: - 庆祝动画面板
struct CelebrationPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme: AppTheme
    var isTopThree: Bool
    
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            theme.config.backgroundColor.opacity(0.95)
            
            Canvas { context, size in
                for particle in particles {
                    let progress = particle.lifeProgress
                    let pSize = particle.size * CGFloat(progress)
                    let rect = CGRect(
                        x: particle.position.x - pSize / 2,
                        y: particle.position.y - pSize / 2,
                        width: pSize,
                        height: pSize
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(Double(progress)))
                    )
                }
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // 庆祝文字
                Text(isTopThree ? "🎉 恭喜上榜！🎉" : "👏 进入排行榜！👏")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("继续") {
                    stopAnimation()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 150, height: 50)
                .background(theme.config.accentColor)
                .cornerRadius(15)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
            spawnParticles()
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateParticles() {
        let perlin = PerlinNoise()
        for i in particles.indices {
            particles[i].update(deltaTime: 0.016, perlin: perlin)
        }
        particles.removeAll { !$0.isAlive }
    }
    
    private func spawnParticles() {
        let screenW = NSScreen.main?.frame.width ?? 800
        let screenH = NSScreen.main?.frame.height ?? 600
        
        if isTopThree {
            // 烟花效果
            if Int.random(in: 0...10) == 0 {
                let x = CGFloat.random(in: 100...screenW - 100)
                let y = CGFloat.random(in: 100...screenH / 2)
                let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
                for _ in 0..<30 {
                    let angle = CGFloat.random(in: 0...2 * .pi)
                    let speed = CGFloat.random(in: 100...300)
                    let color = colors.randomElement()!
                    let randomSize = CGFloat.random(in: 8...20)
                    let randomLife = Float.random(in: 2.8...3.2)
                    particles.append(Particle(
                        position: CGPoint(x: x, y: y),
                        velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - 150),
                        acceleration: CGVector(dx: 0, dy: 0),
                        color: color,
                        shellColor: .randomVariant(of: color),
                        outerColor: .randomVariant(of: color),
                        size: randomSize,
                        life: randomLife,
                        maxLife: randomLife,
                        type: .firework,
                        mass: ParticleType.firework.mass,
                        friction: ParticleType.firework.friction,
                        noiseOffset: Float.random(in: 0...100),
                        turbulence: ParticleType.firework.turbulence,
                        delay: 0
                    ))
                }
            }
        } else {
            // 鞭炮效果
            if Int.random(in: 0...5) == 0 {
                let x = CGFloat.random(in: 100...screenW - 100)
                let y = CGFloat.random(in: 100...screenH - 100)
                let colors: [Color] = [.orange, .red, .yellow]
                for _ in 0..<10 {
                    let angle = CGFloat.random(in: 0...2 * .pi)
                    let speed = CGFloat.random(in: 80...150)
                    let color = colors.randomElement()!
                    let randomSize = CGFloat.random(in: 6...12)
                    let randomLife = Float.random(in: 1.2...1.8)
                    particles.append(Particle(
                        position: CGPoint(x: x, y: y),
                        velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                        acceleration: CGVector(dx: 0, dy: 0),
                        color: color,
                        shellColor: .randomVariant(of: color),
                        outerColor: .randomVariant(of: color),
                        size: randomSize,
                        life: randomLife,
                        maxLife: randomLife,
                        type: .firecracker,
                        mass: ParticleType.firecracker.mass,
                        friction: ParticleType.firecracker.friction,
                        noiseOffset: Float.random(in: 0...100),
                        turbulence: ParticleType.firecracker.turbulence,
                        delay: 0
                    ))
                }
            }
        }
    }
}

#Preview {
    LeaderboardPanel(leaderboard: LeaderboardManager.shared, theme: AppTheme())
}
