// ============================================================
// ParticleSystem.swift — 粒子系统（CPU 版本 + 物理模拟）
// 负责：粒子池管理、粒子更新、事件响应、物理模拟
// 注：使用 SwiftUI Canvas 渲染，Metal 版本可后续升级
// ============================================================

import SwiftUI
import Combine

// MARK: - 粒子系统（ObservableObject，供 View 订阅）
@MainActor
class ParticleSystem: ObservableObject {

    @Published var particles: [Particle] = []

    // 粒子上限（超过则丢弃最旧的）
    private let maxParticles = ParticleConst.maxParticles
    
    // Perlin 噪声生成器（用于自然扰动）
    private let perlin = PerlinNoise()
    
    // 全局风场（可动态变化）
    var windForce: CGVector = CGVector(dx: 0, dy: 0)
    
    // 风场时间（用于动画风）
    private var windTime: Float = 0

    // 粒子配色方案（从主题获取）
    var colorScheme: ParticleColorScheme = .neon

    // MARK: - 更新所有粒子（每帧调用）
    func update() {
        // 更新风场（动态风）
        windTime += 0.016
        windForce = CGVector(
            dx: cos(Double(windTime) * 0.5) * 50,
            dy: sin(Double(windTime) * 0.3) * 30
        )
        
        // 更新存活粒子（使用物理模拟）
        for i in particles.indices {
            particles[i].update(deltaTime: 0.016, perlin: perlin, windForce: windForce)
        }
        // 移除死亡粒子
        particles.removeAll { !$0.isAlive }
    }

    // MARK: - 添加粒子（自动限制上限）
    private func add(_ newParticles: [Particle]) {
        let available = maxParticles - particles.count
        if available <= 0 { return }
        particles.append(contentsOf: newParticles.prefix(available))
    }

    // MARK: - 清空所有粒子
    func clear() {
        particles.removeAll()
    }

    // =========================================================
    // MARK: - 事件响应：生成对应粒子
    // =========================================================

    /// 方块离子拖尾（每帧调用，方块自带）- 减少 50%，寿命减少 20%
    func emitIonTrail(piece: TetrominoPiece, blockSize: CGFloat, color: Color) {
        let c = color.simd4
        var newParticles: [Particle] = []
        for block in piece.blocks {
            guard block.y >= 0 else { continue }
            let cx = Float(CGFloat(block.x) * blockSize + blockSize / 2)
            let cy = Float(CGFloat(block.y) * blockSize + blockSize / 2)
            // 减少 50%：原来 ionTrailRate，现在 ionTrailRate / 2
            for _ in 0..<(ParticleConst.ionTrailRate / 2) {
                var particle = ParticleFactory.ionTrail(x: cx, y: cy, color: c)
                // 寿命减少 20%
                particle.maxLife = particle.maxLife * 0.8
                particle.life = particle.maxLife
                newParticles.append(particle)
            }
        }
        add(newParticles)
    }

    /// 移动空气流动 - 减少 50%，寿命减少 20%
    func emitAirFlow(piece: TetrominoPiece, blockSize: CGFloat, direction: Float) {
        var newParticles: [Particle] = []
        for block in piece.blocks {
            guard block.y >= 0 else { continue }
            let cx = Float(CGFloat(block.x) * blockSize + blockSize / 2)
            let cy = Float(CGFloat(block.y) * blockSize + blockSize / 2)
            // 减少 50%：原来 airFlowCount，现在 airFlowCount / 2
            for _ in 0..<(ParticleConst.airFlowCount / 2) {
                var particle = ParticleFactory.airFlow(x: cx, y: cy, direction: direction)
                // 寿命减少 20%
                particle.maxLife = particle.maxLife * 0.8
                particle.life = particle.maxLife
                newParticles.append(particle)
            }
        }
        add(newParticles)
    }

    /// 旋转甩出 - 减少 50%，寿命减少 20%
    func emitSpinOut(piece: TetrominoPiece, blockSize: CGFloat, color: Color) {
        let c = color.simd4
        var newParticles: [Particle] = []
        for block in piece.blocks {
            guard block.y >= 0 else { continue }
            let cx = Float(CGFloat(block.x) * blockSize + blockSize / 2)
            let cy = Float(CGFloat(block.y) * blockSize + blockSize / 2)
            let baseAngle = Float.random(in: 0...Float.pi * 2)
            // 减少 50%：原来 spinOutCount，现在 spinOutCount / 2
            for i in 0..<(ParticleConst.spinOutCount / 2) {
                let angle = baseAngle + Float(i) / Float(ParticleConst.spinOutCount / 2) * Float.pi * 2
                var particle = ParticleFactory.spinOut(x: cx, y: cy, angle: angle, color: c)
                // 寿命减少 20%
                particle.maxLife = particle.maxLife * 0.8
                particle.life = particle.maxLife
                newParticles.append(particle)
            }
        }
        add(newParticles)
    }

    /// 行消除：燃烧+飞溅（优化版：增加数量 1 倍，增加寿命 30%）
    func emitLineClear(rows: [Int], blockSize: CGFloat, boardValues: [[Int]], pieceColors: (PieceType) -> Color) {
        var newParticles: [Particle] = []
        for row in rows {
            for col in 0..<GameConst.cols {
                let cx = Float(CGFloat(col) * blockSize + blockSize / 2)
                let cy = Float(CGFloat(row) * blockSize + blockSize / 2)
                
                // 燃烧火花：增加数量 1 倍（8 → 16），增加寿命 30%
                let burnCountIncreased = ParticleConst.burnCount / 5 * 2  // 40 / 5 * 2 = 16
                for _ in 0..<burnCountIncreased {
                    var particle = ParticleFactory.burnSpark(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4)
                    // 增加寿命 30%
                    particle.maxLife = particle.maxLife * 1.3
                    particle.life = particle.maxLife
                    // 分散程度保持不变（±30px）
                    particle.position.x += CGFloat.random(in: -30...30)
                    particle.position.y += CGFloat.random(in: -30...30)
                    newParticles.append(particle)
                }
                
                // 离子飞溅：增加数量 1 倍（4 → 8），增加寿命 30%
                let splashCountIncreased = ParticleConst.splashCount / 5 * 2  // 20 / 5 * 2 = 8
                for _ in 0..<splashCountIncreased {
                    var particle = ParticleFactory.ionSplash(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4)
                    // 增加寿命 30%
                    particle.maxLife = particle.maxLife * 1.3
                    particle.life = particle.maxLife
                    // 分散程度保持不变（±30px）
                    particle.position.x += CGFloat.random(in: -30...30)
                    particle.position.y += CGFloat.random(in: -30...30)
                    newParticles.append(particle)
                }
            }
        }
        add(newParticles)
    }

    /// 锁定闪光 - 减少 50%，寿命减少 20%
    func emitLockFlash(piece: TetrominoPiece, blockSize: CGFloat, color: Color) {
        let c = color.simd4
        var newParticles: [Particle] = []
        for block in piece.blocks {
            guard block.y >= 0 else { continue }
            let cx = Float(CGFloat(block.x) * blockSize + blockSize / 2)
            let cy = Float(CGFloat(block.y) * blockSize + blockSize / 2)
            // 减少 50%：原来 6，现在 3
            for _ in 0..<3 {
                var particle = ParticleFactory.lockFlash(x: cx, y: cy, color: c)
                // 寿命减少 20%
                particle.maxLife = particle.maxLife * 0.8
                particle.life = particle.maxLife
                newParticles.append(particle)
            }
        }
        add(newParticles)
    }

    /// 硬降拖尾 - 减少 50%，寿命减少 20%
    func emitHardDropTrail(piece: TetrominoPiece, fromY: Int, toY: Int, blockSize: CGFloat, color: Color) {
        let c = color.simd4
        var newParticles: [Particle] = []
        for block in piece.blocks {
            for row in fromY...toY {
                guard row >= 0 else { continue }
                let cx = Float(CGFloat(block.x) * blockSize + blockSize / 2)
                let cy = Float(CGFloat(row) * blockSize + blockSize / 2)
                // 减少 50%：原来每行 1 个，现在每 2 行 1 个
                if row % 2 == 0 {
                    var particle = ParticleFactory.hardDropTrail(x: cx, y: cy, color: c)
                    // 寿命减少 20%
                    particle.maxLife = particle.maxLife * 0.8
                    particle.life = particle.maxLife
                    newParticles.append(particle)
                }
            }
        }
        add(newParticles)
    }

    // MARK: - 烟花（排行榜前三）
    func emitFireworks(in size: CGSize, count: Int = 5) {
        let colors: [Color] = [
            Color(hex: "FF375F"), Color(hex: "30D158"), Color(hex: "FF9F0A"),
            Color(hex: "BF5AF2"), Color(hex: "FFD700"), Color(hex: "00F5FF")
        ]
        var newParticles: [Particle] = []
        for _ in 0..<count {
            let cx = Float.random(in: Float(size.width * 0.1)...Float(size.width * 0.9))
            let cy = Float.random(in: Float(size.height * 0.05)...Float(size.height * 0.5))
            let color = (colors.randomElement() ?? .white).simd4
            for _ in 0..<30 {
                newParticles.append(ParticleFactory.firework(x: cx, y: cy, color: color))
            }
        }
        add(newParticles)
    }

    // MARK: - 鞭炮（排行榜4-10）
    func emitFirecrackers(in size: CGSize) {
        var newParticles: [Particle] = []
        // 沿屏幕边缘串联爆炸
        let positions: [(Float, Float)] = (0..<8).map { i in
            let t = Float(i) / 8.0
            return (Float(size.width) * t, Float(size.height) * Float.random(in: 0.1...0.9))
        }
        for (cx, cy) in positions {
            for _ in 0..<15 {
                newParticles.append(ParticleFactory.firecracker(x: cx, y: cy, color: colorScheme.colors.randomElement()!.simd4))
            }
        }
        add(newParticles)
    }
}
