// ============================================================
// LeaderboardPanel.swift — 排行榜面板
// 负责：显示排行榜、烟花/鞭炮效果
// ============================================================

import SwiftUI

struct LeaderboardPanel: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var leaderboard: LeaderboardManager
    @ObservedObject var theme: AppTheme
    
    @State private var showFireworks = false
    @State private var showFirecrackers = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("排行榜")
                    .font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
            }
            
            List {
                ForEach(Array(leaderboard.entries.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.headline)
                            .foregroundColor(rankColor(index))
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.playerName)
                                .font(.body)
                            Text("等级 \(entry.level) | \(entry.lines) 行 | \(entry.dateString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(entry.score)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(theme.config.accentColor)
                        
                        // 前三名显示烟花按钮
                        if index < 3 {
                            Button(action: { showFireworks = true }) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                        // 4-10名显示鞭炮按钮
                        else if index < 10 {
                            Button(action: { showFirecrackers = true }) {
                                Image(systemName: "burst")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            HStack {
                Button(role: .destructive, action: { leaderboard.clear() }) {
                    Text("清空排行榜")
                }
                Spacer()
            }
            .padding()
        }
        .padding()
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showFireworks) {
            FireworksView(theme: theme)
        }
        .sheet(isPresented: $showFirecrackers) {
            FirecrackersView(theme: theme)
        }
    }
    
    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow  // 金
        case 1: return Color(hex: "C0C0C0")  // 银
        case 2: return Color(hex: "CD7F32")  // 铜
        default: return .gray
        }
    }
}

// MARK: - 烟花效果视图
struct FireworksView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme: AppTheme
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            theme.config.backgroundColor
            
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(x: CGFloat(particle.x) - CGFloat(particle.size) / 2,
                                     y: CGFloat(particle.y) - CGFloat(particle.size) / 2,
                                     width: CGFloat(particle.size),
                                     height: CGFloat(particle.size))
                    let color = Color(red: Double(particle.r), green: Double(particle.g), blue: Double(particle.b))
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(Double(particle.alpha))))
                }
            }
            
            VStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .padding()
            }
        }
        .onAppear { startFireworks() }
        .onDisappear { stopFireworks() }
    }
    
    private func startFireworks() {
        let colors: [Color] = [
            Color(hex: "FF375F"), Color(hex: "30D158"), Color(hex: "FF9F0A"),
            Color(hex: "BF5AF2"), Color(hex: "FFD700"), Color(hex: "00F5FF")
        ]
        
        for _ in 0..<5 {
            let cx = Float.random(in: 100...700)
            let cy = Float.random(in: 50...300)
            let color = (colors.randomElement() ?? .white).simd4
            for _ in 0..<30 {
                particles.append(ParticleFactory.firework(x: cx, y: cy, color: color))
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in particles.indices {
                particles[i].update()
            }
            particles.removeAll { !$0.isAlive }
        }
    }
    
    private func stopFireworks() {
        timer?.invalidate()
    }
}

// MARK: - 鞭炮效果视图
struct FirecrackersView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme: AppTheme
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            theme.config.backgroundColor
            
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(x: CGFloat(particle.x) - CGFloat(particle.size) / 2,
                                     y: CGFloat(particle.y) - CGFloat(particle.size) / 2,
                                     width: CGFloat(particle.size),
                                     height: CGFloat(particle.size))
                    let color = Color(red: Double(particle.r), green: Double(particle.g), blue: Double(particle.b))
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(Double(particle.alpha))))
                }
            }
            
            VStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .padding()
            }
        }
        .onAppear { startFirecrackers() }
        .onDisappear { stopFirecrackers() }
    }
    
    private func startFirecrackers() {
        let positions: [(Float, Float)] = (0..<8).map { i in
            let t = Float(i) / 8.0
            return (Float(100 + Int(t * 600)), Float.random(in: 100...300))
        }
        for (cx, cy) in positions {
            for _ in 0..<15 {
                particles.append(ParticleFactory.firecracker(x: cx, y: cy))
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in particles.indices {
                particles[i].update()
            }
            particles.removeAll { !$0.isAlive }
        }
    }
    
    private func stopFirecrackers() {
        timer?.invalidate()
    }
}

#Preview {
    LeaderboardPanel(leaderboard: LeaderboardManager.shared, theme: AppTheme())
}
