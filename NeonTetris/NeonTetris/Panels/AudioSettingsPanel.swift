// ============================================================
// AudioSettingsPanel.swift — 音频设置面板
// 负责：音效/背景音乐开关和音量调整
// ============================================================

import SwiftUI

struct AudioSettingsPanel: View {
    @Environment(\.dismiss) var dismiss
    var soundEngine: SoundEngine?
    var musicPlayer: MusicPlayer?
    @ObservedObject var theme: AppTheme
    
    @State private var soundVolume: Float = 0.8
    @State private var musicVolume: Float = 0.5
    @State private var soundEnabled: Bool = true
    @State private var musicEnabled: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("音频设置")
                    .font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
            }
            
            Form {
                Section("音效") {
                    Toggle("启用音效", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { soundEngine?.enabled = $0 }
                    
                    Slider(value: $soundVolume, in: 0...1, step: 0.1)
                        .onChange(of: soundVolume) { soundEngine?.volume = $0 }
                    
                    Text("音量 \(Int(soundVolume * 100))%")
                        .foregroundColor(.secondary)
                }
                
                Section("背景音乐") {
                    Toggle("启用背景音乐", isOn: $musicEnabled)
                        .onChange(of: musicEnabled) { musicPlayer?.enabled = $0 }
                    
                    Slider(value: $musicVolume, in: 0...1, step: 0.1)
                        .onChange(of: musicVolume) { musicPlayer?.volume = $0 }
                    
                    Text("音量 \(Int(musicVolume * 100))%")
                        .foregroundColor(.secondary)
                    
                    Button("选择自定义音乐") {
                        musicPlayer?.selectCustomMusic()
                    }
                    
                    if let name = musicPlayer?.currentTrackName {
                        Text("当前: \(name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 400)
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
