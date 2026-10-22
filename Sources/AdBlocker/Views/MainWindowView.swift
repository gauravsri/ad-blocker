import SwiftUI

public struct MainWindowView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var navigationAction: YouTubeWebView.WebViewAction? = nil

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Custom Native Titlebar & Drag Header
            NativeTitleBar(settings: settings, navigationAction: $navigationAction)

            Divider()

            // Main Content Area (Sidebar + Web Player)
            HStack(spacing: 0) {
                if settings.isSidebarVisible {
                    SidebarView(settings: settings, navigationAction: $navigationAction)
                    Divider()
                }

                // YouTube WebKit Player
                YouTubeWebView(settings: settings, navigationAction: $navigationAction)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $settings.isShowingCaptions) {
            CaptionViewerSheet(settings: settings, navigationAction: $navigationAction)
        }
        .sheet(isPresented: $settings.isShowingSettings) {
            SettingsSheetView(settings: settings)
        }
    }
}

public struct SettingsSheetView: View {
    @ObservedObject var settings: AppSettings

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AdBlocker Preferences")
                    .font(.headline)
                Spacer()
                Button(action: { settings.isShowingSettings = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Ad Blocking")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Toggle("Enable Declarative Network & CSS Ad Blocker", isOn: $settings.blockAds)
                Text("Blocks third-party ad networks (DoubleClick, Google Ad Services) and injects declarative rules hiding promoted video units.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                    Text("Total Ads Neutralized: \(settings.adBlockedCount)")
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Distraction-Free Video Experience")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Toggle("Hide Shorts from feeds and sidebar", isOn: $settings.hideShorts)
                Toggle("Hide video comments section", isOn: $settings.hideComments)
                Toggle("Hide floating end-screen cards", isOn: $settings.hideEndCards)
                Toggle("True OLED Cinema Mode (Pure Black Canvas)", isOn: $settings.cinemaMode)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Window & PiP")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Toggle("Always On Top (Floating Picture-in-Picture)", isOn: $settings.isAlwaysOnTop)
                    .onChange(of: settings.isAlwaysOnTop) { newValue in
                        if let window = NSApplication.shared.windows.first {
                            FloatingPanelController.updateWindowLevel(window, isAlwaysOnTop: newValue)
                        }
                    }
                Text("Locks window to 16:9 widescreen ratio and keeps it floating above all desktop applications.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(width: 440, height: 480)
    }
}
