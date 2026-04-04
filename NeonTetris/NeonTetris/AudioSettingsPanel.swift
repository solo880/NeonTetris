// ============================================================
// AudioSettingsPanel.swift — 音频设置面板
// 负责：音效/背景音乐开关和音量调整，支持中英文
// ============================================================

import SwiftUI

struct AudioSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    var soundEngine: SoundEngine?
    var musicPlayer: MusicPlayer?
    @ObservedObject var theme: AppTheme
    @ObservedObject var localization = LocalizationManager.shared
    
    @State private var soundVolume: Float = 0.8
    @State private var musicVolume: Float = 0.5
    @State private var soundEnabled: Bool = true
    @State private var musicEnabled: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(localization.t("音频设置", "Audio Settings"))
                    .font(.headline)
                Spacer()
                Button(localization.t("关闭", "Close")) { dismiss() }
            }
            
            VStack(spacing: 15) {
                // 测试音效按钮
                BlockButton(
                    label: localization.t("测试音效", "Test Sound"),
                    systemImage: "speaker.wave.2",
                    color: .blockI,
                    action: { soundEngine?.play(.move) }
                )
                
                Divider()
                
                // 音效设置
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(localization.t("启用音效", "Enable Sound"), isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { soundEngine?.enabled = $0 }
                    
                    HStack {
                        Text(localization.t("音量", "Volume"))
                        Slider(value: $soundVolume, in: 0...1, step: 0.1)
                            .onChange(of: soundVolume) { soundEngine?.volume = $0 }
                        Text("\(Int(soundVolume * 100))%")
                            .frame(width: 40)
                    }
                }
                
                Divider()
                
                // 背景音乐设置
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(localization.t("启用背景音乐", "Enable Music"), isOn: $musicEnabled)
                        .onChange(of: musicEnabled) { musicPlayer?.enabled = $0 }
                    
                    HStack {
                        Text(localization.t("音量", "Volume"))
                        Slider(value: $musicVolume, in: 0...1, step: 0.1)
                            .onChange(of: musicVolume) { musicPlayer?.volume = $0 }
                        Text("\(Int(musicVolume * 100))%")
                            .frame(width: 40)
                    }
                    
                    BlockButton(
                        label: localization.t("选择自定义音乐", "Select Custom Music"),
                        color: .blockL,
                        action: { musicPlayer?.selectCustomMusic() }
                    )
                    
                    if let name = musicPlayer?.currentTrackName {
                        Text(localization.t("当前", "Current") + ": \(name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 350, height: 400)
        .onAppear {
            soundVolume = soundEngine?.volume ?? 0.8
            musicVolume = musicPlayer?.volume ?? 0.5
            soundEnabled = soundEngine?.enabled ?? true
            musicEnabled = musicPlayer?.enabled ?? true
        }
    }
}

#Preview {
    AudioSettingsPanel(theme: AppTheme())
}
