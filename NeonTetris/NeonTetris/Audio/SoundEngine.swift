// ============================================================
// SoundEngine.swift — 音效引擎
// 负责：游戏音效播放（AVAudioEngine + 预加载缓冲区）
// ============================================================

import AVFoundation
import Combine

// MARK: - 音效类型
enum SoundEffect: String {
    case move       = "move"        // 移动
    case rotate     = "rotate"      // 旋转
    case rotateFail = "rotateFail"  // 旋转失败
    case softDrop   = "softDrop"    // 软降
    case hardDrop   = "hardDrop"    // 硬降
    case lock       = "lock"        // 锁定
    case clear1     = "clear1"      // 消1行
    case clear2     = "clear2"      // 消2行
    case clear3     = "clear3"      // 消3行
    case clear4     = "clear4"      // 消4行（Tetris）
    case hold       = "hold"        // 暂存
    case levelUp    = "levelUp"     // 升级
    case gameOver   = "gameOver"    // 游戏结束
    case wallHit    = "wallHit"     // 撞墙
}

// MARK: - 音效引擎
class SoundEngine {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var cancellables = Set<AnyCancellable>()

    var enabled: Bool = true
    var volume: Float = 0.8 {
        didSet { mixer.outputVolume = volume }
    }

    init() {
        setupEngine()
        preloadSounds()
    }

    // MARK: - 引擎初始化
    private func setupEngine() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        mixer.outputVolume = volume
        
        do {
            try engine.start()
        } catch {
            print("音效引擎启动失败: \(error)")
        }
    }

    // MARK: - 预加载所有音效
    private func preloadSounds() {
        for effect in [SoundEffect.move, .rotate, .rotateFail, .softDrop, .hardDrop,
                       .lock, .clear1, .clear2, .clear3, .clear4,
                       .hold, .levelUp, .gameOver, .wallHit] {
            if let buffer = loadBuffer(named: effect.rawValue) {
                buffers[effect] = buffer
            } else {
                // 生成合成音效（无音频文件时的备用方案）
                buffers[effect] = synthesize(effect: effect)
            }
        }
    }

    // MARK: - 从 Bundle 加载音频文件
    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav",
                                        subdirectory: "Sounds") else { return nil }
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        try? file.read(into: buffer)
        return buffer
    }

    // MARK: - 合成音效（无音频文件时使用程序生成的音效）
    private func synthesize(effect: SoundEffect) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        switch effect {
        case .move:
            // 移动：清脆的点击声，800Hz + 噪声，持续 30ms
            return generateClickWithNoise(frequency: 800, duration: 0.03, format: format)
        case .rotate:
            // 旋转：上升的嗖嗖声，从 400Hz 扫到 1000Hz，带噪声，持续 100ms
            return generateSweepWithNoise(from: 400, to: 1000, duration: 0.1, format: format)
        case .rotateFail:
            // 旋转失败：低沉的"咔"声，150Hz + 噪声，持续 80ms
            return generateClickWithNoise(frequency: 150, duration: 0.08, format: format)
        case .softDrop:
            // 软降：快速连续的点击，600Hz，持续 40ms
            return generateClickWithNoise(frequency: 600, duration: 0.04, format: format)
        case .hardDrop:
            // 硬降：沉重的撞击声，低频 80Hz + 高频噪声，持续 200ms
            return generateImpact(duration: 0.2, format: format)
        case .lock:
            // 锁定：清脆的"哒"声，1200Hz，持续 60ms
            return generateClickWithNoise(frequency: 1200, duration: 0.06, format: format)
        case .clear1:
            // 消1行：上升的"叮"声，523Hz 上升到 784Hz，持续 300ms
            return generateRisingTone(from: 523, to: 784, duration: 0.3, format: format)
        case .clear2:
            // 消2行：更欢快的双音，523Hz + 659Hz，持续 350ms
            return generateChord([523, 659], duration: 0.35, format: format)
        case .clear3:
            // 消3行：三音和弦，523Hz + 659Hz + 784Hz，持续 400ms
            return generateChord([523, 659, 784], duration: 0.4, format: format)
        case .clear4:
            // 消4行（Tetris）：五声音阶上升，C5 E5 G5 C6 E6，持续 600ms
            return generateArpeggio([523, 659, 784, 1047, 1319], duration: 0.6, format: format)
        case .hold:
            // 暂存：轻快的交换声，400Hz 上升到 800Hz，持续 120ms
            return generateSweepWithNoise(from: 400, to: 800, duration: 0.12, format: format)
        case .levelUp:
            // 升级：胜利的号角音阶，C5 E5 G5 C6，持续 500ms
            return generateArpeggio([523, 659, 784, 1047], duration: 0.5, format: format)
        case .gameOver:
            // 游戏结束：下降的哀鸣，400Hz 下降到 100Hz，持续 1000ms
            return generateDescendingTone(from: 400, to: 100, duration: 1.0, format: format)
        case .wallHit:
            // 撞墙：沉闷的撞击，120Hz + 噪声，持续 60ms
            return generateClickWithNoise(frequency: 120, duration: 0.06, format: format)
        }
    }

    // MARK: - 音效生成工具（改进版）

    // 生成带噪声的点击声
    private func generateClickWithNoise(frequency: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let progress = t / duration
            // 快速衰减的包络
            let env = Float(exp(-t * 40)) * 0.6
            // 正弦波
            let sine = Float(sin(2 * .pi * frequency * t))
            // 添加谐波
            let harmonic = Float(sin(4 * .pi * frequency * t)) * 0.3
            // 添加高频噪声
            let noise = Float.random(in: -1...1) * 0.15
            data[i] = (sine + harmonic + noise) * env
        }
        return buffer
    }

    // 生成带噪声的扫频
    private func generateSweepWithNoise(from: Double, to: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let progress = t / duration
            // 对数扫频
            let freq = from * pow(to / from, progress)
            // 缓慢衰减的包络
            let env = Float(exp(-t * 5)) * 0.5
            // 正弦波
            let sine = Float(sin(2 * .pi * freq * t))
            // 添加噪声
            let noise = Float.random(in: -1...1) * 0.1
            data[i] = (sine + noise) * env
        }
        return buffer
    }

    // 生成撞击声（低频 + 噪声）
    private func generateImpact(duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            // 快速攻击然后缓慢衰减
            let attack = Float(min(t / 0.01, 1.0))
            let decay = Float(exp(-t * 8))
            let env = attack * decay * 0.7
            // 低频正弦波
            let bass = Float(sin(2 * .pi * 80 * t))
            // 中频成分
            let mid = Float(sin(2 * .pi * 200 * t)) * 0.5
            // 高频噪声
            let noise = Float.random(in: -1...1) * 0.4
            data[i] = (bass + mid + noise) * env
        }
        return buffer
    }

    // 生成上升音调
    private func generateRisingTone(from: Double, to: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let progress = t / duration
            let freq = from + (to - from) * progress
            // 包络：渐入渐出
            let env: Float
            if progress < 0.1 {
                env = Float(progress / 0.1) * 0.6
            } else {
                env = Float(exp(-(progress - 0.1) * 3)) * 0.6
            }
            // 正弦波 + 泛音
            let sine = Float(sin(2 * .pi * freq * t))
            let harmonic = Float(sin(4 * .pi * freq * t)) * 0.3
            let bright = Float(sin(6 * .pi * freq * t)) * 0.1
            data[i] = (sine + harmonic + bright) * env
        }
        return buffer
    }

    // 生成下降音调
    private func generateDescendingTone(from: Double, to: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let progress = t / duration
            let freq = from * pow(to / from, progress)
            // 缓慢衰减的包络
            let env = Float(exp(-t * 2)) * 0.6
            // 正弦波 + 低频泛音
            let sine = Float(sin(2 * .pi * freq * t))
            let bass = Float(sin(.pi * freq * t)) * 0.4
            data[i] = (sine + bass) * env
        }
        return buffer
    }

    // 生成和弦
    private func generateChord(_ frequencies: [Double], duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            // 指数衰减包络
            let env = Float(exp(-t * 4)) * 0.4
            var sample: Float = 0
            for freq in frequencies {
                sample += Float(sin(2 * .pi * freq * t))
            }
            data[i] = sample / Float(frequencies.count) * env
        }
        return buffer
    }

    // 生成琶音
    private func generateArpeggio(_ frequencies: [Double], duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let noteLen = duration / Double(frequencies.count)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let noteIdx = min(Int(t / noteLen), frequencies.count - 1)
            let freq = frequencies[noteIdx]
            let localT = t - Double(noteIdx) * noteLen
            // 每个音符独立的包络
            let env = Float(exp(-localT * 6)) * 0.6
            let sine = Float(sin(2 * .pi * freq * t))
            let harmonic = Float(sin(4 * .pi * freq * t)) * 0.2
            data[i] = (sine + harmonic) * env
        }
        return buffer
    }

    // MARK: - 播放音效
    func play(_ effect: SoundEffect) {
        guard enabled, let buffer = buffers[effect] else { return }
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: buffer.format)
        player.scheduleBuffer(buffer, completionHandler: {
            DispatchQueue.main.async {
                self.engine.detach(player)
            }
        })
        player.play()
    }

    // MARK: - 订阅游戏事件
    func subscribe(to publisher: PassthroughSubject<GameEvent, Never>) -> AnyCancellable {
        publisher.sink { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .moveLeft, .moveRight:     self.play(.move)
            case .rotate:                   self.play(.rotate)
            case .rotateFail:               self.play(.rotateFail)
            case .softDrop:                 self.play(.softDrop)
            case .hardDrop:                 self.play(.hardDrop)
            case .lock:                     self.play(.lock)
            case .hold:                     self.play(.hold)
            case .levelUp:                  self.play(.levelUp)
            case .gameOver:                 self.play(.gameOver)
            case .wallHit:                  self.play(.wallHit)
            case .lineClear(_, let count):
                switch count {
                case 1: self.play(.clear1)
                case 2: self.play(.clear2)
                case 3: self.play(.clear3)
                default: self.play(.clear4)
                }
            }
        }
    }
}
