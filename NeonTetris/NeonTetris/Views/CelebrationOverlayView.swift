// ============================================================
// CelebrationOverlayView.swift — 全屏庆祝粒子层
// 负责：烟花/鞭炮效果，始终在最顶层渲染
// ============================================================

import SwiftUI
import AppKit

// MARK: - 庆祝粒子类型
enum CelebrationParticleType {
    case firecracker      // 鞭炮爆炸粒子
    case firecrackerDebris // 鞭炮碎片（飞溅后掉落）
    case fireworkTrail    // 烟花尾迹
    case fireworkSpark    // 烟花爆炸火花
}

// MARK: - 庆祝粒子系统（独立于游戏粒子）
@MainActor
class CelebrationSystem: ObservableObject {
    @Published var particles: [CelebrationParticle] = []
    @Published var playerName: String = ""
    @Published var playerRank: Int = 0
    @Published var isActive: Bool = false
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
        var type: CelebrationParticleType
        var alpha: CGFloat { CGFloat(life / maxLife) }
    }
    
    func start(name: String, rank: Int) {
        playerName = name
        playerRank = rank
        isActive = true
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
        isActive = false
    }
    
    private func update() {
        let dt: Float = 0.016
        for i in particles.indices {
            particles[i].life -= dt
            
            // 不同类型粒子有不同的物理特性
            switch particles[i].type {
            case .firecracker, .firecrackerDebris:
                // 碎片受重力影响更大，有空气阻力
                particles[i].vy += 150 * CGFloat(dt)   // 较强重力
                particles[i].vx *= 0.98                // 空气阻力
                particles[i].vy *= 0.98
            case .fireworkTrail:
                // 烟花尾迹有轻微重力，快速减速
                particles[i].vy += 30 * CGFloat(dt)
                particles[i].vx *= 0.95
                particles[i].vy *= 0.95
            case .fireworkSpark:
                // 火花受重力，有闪烁效果（通过生命周期控制）
                particles[i].vy += 80 * CGFloat(dt)
                particles[i].vx *= 0.97
                particles[i].vy *= 0.97
            }
            
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
    @State private var blinkCount: Int = 0
    @State private var isTextVisible: Bool = true
    @State private var blinkTimer: Timer?
    
    // 彩虹色数组
    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    var body: some View {
        ZStack {
            // 全屏透明背景（确保覆盖整个界面）
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 粒子画布
            Canvas { context, size in
                for p in system.particles {
                    let rect = CGRect(
                        x: p.x - p.size / 2,
                        y: p.y - p.size / 2,
                        width: p.size,
                        height: p.size
                    )
                    
                    // 根据粒子类型绘制不同效果
                    switch p.type {
                    case .firecracker, .firecrackerDebris:
                        // 鞭炮粒子：带光晕
                        context.fill(
                            Path(ellipseIn: rect.insetBy(dx: -p.size * 0.3, dy: -p.size * 0.3)),
                            with: .color(p.color.opacity(Double(p.alpha) * 0.3))
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(p.color.opacity(Double(p.alpha) * 0.95))
                        )
                    case .fireworkTrail:
                        // 尾迹：细长
                        let trailRect = CGRect(
                            x: p.x - p.size / 4,
                            y: p.y - p.size,
                            width: p.size / 2,
                            height: p.size * 2
                        )
                        context.fill(
                            Path(ellipseIn: trailRect),
                            with: .color(p.color.opacity(Double(p.alpha) * 0.6))
                        )
                    case .fireworkSpark:
                        // 火花：带强烈光晕
                        context.fill(
                            Path(ellipseIn: rect.insetBy(dx: -p.size * 0.8, dy: -p.size * 0.8)),
                            with: .color(p.color.opacity(Double(p.alpha) * 0.2))
                        )
                        context.fill(
                            Path(ellipseIn: rect.insetBy(dx: -p.size * 0.4, dy: -p.size * 0.4)),
                            with: .color(p.color.opacity(Double(p.alpha) * 0.5))
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(.white.opacity(Double(p.alpha) * 0.9))
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            
            // 彩虹闪烁文字
            if isTextVisible && blinkCount < 6 && system.isActive {
                VStack(spacing: 20) {
                    Text(celebrationText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(rainbowColors[blinkCount % rainbowColors.count])
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.15), value: blinkCount)
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .onChange(of: system.isActive) { active in
            if active {
                startBlinking()
            } else {
                stopBlinking()
            }
        }
    }
    
    private var celebrationText: String {
        let name = system.playerName.isEmpty ? "玩家" : system.playerName
        let rankText: String
        switch system.playerRank {
        case 1: rankText = "🥇 第一名"
        case 2: rankText = "🥈 第二名"
        case 3: rankText = "🥉 第三名"
        default: rankText = "第\(system.playerRank)名"
        }
        return "🎉 恭喜 \(name)，获得 \(rankText) 的成绩！🎉"
    }
    
    private func startBlinking() {
        var count = 0
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [self] _ in
            count += 1
            self.blinkCount = count
            if count >= 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isTextVisible = false
                }
                self.blinkTimer?.invalidate()
                self.blinkTimer = nil
            }
        }
    }
    
    private func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
    }
}

// MARK: - 庆祝效果触发器
struct CelebrationTrigger {
    
    @MainActor
    static func trigger(rank: Int, system: CelebrationSystem, playerName: String, soundEngine: SoundEngine?) {
        // 设置玩家信息
        system.start(name: playerName, rank: rank)
        
        // 使用主屏幕尺寸（确保全屏覆盖）
        guard let mainScreen = NSScreen.main else { return }
        let W = Float(mainScreen.frame.width)
        let H = Float(mainScreen.frame.height)
        
        // 启动鞭炮效果（门神对联位置：左上和右上，先显示后爆炸）
        startFirecrackerCouplets(system: system, W: W, H: H, soundEngine: soundEngine)
        
        if rank <= 3 {
            // 前三名：从0秒开始发射烟花（共6个，间隔1秒）
            for i in 0..<6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                    launchFirework(system: system, W: W, H: H, soundEngine: soundEngine)
                }
            }
        }
        
        // 停止时间
        let stopDelay = rank <= 3 ? 8.0 : 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + stopDelay) {
            system.stop()
        }
    }
    
    // MARK: - 门神对联式鞭炮（悬挂→爆炸）
    @MainActor
    private static func startFirecrackerCouplets(system: CelebrationSystem, W: Float, H: Float, soundEngine: SoundEngine?) {
        // 鞭炮串位置：模拟对联/门神
        // 左上位置 (like left couplet)
        let leftTopX = W * 0.08
        let leftTopY = H * 0.75
        let leftStringHeight: Float = H * 0.55  // 较长
        
        // 右上位置 (like right couplet)
        let rightTopX = W * 0.92
        let rightTopY = H * 0.75
        let rightStringHeight: Float = H * 0.55
        
        // 中间顶部横批位置
        let centerX = W * 0.5
        let centerTopY = H * 0.85
        let centerStringWidth: Float = W * 0.3
        
        // 鞭炮参数
        let firecrackerCount = 30
        let explosionInterval: Double = 0.1  // 爆炸间隔
        
        // 第一步：先显示悬挂的鞭炮串（静态粒子）
        showHangingFirecrackers(system: system, W: W, H: H, leftX: leftTopX, leftY: leftTopY, leftHeight: leftStringHeight, rightX: rightTopX, rightY: rightTopY, rightHeight: rightStringHeight, centerX: centerX, centerY: centerTopY, centerWidth: centerStringWidth, count: firecrackerCount)
        
        // 第二步：0.8秒后开始从下往上依次爆炸
        let startDelay: Double = 0.8
        
        // 左串鞭炮（从下往上炸）
        for i in 0..<firecrackerCount {
            let delay = startDelay + Double(i) * explosionInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Float(i) / Float(firecrackerCount - 1)
                let y = leftTopY - leftStringHeight * progress
                let offset = Float.random(in: -8...8)
                explodeFirecracker(system: system, x: CGFloat(leftTopX + offset), y: CGFloat(y))
                soundEngine?.playSingleFirecracker()
            }
        }
        
        // 右串鞭炮（从下往上炸，稍微错开）
        for i in 0..<firecrackerCount {
            let delay = startDelay + Double(i) * explosionInterval + 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Float(i) / Float(firecrackerCount - 1)
                let y = rightTopY - rightStringHeight * progress
                let offset = Float.random(in: -8...8)
                explodeFirecracker(system: system, x: CGFloat(rightTopX + offset), y: CGFloat(y))
            }
        }
        
        // 中间横批鞭炮（从中间往两边炸）
        for i in 0..<(firecrackerCount / 2) {
            // 从中间往左
            let delayLeft = startDelay + Double(i) * explosionInterval * 1.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delayLeft) {
                let progress = Float(i) / Float(firecrackerCount / 2 - 1)
                let x = Float(centerX) - centerStringWidth * progress
                explodeFirecracker(system: system, x: CGFloat(x), y: CGFloat(centerTopY))
            }
            // 从中间往右
            let delayRight = startDelay + Double(i) * explosionInterval * 1.5 + 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + delayRight) {
                let progress = Float(i) / Float(firecrackerCount / 2 - 1)
                let x = Float(centerX) + centerStringWidth * progress
                explodeFirecracker(system: system, x: CGFloat(x), y: CGFloat(centerTopY))
            }
        }
    }
    
    // MARK: - 显示悬挂的鞭炮串（静态视觉）
    @MainActor
    private static func showHangingFirecrackers(system: CelebrationSystem, W: Float, H: Float, leftX: Float, leftY: Float, leftHeight: Float, rightX: Float, rightY: Float, rightHeight: Float, centerX: Float, centerY: Float, centerWidth: Float, count: Int) {
        var batch: [CelebrationSystem.CelebrationParticle] = []
        
        // 鞭炮未爆炸的颜色（暗红色/暗金色）
        let hangingColor = Color(red: 0.6, green: 0.15, blue: 0.1)
        
        // 左串
        for i in 0..<count {
            let progress = Float(i) / Float(count - 1)
            let yPos = leftY - leftHeight * progress
            let offsetX = Float.random(in: -3...3)
            let xPos = leftX + offsetX
            
            batch.append(.init(
                x: CGFloat(xPos),
                y: CGFloat(yPos),
                vx: 0,
                vy: 0,
                life: 0.8,
                maxLife: 0.8,
                size: CGFloat.random(in: 6...10),
                color: hangingColor,
                type: .firecracker
            ))
        }
        
        // 右串
        for i in 0..<count {
            let progress = Float(i) / Float(count - 1)
            let yPos = rightY - rightHeight * progress
            let offsetX = Float.random(in: -3...3)
            let xPos = rightX + offsetX
            
            batch.append(.init(
                x: CGFloat(xPos),
                y: CGFloat(yPos),
                vx: 0,
                vy: 0,
                life: 0.8,
                maxLife: 0.8,
                size: CGFloat.random(in: 6...10),
                color: hangingColor,
                type: .firecracker
            ))
        }
        
        // 中间横批（较短）
        let centerCount = count / 2
        for i in 0..<centerCount {
            let progress = Float(i) / Float(centerCount - 1)
            let halfWidth = centerWidth / 2
            let xPos = centerX - halfWidth + centerWidth * progress
            let offsetY = Float.random(in: -2...2)
            
            batch.append(.init(
                x: CGFloat(xPos),
                y: CGFloat(centerY + offsetY),
                vx: 0,
                vy: 0,
                life: 0.8,
                maxLife: 0.8,
                size: CGFloat.random(in: 5...8),
                color: hangingColor,
                type: .firecracker
            ))
        }
        
        system.addParticles(batch)
    }
    
    // MARK: - 单个鞭炮爆炸（产生爆炸粒子和碎片）
    @MainActor
    private static func explodeFirecracker(system: CelebrationSystem, x: CGFloat, y: CGFloat) {
        var batch: [CelebrationSystem.CelebrationParticle] = []
        
        // 爆炸颜色：红色、橙色、金色
        let explosionColors: [Color] = [
            Color(red: 1.0, green: 0.1, blue: 0.1),   // 鲜红
            Color(red: 1.0, green: 0.5, blue: 0.0),   // 橙红
            Color(red: 1.0, green: 0.8, blue: 0.2),   // 金色
            Color(red: 1.0, green: 0.9, blue: 0.5),   // 浅金
        ]
        
        // 碎片颜色：纸屑颜色
        let debrisColors: [Color] = [
            Color(red: 1.0, green: 0.2, blue: 0.2),
            Color(red: 1.0, green: 0.6, blue: 0.1),
            Color(red: 0.9, green: 0.9, blue: 0.2),
            Color(red: 1.0, green: 1.0, blue: 0.8),
        ]
        
        // 爆炸核心粒子（8-12个，快速扩散）
        let coreCount = Int.random(in: 8...12)
        for _ in 0..<coreCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...180)
            
            batch.append(.init(
                x: x + CGFloat.random(in: -5...5),
                y: y + CGFloat.random(in: -5...5),
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                life: Float.random(in: 0.3...0.6),
                maxLife: 0.6,
                size: CGFloat.random(in: 4...8),
                color: explosionColors.randomElement()!,
                type: .firecracker
            ))
        }
        
        // 飞溅碎片（15-20个，飞得更远，受重力掉落）
        let debrisCount = Int.random(in: 15...20)
        for _ in 0..<debrisCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 150...350)
            // 稍微向上偏，模拟爆炸飞溅
            let upwardBias = CGFloat.random(in: -0.3...0.8)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed - upwardBias * speed * 0.5
            
            batch.append(.init(
                x: x,
                y: y,
                vx: vx,
                vy: vy,
                life: Float.random(in: 1.0...2.0),
                maxLife: 2.0,
                size: CGFloat.random(in: 2...5),
                color: debrisColors.randomElement()!,
                type: .firecrackerDebris
            ))
        }
        
        system.addParticles(batch)
    }
    
    // MARK: - 发射烟花（从下方飞到中间上方爆炸）
    @MainActor
    private static func launchFirework(system: CelebrationSystem, W: Float, H: Float, soundEngine: SoundEngine?) {
        // 发射位置：底部中间随机
        let launchX = Float.random(in: W * 0.2...W * 0.8)
        let launchY = H * 0.95
        
        // 目标爆炸位置：中间偏上
        let targetX = Float.random(in: W * 0.2...W * 0.8)
        let targetY = Float.random(in: H * 0.15...H * 0.45)
        
        // 计算发射速度（更快一点）
        let dx = targetX - launchX
        let dy = targetY - launchY
        let distance = sqrt(dx*dx + dy*dy)
        let launchSpeed: Float = 550 // 发射速度
        let vx = (dx / distance) * launchSpeed
        let vy = (dy / distance) * launchSpeed
        
        // 播放升空音效
        soundEngine?.playFireworkLaunch()
        
        // 尾迹颜色
        let trailColor = Color(red: 0.9, green: 0.9, blue: 0.95)
        
        // 计算飞行时间
        let flightTime = Float(distance) / launchSpeed
        
        // 发射尾迹粒子（持续产生）
        let trailInterval: Float = 0.02
        var trailCount = Int(flightTime / trailInterval)
        if trailCount > 20 { trailCount = 20 }
        
        for i in 0..<trailCount {
            let delay = Float(i) * trailInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)) {
                let t = Float(i) * trailInterval
                // 简化的抛物线轨迹
                let px = CGFloat(launchX + vx * t)
                let py = CGFloat(launchY + vy * t + 0.5 * 80 * t * t)
                
                system.addParticles([.init(
                    x: px,
                    y: py,
                    vx: CGFloat.random(in: -8...8),
                    vy: CGFloat.random(in: -8...8),
                    life: Float.random(in: 0.15...0.3),
                    maxLife: 0.3,
                    size: CGFloat.random(in: 2...4),
                    color: trailColor,
                    type: .fireworkTrail
                )])
            }
        }
        
        // 到达目标位置后爆炸
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(flightTime)) {
            explodeFirework(system: system, x: CGFloat(targetX), y: CGFloat(targetY))
            soundEngine?.playFireworkBurst()
        }
    }
    
    // MARK: - 烟花爆炸（圆形炸开，考虑重力）
    @MainActor
    private static func explodeFirework(system: CelebrationSystem, x: CGFloat, y: CGFloat) {
        var batch: [CelebrationSystem.CelebrationParticle] = []
        
        // 随机选择烟花主色调
        let hue = CGFloat.random(in: 0...1)
        let mainColor = Color(hue: hue, saturation: 0.9, brightness: 1.0)
        let secondaryColor = Color(hue: fmod(hue + 0.15, 1.0), saturation: 0.8, brightness: 1.0)
        let accentColor = Color(hue: fmod(hue + 0.3, 1.0), saturation: 0.7, brightness: 1.0)
        let colors = [mainColor, secondaryColor, accentColor, .white]
        
        // 火花数量：60-80个，均匀圆形分布
        let sparkCount = Int.random(in: 60...80)
        
        for i in 0..<sparkCount {
            // 圆形均匀分布
            let angle = CGFloat(i) / CGFloat(sparkCount) * 2 * .pi + CGFloat.random(in: -0.1...0.1)
            // 速度有层次：内圈慢，外圈快
            let speedBase = CGFloat.random(in: 80...200)
            let speedVariation = CGFloat.random(in: 0.8...1.2)
            let speed = speedBase * speedVariation
            
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed
            
            // 随机选择颜色
            let color = colors.randomElement()!
            
            // 大小也有层次
            let size = CGFloat.random(in: 3...7)
            
            batch.append(.init(
                x: x + CGFloat.random(in: -3...3),
                y: y + CGFloat.random(in: -3...3),
                vx: vx,
                vy: vy,
                life: Float.random(in: 1.5...2.5),
                maxLife: 2.5,
                size: size,
                color: color,
                type: .fireworkSpark
            ))
        }
        
        // 添加一些更亮的中心火花
        for _ in 0..<10 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 30...80)
            
            batch.append(.init(
                x: x,
                y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                life: Float.random(in: 0.8...1.2),
                maxLife: 1.2,
                size: CGFloat.random(in: 5...9),
                color: .white,
                type: .fireworkSpark
            ))
        }
        
        system.addParticles(batch)
    }
}

// 辅助函数：浮点数取模
func fmod(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
    return x - y * floor(x / y)
}
