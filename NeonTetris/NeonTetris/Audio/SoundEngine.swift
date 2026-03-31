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
        try? engine.start()
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
            return generateTone(frequency: 440, duration: 0.05, envelope: .click, format: format)
        case .rotate:
            return generateSweep(from: 300, to: 600, duration: 0.08, format: format)
        case .rotateFail:
            return generateTone(frequency: 200, duration: 0.06, envelope: .click, format: format)
        case .softDrop:
            return generateTone(frequency: 350, duration: 0.04, envelope: .click, format: format)
        case .hardDrop:
            return generateTone(frequency: 150, duration: 0.12, envelope: .punch, format: format)
        case .lock:
            return generateTone(frequency: 500, duration: 0.08, envelope: .click, format: format)
        case .clear1:
            return generateChord(frequencies: [523, 659], duration: 0.2, format: format)
        case .clear2:
            return generateChord(frequencies: [523, 659, 784], duration: 0.25, format: format)
        case .clear3:
            return generateChord(frequencies: [523, 659, 784, 1047], duration: 0.3, format: format)
        case .clear4:
            return generateChord(frequencies: [523, 659, 784, 1047, 1319], duration: 0.5, format: format)
        case .hold:
            return generateSweep(from: 400, to: 600, duration: 0.1, format: format)
        case .levelUp:
            return generateArpeggio(frequencies: [523, 659, 784, 1047], duration: 0.4, format: format)
        case .gameOver:
            return generateSweep(from: 400, to: 100, duration: 0.8, format: format)
        case .wallHit:
            return generateTone(frequency: 180, duration: 0.04, envelope: .click, format: format)
        }
    }

    // MARK: - 音效生成工具

    enum Envelope { case click, punch }

    private func generateTone(frequency: Double, duration: Double, envelope: Envelope, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let env: Float
            switch envelope {
            case .click: env = Float(exp(-t * 30))
            case .punch: env = Float(exp(-t * 10))
            }
            data[i] = Float(sin(2 * .pi * frequency * t)) * env * 0.5
        }
        return buffer
    }

    private func generateSweep(from: Double, to: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let progress = t / duration
            let freq = from + (to - from) * progress
            let env = Float(1.0 - progress) * 0.5
            data[i] = Float(sin(2 * .pi * freq * t)) * env
        }
        return buffer
    }

    private func generateChord(frequencies: [Double], duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let env = Float(exp(-t * 3)) * 0.4
            var sample: Float = 0
            for freq in frequencies {
                sample += Float(sin(2 * .pi * freq * t))
            }
            data[i] = sample / Float(frequencies.count) * env
        }
        return buffer
    }

    private func generateArpeggio(frequencies: [Double], duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
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
            let env = Float(exp(-localT * 8)) * 0.5
            data[i] = Float(sin(2 * .pi * freq * t)) * env
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
