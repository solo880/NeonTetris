// ============================================================
// ParticleTypes.swift — 粒子类型定义
// 负责：粒子数据结构、粒子类型枚举、粒子工厂方法
// ============================================================

import SwiftUI

// MARK: - 粒子类型
enum ParticleKind {
    case ionTrail    // 离子拖尾（方块自带，持续发射）
    case airFlow     // 空气流动（下落/移动时）
    case spinOut     // 甩出效果（旋转时）
    case burnSpark   // 燃烧火花（行消除）
    case ionSplash   // 离子飞溅（行消除）
    case firework    // 烟花（排行榜前三）
    case firecracker // 鞭炮（排行榜4-10）
    case lockFlash   // 锁定闪光
    case hardDropTrail // 硬降拖尾
}

// MARK: - 粒子数据（值类型，高性能）
struct Particle {
    var x: Float            // 屏幕坐标 X
    var y: Float            // 屏幕坐标 Y
    var vx: Float           // 速度 X
    var vy: Float           // 速度 Y
    var r: Float            // 颜色 R
    var g: Float            // 颜色 G
    var b: Float            // 颜色B
    var alpha: Float        // 透明度
    var size: Float         // 粒子大小
    var life: Float         // 剩余生命（0-1）
    var decay: Float        // 每帧衰减量
    var gravity: Float      // 重力加速度
    var kind: ParticleKind  // 粒子类型

    /// 是否存活
    var isAlive: Bool { life > 0 }

    /// 更新粒子状态（每帧调用）
    mutating func update() {
        x += vx
        y += vy
        vy += gravity
        vx *= 0.97  // 水平阻力
        life -= decay
        alpha = max(0, life)
        size *= 0.995
    }
}

// MARK: - 粒子工厂
enum ParticleFactory {

    // MARK: - 离子拖尾（方块自带）
    static func ionTrail(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let angle = Float.random(in: 0...Float.pi * 2)
        let speed = Float.random(in: 0.3...1.5)
        return Particle(
            x: x + Float.random(in: -8...8),
            y: y + Float.random(in: -8...8),
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 0.5,
            r: color.x, g: color.y, b: color.z,
            alpha: Float.random(in: 0.6...1.0),
            size: Float.random(in: 2...5),
            life: Float.random(in: 0.4...0.8),
            decay: Float.random(in: 0.02...0.04),
            gravity: -0.02,  // 轻微上浮
            kind: .ionTrail
        )
    }

    // MARK: - 空气流动（移动/下落时）
    static func airFlow(x: Float, y: Float, direction: Float) -> Particle {
        // direction: -1=左, 1=右, 0=下落
        let angle = direction == 0
            ? Float.random(in: Float.pi * 0.3...Float.pi * 0.7)  // 向上扩散
            : Float.random(in: -Float.pi * 0.3...Float.pi * 0.3) + (direction > 0 ? Float.pi : 0)
        let speed = Float.random(in: 1...3)
        // 空气流动用青白色
        let t = Float.random(in: 0...1)
        return Particle(
            x: x, y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            r: t, g: 0.9 + t * 0.1, b: 1.0,
            alpha: Float.random(in: 0.3...0.7),
            size: Float.random(in: 1.5...4),
            life: Float.random(in: 0.3...0.6),
            decay: Float.random(in: 0.03...0.06),
            gravity: -0.05,
            kind: .airFlow
        )
    }

    // MARK: - 旋转甩出
    static func spinOut(x: Float, y: Float, angle: Float, color: SIMD4<Float>) -> Particle {
        let speed = Float.random(in: 2...6)
        let spread = Float.random(in: -0.5...0.5)
        return Particle(
            x: x, y: y,
            vx: cos(angle + spread) * speed,
            vy: sin(angle + spread) * speed,
            r: color.x, g: color.y, b: color.z,
            alpha: 1.0,
            size: Float.random(in: 3...7),
            life: Float.random(in: 0.5...1.0),
            decay: Float.random(in: 0.02...0.04),
            gravity: 0.1,
            kind: .spinOut
        )
    }

    // MARK: - 燃烧火花（行消除）
    static func burnSpark(x: Float, y: Float) -> Particle {
        let angle = Float.random(in: 0...Float.pi * 2)
        let speed = Float.random(in: 1...5)
        // 火焰色：红橙黄
        let t = Float.random(in: 0...1)
        return Particle(
            x: x, y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 2,  // 向上
            r: 1.0, g: t * 0.6, b: 0.0,
            alpha: 1.0,
            size: Float.random(in: 3...8),
            life: Float.random(in: 0.4...0.9),
            decay: Float.random(in: 0.02...0.05),
            gravity: 0.08,
            kind: .burnSpark
        )
    }

    // MARK: - 离子飞溅（行消除）
    static func ionSplash(x: Float, y: Float, colorScheme: ParticleColorScheme) -> Particle {
        let angle = Float.random(in: 0...Float.pi * 2)
        let speed = Float.random(in: 2...8)
        let color = colorScheme.colors.randomElement()?.simd4 ?? SIMD4<Float>(1,1,1,1)
        return Particle(
            x: x, y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 1,
            r: color.x, g: color.y, b: color.z,
            alpha: 1.0,
            size: Float.random(in: 2...6),
            life: Float.random(in: 0.6...1.2),
            decay: Float.random(in: 0.015...0.03),
            gravity: 0.12,
            kind: .ionSplash
        )
    }

    // MARK: - 烟花粒子
    static func firework(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let angle = Float.random(in: 0...Float.pi * 2)
        let speed = Float.random(in: 3...10)
        return Particle(
            x: x, y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            r: color.x, g: color.y, b: color.z,
            alpha: 1.0,
            size: Float.random(in: 3...7),
            life: Float.random(in: 0.8...1.5),
            decay: Float.random(in: 0.01...0.025),
            gravity: 0.15,
            kind: .firework
        )
    }

    // MARK: - 鞭炮粒子
    static func firecracker(x: Float, y: Float) -> Particle {
        let angle = Float.random(in: 0...Float.pi * 2)
        let speed = Float.random(in: 1...4)
        return Particle(
            x: x, y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            r: 1.0, g: Float.random(in: 0...0.3), b: 0.0,
            alpha: 1.0,
            size: Float.random(in: 2...5),
            life: Float.random(in: 0.3...0.8),
            decay: Float.random(in: 0.02...0.05),
            gravity: 0.1,
            kind: .firecracker
        )
    }

    // MARK: - 锁定闪光
    static func lockFlash(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        let angle = Float.random(in: 0...Float.pi * 2)
        let speed = Float.random(in: 0.5...3)
        return Particle(
            x: x, y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            r: color.x * 1.5, g: color.y * 1.5, b: color.z * 1.5,
            alpha: 0.9,
            size: Float.random(in: 2...5),
            life: Float.random(in: 0.2...0.5),
            decay: Float.random(in: 0.04...0.08),
            gravity: 0,
            kind: .lockFlash
        )
    }

    // MARK: - 硬降拖尾
    static func hardDropTrail(x: Float, y: Float, color: SIMD4<Float>) -> Particle {
        return Particle(
            x: x + Float.random(in: -4...4),
            y: y,
            vx: Float.random(in: -0.5...0.5),
            vy: Float.random(in: -1...0),
            r: color.x, g: color.y, b: color.z,
            alpha: Float.random(in: 0.4...0.8),
            size: Float.random(in: 2...5),
            life: Float.random(in: 0.2...0.5),
            decay: Float.random(in: 0.04...0.08),
            gravity: 0,
            kind: .hardDropTrail
        )
    }
}
