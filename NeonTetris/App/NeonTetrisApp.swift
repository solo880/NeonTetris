// ============================================================
// NeonTetrisApp.swift — App 入口
// 负责：应用生命周期、窗口配置
// ============================================================

import SwiftUI

@main
struct NeonTetrisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // 移除默认菜单项
            CommandGroup(replacing: .newItem) {}
        }
    }
}
