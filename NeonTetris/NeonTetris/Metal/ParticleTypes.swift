// ============================================================
// ParticleTypes.swift — 粒子类型定义 + 物理模拟 + 随机化
// 带 Perlin 噪声、风场、重力、摩擦、三层随机颜色的自然粒子系统
// ============================================================

import SwiftUI
import simd

// MARK: - 颜色工具函数
extension Color {
    /// 生成随机颜色（保持饱和度和亮度）
    static func randomNeon() -> Color {
        let hue = Double.random(in: 0...1)
        return Color(hue: hue, saturation: 0.8, brightness: 0.95)
    }
    
    /// 生成随机颜色变体（基于基础颜色）
    static func randomVariant(of baseColor: Color) -> Color {
        let hue = Double.random(in: 0...1)
        let saturation = Double.random(in: 0.6...1.0)
        let brightness = Double.random(in: 0.7...1.0)
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - Perlin 噪声（用于自然扰动）
class PerlinNoise {
    private let permutation = [
        151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
        140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
        247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
        57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
        74, 165, 71, 134, 139, 48, 27, 166, 102, 143, 54, 65, 25, 63, 161, 1,
        215, 104, 3, 226, 83, 186, 177, 200, 130, 120, 1, 123, 151, 160, 137, 91,
        90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30,
        69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75,
        0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88,
        237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134,
        139, 48, 27, 166, 102, 143, 54, 65, 25, 63, 161, 1, 215, 104, 3, 226,
        83, 186, 177, 200, 130, 120, 1, 123, 151, 160, 137, 91, 90, 15, 131, 13,
        201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99,
        37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62,
        94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87,
        174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166,
        102, 143, 54, 65, 25, 63, 161, 1, 215, 104, 3, 226, 83, 186, 177, 200
    ]
    
    func noise(_ x: Float, _ y: Float, _ z: Float) -> Float {
        let xi = Int(x) & 255
        let yi = Int(y) & 255
        let zi = Int(z) & 255
        
        let xf = x - Float(Int(x))
        let yf = y - Float(Int(y))
        let zf = z - Float(Int(z))
        
        let u = fade(xf)
        let v = fade(yf)
        let w = fade(zf)
        
        let p0 = permutation[xi]
        let p1 = permutation[(xi + 1) & 255]
        
        let aa = permutation[(p0 + yi) & 255]
        let ab = permutation[(p0 + ((yi + 1) & 255)) & 255]
        let ba = permutation[(p1 + yi) & 255]
        let bb = permutation[(p1 + ((yi + 1) & 255)) & 255]
        
        let aaa = permutation[(aa + zi) & 255]
        let aab = permutation[(aa + ((zi + 1) & 255)) & 255]
        let aba = permutation[(ab + zi) & 255]
        let abb = permutation[(ab + ((zi + 1) & 255)) & 255]
        let baa = permutation[(ba + zi) & 255]
        let bab = permutation[(ba + ((zi + 1) & 255)) & 255]
        let bba = permutation[(bb + zi) & 255]
        let bbb = permutation[(bb + ((zi + 1) & 255)) & 255]
        
        let x1 = lerp(u, grad(aaa, xf, yf, zf), grad(baa, xf - 1, yf, zf))
        let x2 = lerp(u, grad(aba, xf, yf - 1, zf), grad(bba, xf - 1, yf - 1, zf))
        let y1 = lerp(v, x1, x2)
        
        let x3 = lerp(u, grad(aab, xf, yf, zf - 1), grad(bab, xf - 1, yf, zf - 1))
        let x4 = lerp(u, grad(abb, xf, yf - 1, zf - 1), grad(bbb, xf - 1, yf - 1, zf - 1))
        let y2 = lerp(v, x3, x4)
        
        return lerp(w, y1, y2)
    }
    
    private func fade(_ t: Float) -> Float {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func lerp(_ t: Float, _ a: Float, _ b: Float) -> Float {
        return a + t * (b - a)
    }
    
    private func grad(_ hash: Int, _ x: Float, _ y: Float, _ z: Float) -> Float {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 8 ? y : z
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

// MARK: - 粒子类型枚举
enum ParticleType: String, CaseIterable {
    case ionTrail      // 离子拖尾
    case airFlow       // 空气流动
    case spinOut       // 旋转甩出
    case burnSpark     // 燃烧火花
    case ionSplash     // 离子飞溅
    case lockFlash     // 锁定闪光
    case hardDropTrail // 硬降拖尾
    case firework      // 烟花
    case firecracker   // 鞭炮
    
    // 默认颜色
    var defaultColor: Color {
        switch self {
        case .ionTrail:      return .cyan
        case .airFlow:       return .blue
        case .spinOut:       return .purple
        case .burnSpark:     return .orange
        case .ionSplash:     return .yellow
        case .lockFlash:     return .white
        case .hardDropTrail: return .red
        case .firework:      return .pink
        case .firecracker:   return .orange
        }
    }
    
    // 生命周期（秒）
    var lifetime: Float {
        switch self {
        case .ionTrail:      return 1.5
        case .airFlow:       return 1.0
        case .spinOut:       return 1.2
        case .burnSpark:     return 1.8
        case .ionSplash:     return 2.0
        case .lockFlash:     return 0.6
        case .hardDropTrail: return 1.2
        case .firework:      return 4.0
        case .firecracker:   return 1.5
        }
    }
    
    // 初始大小
    var initialSize: Float {
        switch self {
        case .ionTrail:      return 6.0
        case .airFlow:       return 5.0
        case .spinOut:       return 8.0
        case .burnSpark:     return 5.0
        case .ionSplash:     return 10.0
        case .lockFlash:     return 12.0
        case .hardDropTrail: return 8.0
        case .firework:      return 15.0
        case .firecracker:   return 8.0
        }
    }
    
    // 初始速度
    var initialSpeed: Float {
        switch self {
        case .ionTrail:      return 80.0
        case .airFlow:       return 150.0
        case .spinOut:       return 250.0
        case .burnSpark:     return 120.0
        case .ionSplash:     return 300.0
        case .lockFlash:     return 50.0
        case .hardDropTrail: return 180.0
        case .firework:      return 400.0
        case .firecracker:   return 200.0
        }
    }
    
    // 质量（影响重力）
    var mass: Float {
        switch self {
        case .ionTrail:      return 0.5
        case .airFlow:       return 0.4
        case .spinOut:       return 0.45
        case .burnSpark:     return 0.6
        case .ionSplash:     return 0.5
        case .lockFlash:     return 0.1
        case .hardDropTrail: return 0.5
        case .firework:      return 0.2
        case .firecracker:   return 0.4
        }
    }
    
    // 摩擦系数（0-1，越小越滑）
    var friction: Float {
        switch self {
        case .ionTrail:      return 0.94
        case .airFlow:       return 0.92
        case .spinOut:       return 0.90
        case .burnSpark:     return 0.92
        case .ionSplash:     return 0.91
        case .lockFlash:     return 0.97
        case .hardDropTrail: return 0.93
        case .firework:      return 0.99
        case .firecracker:   return 0.88
        }
    }
    
    // 湍流强度（Perlin噪声影响）
    var turbulence: Float {
        switch self {
        case .ionTrail:      return 0.7
        case .airFlow:       return 0.9
        case .spinOut:       return 0.6
        case .burnSpark:     return 0.75
        case .ionSplash:     return 0.7
        case .lockFlash:     return 1.0
        case .hardDropTrail: return 0.5
        case .firework:      return 0.4
        case .firecracker:   return 0.6
        }
    }
}

// MARK: - 粒子数据结构（带物理属性 + 三层随机颜色）
struct Particle {
    var position: CGPoint      // 位置
    var velocity: CGVector     // 速度
    var acceleration: CGVector // 加速度（用于物理模拟）
    var color: Color           // 核心颜色
    var shellColor: Color      // 壳层颜色（随机）
    var outerColor: Color      // 外层颜色（随机）
    var size: CGFloat          // 大小
    var life: Float            // 当前生命值
    var maxLife: Float         // 最大生命值
    var type: ParticleType     // 粒子类型
    var mass: Float            // 质量（影响重力和碰撞）
    var friction: Float        // 摩擦系数（0-1）
    var noiseOffset: Float     // 噪声偏移（用于Perlin噪声）
    var turbulence: Float      // 湍流强度
    
    // 生命周期进度（0-1）
    var lifeProgress: Float {
        life / maxLife
    }
    
    // 是否存活
    var isAlive: Bool {
        life > 0
    }
    
    // 更新粒子（物理模拟 + 噪声扰动）
    mutating func update(deltaTime: Float, perlin: PerlinNoise, windForce: CGVector = CGVector(dx: 0, dy: 0)) {
        life -= deltaTime
        
        // ========== 大方向：符合物理 ==========
        
        // 1. 应用全局风场
        acceleration.dx = acceleration.dx + CGFloat(Float(windForce.dx) * 0.08)
        acceleration.dy = acceleration.dy + CGFloat(Float(windForce.dy) * 0.08)
        
        // 2. 应用重力（根据粒子类型和质量）
        let gravityScale: Float = {
            switch type {
            case .ionTrail:      return 0.2 * mass
            case .airFlow:       return 0.3 * mass
            case .spinOut:       return 0.25 * mass
            case .burnSpark:     return 0.4 * mass
            case .ionSplash:     return 0.35 * mass
            case .lockFlash:     return 0.02 * mass
            case .hardDropTrail: return 0.3 * mass
            case .firework:      return -0.25 * mass
            case .firecracker:   return 0.2 * mass
            }
        }()
        acceleration.dy = acceleration.dy + CGFloat(gravityScale) * 120
        
        // ========== 局部：随机扰动（Perlin 噪声） ==========
        
        // 3. Perlin 噪声扰动（自然湍流效应）
        noiseOffset += deltaTime * 3.0
        let noiseX = perlin.noise(noiseOffset, Float(position.x) * 0.015, Float(position.y) * 0.015)
        let noiseY = perlin.noise(noiseOffset + 100, Float(position.x) * 0.015, Float(position.y) * 0.015)
        
        // 4. 应用湍流加速度（局部随机）
        acceleration.dx = acceleration.dx + CGFloat(noiseX) * CGFloat(turbulence) * 120
        acceleration.dy = acceleration.dy + CGFloat(noiseY) * CGFloat(turbulence) * 120
        
        // ========== 速度更新 ==========
        
        // 5. 更新速度（应用加速度）
        velocity.dx = velocity.dx + acceleration.dx * CGFloat(deltaTime)
        velocity.dy = velocity.dy + acceleration.dy * CGFloat(deltaTime)
        
        // 6. 应用摩擦力（减速）
        velocity.dx = velocity.dx * CGFloat(friction)
        velocity.dy = velocity.dy * CGFloat(friction)
        
        // ========== 位置更新 ==========
        
        // 7. 更新位置
        position.x = position.x + velocity.dx * CGFloat(deltaTime)
        position.y = position.y + velocity.dy * CGFloat(deltaTime)
        
        // 8. 重置加速度（每帧重置）
        acceleration = CGVector(dx: 0, dy: 0)
    }
}

// MARK: - 粒子工厂（带随机化）
enum ParticleFactory {
    /// 生成随机出生位置（在给定范围内分散）
    private static func randomSpawnOffset() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: -15...15),
            y: CGFloat.random(in: -15...15)
        )
    }
    
    /// 生成随机大小（基础大小 ± 40%）
    private static func randomSize(_ baseSize: Float) -> CGFloat {
        let variation = CGFloat.random(in: 0.6...1.4)
        return CGFloat(baseSize) * variation
    }
    
    /// 生成随机寿命（基础寿命 ± 30%）
    private static func randomLifetime(_ baseLifetime: Float) -> Float {
        let variation = Float.random(in: 0.7...1.3)
        return baseLifetime * variation
    }
    
    static func ionTrail(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.ionTrail
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: CGFloat.random(in: -40...40), dy: CGFloat.random(in: -100...(-30))),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func airFlow(x: Float, y: Float, direction: Float) -> Particle {
        let type = ParticleType.airFlow
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: CGFloat(direction) * 120 + CGFloat.random(in: -60...60), dy: CGFloat.random(in: -80...80)),
            acceleration: CGVector(dx: 0, dy: 0),
            color: .blue,
            shellColor: .randomVariant(of: .blue),
            outerColor: .randomVariant(of: .blue),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func spinOut(x: Float, y: Float, angle: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.spinOut
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let speed = CGFloat(type.initialSpeed) * CGFloat.random(in: 0.6...1.2)
        let angleVariation = angle + Float.random(in: -0.5...0.5)
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: cos(CGFloat(angleVariation)) * speed, dy: sin(CGFloat(angleVariation)) * speed),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func burnSpark(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.burnSpark
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let angle = CGFloat.random(in: -1.0...1.0) - .pi / 2
        let speed = CGFloat(type.initialSpeed) * CGFloat.random(in: 0.5...1.2)
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func ionSplash(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.ionSplash
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let angle = CGFloat.random(in: 0...2 * .pi)
        let speed = CGFloat(type.initialSpeed) * CGFloat.random(in: 0.4...1.2)
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func lockFlash(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.lockFlash
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: CGFloat.random(in: -60...60), dy: CGFloat.random(in: -80...(-10))),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func hardDropTrail(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.hardDropTrail
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: CGFloat.random(in: -70...70), dy: CGFloat.random(in: 60...180)),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func firework(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.firework
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let angle = CGFloat.random(in: 0...2 * .pi)
        let speed = CGFloat(type.initialSpeed) * CGFloat.random(in: 0.3...1.2)
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - 250),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
    
    static func firecracker(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let type = ParticleType.firecracker
        let baseColor = Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z), opacity: Double(color.w))
        let angle = CGFloat.random(in: 0...2 * .pi)
        let speed = CGFloat(type.initialSpeed) * CGFloat.random(in: 0.4...1.2)
        let spawnOffset = randomSpawnOffset()
        let randomSize = randomSize(type.initialSize)
        let randomLifetime = randomLifetime(type.lifetime)
        
        return Particle(
            position: CGPoint(x: CGFloat(x) + spawnOffset.x, y: CGFloat(y) + spawnOffset.y),
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            acceleration: CGVector(dx: 0, dy: 0),
            color: baseColor,
            shellColor: .randomVariant(of: baseColor),
            outerColor: .randomVariant(of: baseColor),
            size: randomSize,
            life: randomLifetime,
            maxLife: randomLifetime,
            type: type,
            mass: type.mass,
            friction: type.friction,
            noiseOffset: Float.random(in: 0...100),
            turbulence: type.turbulence
        )
    }
}
