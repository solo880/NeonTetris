// ============================================================
// CelebrationOverlayView.swift — 全屏庆祝粒子层
// 负责：烟花/鞭炮效果，始终在最顶层渲染
// ============================================================

import SwiftUI

// MARK: - 庆祝粒子系统（独立于游戏粒子）
@MainActor
class CelebrationSystem: ObservableObject {
    @Published var particles: [CelebrationParticle] = []
    private var displayTimer: Timer?
    
    struct CelebrationParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var life: Float       // 当前剩余寿命
        var maxLife: Float
        var size: CGFloat
        var color: Color
        var alpha: CGFloat { CGFloat(life / maxLife) }
    }
    
    func start() {
        guard displayTimer == nil else { return }
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.update()
            }
        }
    }
    
    func stop() {
        displayTimer?.invalidate()
        displayTimer = nil
        particles.removeAll()
    }
    
    private func update() {
        let dt: Float = 0.016
        for i in particles.indices {
            particles[i].life -= dt
            particles[i].vy += 60 * CGFloat(dt)   // 重力
            particles[i].vx *= 0.99               // 空气阻力
            particles[i].vy *= 0.99
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
        }
        particles.removeAll { $0.life <= 0 }
    }
    
    func addParticles(_ newOnes: [CelebrationParticle]) {
        let cap = 3000
        let available = cap - particles.count
        guard available > 0 else { return }
        particles.append(contentsOf: newOnes.prefix(available))
    }
}

// MARK: - 全屏庆祝覆盖层
struct CelebrationOverlayView: View {
    @ObservedObject var system: CelebrationSystem
    
    var body: some View {
        Canvas { context, size in
            for p in system.particles {
                let rect = CGRect(
                    x: p.x - p.size / 2,
                    y: p.y - p.size / 2,
                    width: p.size,
                    height: p.size
                )
                // 外光晕
                context.fill(
                    Path(ellipseIn: rect.insetBy(dx: -p.size * 0.5, dy: -p.size * 0.5)),
                    with: .color(p.color.opacity(Double(p.alpha) * 0.25))
                )
                // 核心
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(p.color.opacity(Double(p.alpha) * 0.9))
                )
            }
        }
        .allowsHitTesting(false)   // 不拦截点击
        .ignoresSafeArea()
    }
}

// MARK: - 庆祝效果触发器
struct CelebrationTrigger {
    
    @MainActor
    static func trigger(rank: Int, system: CelebrationSystem, screenSize: CGSize) {
        system.start()
        
        let W = Float(screenSize.width)
        let H = Float(screenSize.height)
        
        if rank <= 3 {
            // 前三名：鞭炮 + 3波烟花
            addFirecrackers(system: system, W: W, H: H, count: 80)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                addFireworkWave(system: system, W: W, H: H)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                addFireworkWave(system: system, W: W, H: H)
                addFirecrackers(system: system, W: W, H: H, count: 60)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                addFireworkWave(system: system, W: W, H: H)
            }
            // 5s 后停止
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                system.stop()
            }
        } else {
            // 其他排名：鞭炮从底部向上
            addFirecrackers(system: system, W: W, H: H, count: 60)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                addFirecrackers(system: system, W: W, H: H, count: 40)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                system.stop()
            }
        }
    }
    
    // MARK: - 鞭炮：从屏幕四周向中心喷射
    @MainActor
    private static func addFirecrackers(system: CelebrationSystem, W: Float, H: Float, count: Int) {
        var batch: [CelebrationSystem.CelebrationParticle] = []
        
        let goldColors: [Color] = [
            Color(red: 1.0, green: 0.85, blue: 0.1),
            Color(red: 1.0, green: 0.6,  blue: 0.1),
            Color(red: 1.0, green: 0.4,  blue: 0.1),
            Color(red: 1.0, green: 1.0,  blue: 0.4),
        ]
        
        for _ in 0..<count {
            let side = Int.random(in: 0..<4)
            var x: Float, y: Float
            switch side {
            case 0: x = Float.random(in: 0...W); y = -10
            case 1: x = Float.random(in: 0...W); y = H + 10
            case 2: x = -10;                     y = Float.random(in: 0...H)
            default: x = W + 10;                 y = Float.random(in: 0...H)
            }
            
            let targetX = Float.random(in: W * 0.2...W * 0.8)
            let targetY = Float.random(in: H * 0.2...H * 0.8)
            let dist = max(1, sqrt(pow(targetX - x, 2) + pow(targetY - y, 2)))
            let speed = Float.random(in: 200...450)
            let vx = CGFloat((targetX - x) / dist * speed)
            let vy = CGFloat((targetY - y) / dist * speed)
            
            batch.append(.init(
                x: CGFloat(x), y: CGFloat(y),
                vx: vx, vy: vy,
                life: Float.random(in: 1.5...2.5),
                maxLife: 2.5,
                size: CGFloat.random(in: 6...12),
                color: goldColors.randomElement()!
            ))
        }
        system.addParticles(batch)
    }
    
    // MARK: - 烟花波：随机位置爆炸
    @MainActor
    private static func addFireworkWave(system: CelebrationSystem, W: Float, H: Float) {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.2, blue: 0.2),
            Color(red: 0.3, green: 1.0, blue: 0.3),
            Color(red: 0.3, green: 0.5, blue: 1.0),
            Color(red: 1.0, green: 1.0, blue: 0.2),
            Color(red: 1.0, green: 0.3, blue: 1.0),
            Color(red: 0.2, green: 1.0, blue: 1.0),
            Color(red: 1.0, green: 0.6, blue: 0.1),
        ]
        
        var batch: [CelebrationSystem.CelebrationParticle] = []
        
        // 15 个爆炸点，每点 40 粒子
        for _ in 0..<15 {
            let cx = CGFloat(Float.random(in: W * 0.1...W * 0.9))
            let cy = CGFloat(Float.random(in: H * 0.1...H * 0.8))
            let color = colors.randomElement()!
            let secondColor = colors.randomElement()!
            
            for i in 0..<40 {
                let angle = CGFloat(i) / 40.0 * .pi * 2 + CGFloat.random(in: -0.15...0.15)
                let speed = CGFloat.random(in: 120...320)
                let c = Bool.random() ? color : secondColor
                
                batch.append(.init(
                    x: cx, y: cy,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    life: Float.random(in: 2.0...3.5),
                    maxLife: 3.5,
                    size: CGFloat.random(in: 7...14),
                    color: c
                ))
            }
        }
        system.addParticles(batch)
    }
}
