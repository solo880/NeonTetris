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
    // 粒子与循环控制
    var maxParticles: Int = 2000           // 全局上限（保护）
    var highWatermark: Int = 1700          // 超过此值时降载
    var lowWatermark: Int = 1200           // 低于此值时恢复
    private var displayTimer: Timer?
    private var loopTimerFireworks: Timer?
    private var loopTimerCrackers: Timer?
    private var reducedLoad: Bool = false  // 当前是否降载模式
    // 每帧新增粒子上限（仅对烟花爆炸火花生效）
    var perFrameSparkCap: Int = 40
    // FPS 目标与时间采样
    var fpsTarget: Int = 60
    private var lastUpdateAt: CFAbsoluteTime?
    
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
        applyTimer()
    }
    
    func startLoops(canvasSize: CGSize, intensity: GameSettings.CelebrationIntensity) {
        stopLoops()
        // 根据游戏设置的庆祝强度自适应参数
        var fireworkInterval: TimeInterval
        var crackerInterval: TimeInterval
        var cap = maxParticles
        switch intensity {
        case .normal:
            fireworkInterval = 1.2
            crackerInterval = 0.45
            cap = 1400
        case .fancy:
            fireworkInterval = 0.9
            crackerInterval = 0.30
            cap = 2000
        case .extreme:
            fireworkInterval = 0.6
            crackerInterval = 0.20
            cap = 2600
        }
        self.maxParticles = cap

        // 连续烟花
        loopTimerFireworks = Timer.scheduledTimer(withTimeInterval: fireworkInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            if self.particles.count > self.highWatermark { return }
            // 根据强度调整“每帧火花上限”（减少一半）
            switch intensity {
            case .normal: self.perFrameSparkCap = 20
            case .fancy:  self.perFrameSparkCap = 40 // 原 80 的一半理念
            case .extreme:self.perFrameSparkCap = 60 // 原更高，也按一半控制
            }
            let W = Float(canvasSize.width)
            let H = Float(canvasSize.height)
            CelebrationTrigger.launchFirework(system: self, W: W, H: H, soundEngine: nil)
        }
        // 连续鞭炮
        loopTimerCrackers = Timer.scheduledTimer(withTimeInterval: crackerInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            if self.particles.count > self.highWatermark { return }
            let W = canvasSize.width
            let H = canvasSize.height
            let left = Bool.random()
            let x = left ? CGFloat.random(in: W*0.04...W*0.08) : CGFloat.random(in: W*0.92...W*0.96)
            let y = CGFloat.random(in: H*0.08...H*0.55)
            CelebrationTrigger.explodeFirecracker(system: self, x: x, y: y)
        }
    }
    
    func stopLoops() {
        loopTimerFireworks?.invalidate(); loopTimerFireworks = nil
        loopTimerCrackers?.invalidate(); loopTimerCrackers = nil
    }
    
    func stop() {
        displayTimer?.invalidate(); displayTimer = nil
        stopLoops()
        particles.removeAll()
        isActive = false
    }
    
    private func update() {
        let now = CFAbsoluteTimeGetCurrent()
        let targetDt = 1.0 / Double(max(1, fpsTarget))
        let realDt = lastUpdateAt.map { min(max(now - $0, targetDt * 0.5), 0.05) } ?? targetDt
        lastUpdateAt = now
        let dt: Float = Float(realDt)

        // 自适应降载切换（基于总量与帧时长）
        if particles.count > highWatermark || realDt > targetDt * 1.5 {
            reducedLoad = true
        } else if particles.count < lowWatermark && realDt < targetDt * 1.1 {
            reducedLoad = false
        }

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
        let cap = maxParticles
        let available = cap - particles.count
        guard available > 0 else { return }
        // 降载时进一步削减新粒子
        var slice = reducedLoad ? max(available / 2, 0) : available
        if slice <= 0 { return }
        // 对烟花爆炸火花（fireworkSpark）执行“每帧上限”控制
        let sparks = newOnes.filter { $0.type == .fireworkSpark }
        let others = newOnes.filter { $0.type != .fireworkSpark }
        let allowedSparks = Array(sparks.prefix(min(perFrameSparkCap, slice)))
        slice -= allowedSparks.count
        let allowedOthers = Array(others.prefix(max(slice, 0)))
        particles.append(contentsOf: allowedSparks + allowedOthers)
    }
    
    // 配置性能：设置 FPS 目标（重建计时器）
    func configurePerformance(fpsTarget: Int) {
        let newTarget = (fpsTarget == 120) ? 120 : 60
        if newTarget != self.fpsTarget {
            self.fpsTarget = newTarget
            applyTimer()
        } else if displayTimer == nil {
            applyTimer()
        }
    }
    
    private func applyTimer() {
        displayTimer?.invalidate(); displayTimer = nil
        lastUpdateAt = nil
        let interval = 1.0 / Double(max(1, fpsTarget))
        displayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
    }
}

// MARK: - 全屏庆祝覆盖层
struct CelebrationOverlayView: View {
    @ObservedObject var system: CelebrationSystem
    @EnvironmentObject var settings: GameSettings
    @State private var blinkCount: Int = 0
    @State private var isTextVisible: Bool = true
    @State private var blinkTimer: Timer?
    @State private var canvasSize: CGSize = .zero
    
    // 彩虹色数组
    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 全屏透明背景（确保覆盖整个界面）
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 粒子画布
                Canvas { context, size in
                    // 存储实际画布尺寸
                    if canvasSize != size {
                        canvasSize = size
                    }
                    
                    for p in system.particles {
                        let rect = CGRect(
                            x: p.x - p.size / 2,
                            y: p.y - p.size / 2,
                            width: p.size,
                            height: p.size
                        )
                        
                        // 根据粒子类型绘制不同效果
                        let gpuFriendly = settings.gpuFriendly
                        switch p.type {
                        case .firecracker, .firecrackerDebris:
                            // 鞭炮粒子：光晕层在 GPU 友好模式下减少
                            if !gpuFriendly {
                                context.fill(
                                    Path(ellipseIn: rect.insetBy(dx: -p.size * 0.3, dy: -p.size * 0.3)),
                                    with: .color(p.color.opacity(Double(p.alpha) * 0.3))
                                )
                            }
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(p.color.opacity(Double(p.alpha) * 0.95))
                            )
                        case .fireworkTrail:
                            // 尾迹：细长（GPU 友好模式下缩短并减少不透明度）
                            let lenScale: CGFloat = gpuFriendly ? 1.4 : 2.0
                            let trailRect = CGRect(
                                x: p.x - p.size / 4,
                                y: p.y - p.size,
                                width: p.size / 2,
                                height: p.size * lenScale
                            )
                            context.fill(
                                Path(ellipseIn: trailRect),
                                with: .color(p.color.opacity(Double(p.alpha) * (gpuFriendly ? 0.4 : 0.6)))
                            )
                        case .fireworkSpark:
                            // 火花：光晕层在 GPU 友好模式下从 2 层降为 1 层
                            if !gpuFriendly {
                                context.fill(
                                    Path(ellipseIn: rect.insetBy(dx: -p.size * 0.8, dy: -p.size * 0.8)),
                                    with: .color(p.color.opacity(Double(p.alpha) * 0.2))
                                )
                                context.fill(
                                    Path(ellipseIn: rect.insetBy(dx: -p.size * 0.4, dy: -p.size * 0.4)),
                                    with: .color(p.color.opacity(Double(p.alpha) * 0.5))
                                )
                            } else {
                                context.fill(
                                    Path(ellipseIn: rect.insetBy(dx: -p.size * 0.5, dy: -p.size * 0.5)),
                                    with: .color(p.color.opacity(Double(p.alpha) * 0.35))
                                )
                            }
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(.white.opacity(Double(p.alpha) * 0.9))
                            )
                        }
                    }
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
                
                // 彩虹闪烁文字 - 移到界面顶部，不遮挡成绩
                if isTextVisible && blinkCount < 6 && system.isActive {
                    VStack {
                        Text(celebrationText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                            .scaleEffect(1.1)
                            .animation(.easeInOut(duration: 0.15), value: blinkCount)
                            .outlineShadow(color: .yellow)
                            .padding(.top, 60) // 距离顶部60像素
                        
                        Spacer() // 占位，把文字顶上去
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // 使用实际画布尺寸触发庆祝效果
                let size = geometry.size
                if size.width > 0 && size.height > 0 && system.isActive {
                    DispatchQueue.main.async {
                        CelebrationTrigger.trigger(
                            rank: system.playerRank,
                            system: system,
                            playerName: system.playerName,
                            canvasSize: size,
                            soundEngine: nil
                        )
                        system.startLoops(canvasSize: size, intensity: GameSettings.CelebrationIntensity.fancy)
                    }
                }
            }
            .onChange(of: system.isActive) { active in
                if active {
                    startBlinking()
                    // 再次检查并触发（如果onAppear时isActive还未设置）
                    let size = geometry.size
                    if size.width > 0 && size.height > 0 {
                        DispatchQueue.main.async {
                            CelebrationTrigger.trigger(
                                rank: system.playerRank,
                                system: system,
                                playerName: system.playerName,
                                canvasSize: size,
                                soundEngine: nil
                            )
                            system.startLoops(canvasSize: size, intensity: GameSettings.CelebrationIntensity.fancy)
                        }
                    }
                } else {
                    stopBlinking()
                    system.stop()
                }
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
        return "🎉 恭喜 \(name)获得 \(rankText) 的成绩！🎉"
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
    static func trigger(rank: Int, system: CelebrationSystem, playerName: String, canvasSize: CGSize, soundEngine: SoundEngine?) {
        // 设置玩家信息并立即开始一轮视觉
        system.start(name: playerName, rank: rank)
        
        // 使用实际 Canvas 尺寸
        let W = Float(canvasSize.width)
        let H = Float(canvasSize.height)
        
        // 开场：对联式鞭炮一轮+两三发烟花
        startFirecrackerCouplets(system: system, W: W, H: H, soundEngine: soundEngine)
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
                launchFirework(system: system, W: W, H: H, soundEngine: soundEngine)
            }
        }
        // 后续持续循环由 CelebrationSystem.startLoops 控制，直到 isActive 被置为 false
    }
    
    // MARK: - 门神对联式鞭炮（悬挂→爆炸）
    @MainActor
    private static func startFirecrackerCouplets(system: CelebrationSystem, W: Float, H: Float, soundEngine: SoundEngine?) {
        // 鞭炮串位置：SwiftUI坐标系（原点在左上角，Y向下）
        // 左串：距离左边缘5%，从顶部10%开始向下延伸
        let leftX = W * 0.05
        let leftTopY = H * 0.10
        let leftHeight = H * 0.35
        
        // 右串：距离右边缘5%，从顶部10%开始向下延伸
        let rightX = W * 0.95
        let rightTopY = H * 0.10
        let rightHeight = H * 0.35
        
        // 横批：顶部中央
        let centerX = W * 0.5
        let centerY = H * 0.05
        let centerWidth = W * 0.30
        
        let firecrackerCount = 16
        let explosionInterval: Double = 0.12
        
        // 显示悬挂的鞭炮串
        showHangingFirecrackers(system: system, leftX: leftX, leftY: leftTopY, leftHeight: leftHeight, rightX: rightX, rightY: rightTopY, rightHeight: rightHeight, centerX: centerX, centerY: centerY, centerWidth: centerWidth, count: firecrackerCount)
        
        // 0.5秒后开始爆炸（从上往下）
        let startDelay: Double = 0.5
        
        // 左串（从上往下炸）
        for i in 0..<firecrackerCount {
            let delay = startDelay + Double(i) * explosionInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Float(i) / Float(firecrackerCount - 1)
                let y = leftTopY + leftHeight * progress  // Y向下增加
                explodeFirecracker(system: system, x: CGFloat(leftX), y: CGFloat(y))
                soundEngine?.playSingleFirecracker()
            }
        }
        
        // 右串（从上往下炸）
        for i in 0..<firecrackerCount {
            let delay = startDelay + Double(i) * explosionInterval + 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Float(i) / Float(firecrackerCount - 1)
                let y = rightTopY + rightHeight * progress
                explodeFirecracker(system: system, x: CGFloat(rightX), y: CGFloat(y))
            }
        }
        
        // 横批（从中间往两边）
        for i in 0..<(firecrackerCount / 2) {
            let delay = startDelay + Double(i) * explosionInterval * 1.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Float(i) / Float(firecrackerCount / 2 - 1)
                let xLeft = centerX - centerWidth * progress
                explodeFirecracker(system: system, x: CGFloat(xLeft), y: CGFloat(centerY))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.02) {
                let progress = Float(i) / Float(firecrackerCount / 2 - 1)
                let xRight = centerX + centerWidth * progress
                explodeFirecracker(system: system, x: CGFloat(xRight), y: CGFloat(centerY))
            }
        }
    }
    
    // MARK: - 显示悬挂的鞭炮串（静态视觉）
    @MainActor
    private static func showHangingFirecrackers(system: CelebrationSystem, leftX: Float, leftY: Float, leftHeight: Float, rightX: Float, rightY: Float, rightHeight: Float, centerX: Float, centerY: Float, centerWidth: Float, count: Int) {
        var batch: [CelebrationSystem.CelebrationParticle] = []
        
        let hangingColor = Color(red: 0.6, green: 0.15, blue: 0.1)
        
        // 左串（Y向下延伸）
        for i in 0..<count {
            let progress = Float(i) / Float(count - 1)
            let yPos = leftY + leftHeight * progress
            
            batch.append(.init(
                x: CGFloat(leftX),
                y: CGFloat(yPos),
                vx: 0,
                vy: 0,
                life: 0.5,
                maxLife: 0.5,
                size: CGFloat.random(in: 5...8),
                color: hangingColor,
                type: .firecracker
            ))
        }
        
        // 右串
        for i in 0..<count {
            let progress = Float(i) / Float(count - 1)
            let yPos = rightY + rightHeight * progress
            
            batch.append(.init(
                x: CGFloat(rightX),
                y: CGFloat(yPos),
                vx: 0,
                vy: 0,
                life: 0.5,
                maxLife: 0.5,
                size: CGFloat.random(in: 5...8),
                color: hangingColor,
                type: .firecracker
            ))
        }
        
        // 横批
        let centerCount = count / 2
        for i in 0..<centerCount {
            let progress = Float(i) / Float(centerCount - 1)
            let xPos = centerX - centerWidth * 0.5 + centerWidth * progress
            
            batch.append(.init(
                x: CGFloat(xPos),
                y: CGFloat(centerY),
                vx: 0,
                vy: 0,
                life: 0.5,
                maxLife: 0.5,
                size: CGFloat.random(in: 4...7),
                color: hangingColor,
                type: .firecracker
            ))
        }
        
        system.addParticles(batch)
    }
    
    // MARK: - 单个鞭炮爆炸（产生爆炸粒子和碎片）
    @MainActor
    static func explodeFirecracker(system: CelebrationSystem, x: CGFloat, y: CGFloat) {
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
        
        // 爆炸核心粒子（4-6个，快速扩散）- 速度加倍
        let coreCount = Int.random(in: 4...6)
        for _ in 0..<coreCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 160...360)  // 速度加倍 (80*2...180*2)
            
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
        
        // 飞溅碎片（8-12个，飞得更远，受重力掉落）- 速度加倍
        let debrisCount = Int.random(in: 8...12)
        for _ in 0..<debrisCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 300...700)  // 速度加倍 (150*2...350*2)
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
    static func launchFirework(system: CelebrationSystem, W: Float, H: Float, soundEngine: SoundEngine?) {
        // 发射位置：底部中间
        let launchX = W * 0.5
        let launchY = H * 0.85
        
        // 目标爆炸位置：中间偏上（限制在屏幕中央区域）
        let targetX = W * Float.random(in: 0.3...0.7)
        let targetY = H * Float.random(in: 0.25...0.45)
        
        // 计算发射速度
        let dx = targetX - launchX
        let dy = targetY - launchY  // Y向上减小（SwiftUI坐标系Y向下，所以向上是负值）
        let distance = sqrt(dx*dx + dy*dy)
        let launchSpeed: Float = 400
        let vx = (dx / distance) * launchSpeed
        let vy = (dy / distance) * launchSpeed
        
        soundEngine?.playFireworkLaunch()
        
        // 尾迹 - 更粗更明显，消失时间加长一倍
        let flightTime = distance / launchSpeed
        let trailSteps = min(Int(flightTime / 0.02), 18)  // 增加步数
        
        for i in 0..<trailSteps {
            let t = Float(i) * 0.02
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(t)) {
                let px = launchX + vx * t
                let py = launchY + vy * t
                
                // 尾迹粒子：更大更粗，生命周期加长一倍
                system.addParticles([.init(
                    x: CGFloat(px),
                    y: CGFloat(py),
                    vx: 0,
                    vy: 0,
                    life: 0.4,  // 从 0.2 改为 0.4（加长一倍）
                    maxLife: 0.4,
                    size: 7,  // 从 3 改为 7（更粗更清楚）
                    color: Color.gray,
                    type: .fireworkTrail
                )])
            }
        }
        
        // 爆炸
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
        
        // 火花数量减少 1/3（更凝练），均匀圆形分布 + 随机扰动
        let baseCount = Int.random(in: 50...80)
        let sparkCount = max(12, Int(Double(baseCount) * (2.0/3.0)))
        
        for i in 0..<sparkCount {
            // 圆形均匀分布
            let angle = CGFloat(i) / CGFloat(sparkCount) * 2 * .pi + CGFloat.random(in: -0.1...0.1)
            // 速度加倍（更有爆发力）
            let speedBase = CGFloat.random(in: 220...560)
            let speedVariation = CGFloat.random(in: 0.8...1.2)
            let speed = (speedBase * speedVariation) * 2.0
            
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed
            
            // 随机选择颜色
            let color = colors.randomElement()!
            
            // 大小层次不变
            let size = CGFloat.random(in: 5...12)
            
            batch.append(.init(
                x: x + CGFloat.random(in: -3...3),
                y: y + CGFloat.random(in: -3...3),
                vx: vx,
                vy: vy,
                life: Float.random(in: 1.0...1.5),   // 持续时间减半
                maxLife: 1.5,
                size: size,
                color: color,
                type: .fireworkSpark
            ))
        }
        
        // 中心亮白火花：数量减少 1/3、速度加倍、寿命减半
        for _ in 0..<3 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 200...400)  // 加倍
            
            batch.append(.init(
                x: x,
                y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                life: Float.random(in: 0.5...0.75),   // 半寿命
                maxLife: 0.75,
                size: CGFloat.random(in: 8...14),
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
