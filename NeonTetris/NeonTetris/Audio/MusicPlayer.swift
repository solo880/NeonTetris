// ============================================================
// MusicPlayer.swift — 背景音乐播放器
// 负责：内置BGM播放、自选音乐文件、循环/淡入淡出
// ============================================================

import AVFoundation
import AppKit

// MARK: - 背景音乐播放器
class MusicPlayer: ObservableObject {

    @Published var isPlaying: Bool = false
    @Published var currentTrackName: String = "内置 BGM"

    private var player: AVAudioPlayer?
    var enabled: Bool = true {
        didSet { enabled ? resume() : pause() }
    }
    var volume: Float = 0.5 {
        didSet { player?.volume = volume }
    }

    // MARK: - 初始化（加载内置 BGM）
    init() {
        loadBuiltinBGM()
    }

    // MARK: - 加载内置 BGM
    func loadBuiltinBGM() {
        // 优先加载 BGM.mp3（如果存在）
        if let url = Bundle.main.url(forResource: "BGM", withExtension: "mp3") {
            load(url: url, name: "BGM")
            return
        }
        // 备用：《芒种》
        if let url = Bundle.main.url(forResource: "《芒种》", withExtension: "mp3") {
            load(url: url, name: "《芒种》")
            return
        }
        // 备用：Bundle 内置 BGM
        if let url = Bundle.main.url(forResource: "bgm_default", withExtension: "mp3") {
            load(url: url, name: "内置 BGM")
        } else {
            // 无内置 BGM 时生成简单节拍
            generateSimpleBeat()
        }
    }

    // MARK: - 加载指定 URL 的音乐
    private func load(url: URL, name: String) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1  // 无限循环
            player?.volume = volume
            currentTrackName = name
        } catch {
            print("音乐加载失败: \(error)")
        }
    }

    // MARK: - 用户自选音乐文件（弹出文件选择器）
    func selectCustomMusic() {
        let panel = NSOpenPanel()
        panel.title = "选择背景音乐"
        panel.allowedContentTypes = [.mp3, .wav, .aiff, .mpeg4Audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            let name = url.deletingPathExtension().lastPathComponent
            load(url: url, name: name)
            if enabled { play() }
        }
    }

    // MARK: - 播放控制
    func play() {
        guard enabled else { return }
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        guard enabled else { return }
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
    }

    // MARK: - 淡入
    func fadeIn(duration: Double = 1.0) {
        player?.volume = 0
        player?.play()
        isPlaying = true
        let steps = 20
        let stepDuration = duration / Double(steps)
        let targetVolume = volume
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                self?.player?.volume = targetVolume * Float(i) / Float(steps)
            }
        }
    }

    // MARK: - 淡出
    func fadeOut(duration: Double = 1.0, completion: (() -> Void)? = nil) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let startVolume = player?.volume ?? volume
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                self?.player?.volume = startVolume * Float(steps - i) / Float(steps)
                if i == steps {
                    self?.player?.stop()
                    self?.isPlaying = false
                    completion?()
                }
            }
        }
    }

    // MARK: - 生成简单节拍（无音频文件时的备用）
    private func generateSimpleBeat() {
        // 生成一段简单的 PCM 节拍音频
        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: frameCount)

        // 简单的 4/4 拍节拍
        let bpm: Double = 120
        let beatInterval = sampleRate * 60 / bpm
        for i in 0..<frameCount {
            let beatPhase = Double(i).truncatingRemainder(dividingBy: beatInterval) / beatInterval
            if beatPhase < 0.05 {
                let t = beatPhase / 0.05
                let env = Float(1.0 - t)
                samples[i] = Int16(sin(2 * .pi * 440 * Double(i) / sampleRate) * Double(env) * 8000)
            }
        }

        // 写入临时文件
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("beat.wav")
        writeWAV(samples: samples, sampleRate: Int(sampleRate), to: tmpURL)
        load(url: tmpURL, name: "默认节拍")
    }

    private func writeWAV(samples: [Int16], sampleRate: Int, to url: URL) {
        var data = Data()
        let dataSize = samples.count * 2
        let fileSize = dataSize + 36

        func append<T: FixedWidthInteger>(_ value: T) {
            var v = value.littleEndian
            data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
        }

        // RIFF 头
        data.append(contentsOf: "RIFF".utf8)
        append(UInt32(fileSize))
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        append(UInt32(16))      // chunk size
        append(UInt16(1))       // PCM
        append(UInt16(1))       // mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2))
        append(UInt16(2))       // block align
        append(UInt16(16))      // bits per sample
        data.append(contentsOf: "data".utf8)
        append(UInt32(dataSize))
        for s in samples { append(s) }

        try? data.write(to: url)
    }
}
