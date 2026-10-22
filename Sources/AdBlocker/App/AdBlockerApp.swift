import SwiftUI
import AppKit

@main
struct AdBlockerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        FloatingPanelController.configureWindow(window, isAlwaysOnTop: AppSettings.shared.isAlwaysOnTop)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .appInfo) {
                Button("About YouTube Ad Blocker") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "YouTube Ad Blocker",
                            .applicationVersion: "1.0.0",
                            .version: "2026.1"
                        ]
                    )
                }
            }
            CommandMenu("Player") {
                Button("Toggle Cinema Mode") {
                    AppSettings.shared.cinemaMode.toggle()
                }
                .keyboardShortcut("f", modifiers: [.command])

                Button("Toggle Always on Top (PiP)") {
                    AppSettings.shared.isAlwaysOnTop.toggle()
                    if let window = NSApplication.shared.windows.first {
                        FloatingPanelController.updateWindowLevel(window, isAlwaysOnTop: AppSettings.shared.isAlwaysOnTop)
                    }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Toggle Shorts") {
                    AppSettings.shared.hideShorts.toggle()
                }

                Button("Toggle Captions / Transcript") {
                    AppSettings.shared.isShowingCaptions.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
