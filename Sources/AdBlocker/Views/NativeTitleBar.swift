import SwiftUI
import AppKit

// Dedicated synchronous AppKit drag handle view
public struct WindowDragHandle: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> DragView {
        DragView()
    }

    public func updateNSView(_ nsView: DragView, context: Context) {}

    public final class DragView: NSView {
        public override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

public struct NativeTitleBar: View {
    @ObservedObject var settings: AppSettings
    @Binding var navigationAction: YouTubeWebView.WebViewAction?
    @State private var searchInput: String = ""

    public init(settings: AppSettings, navigationAction: Binding<YouTubeWebView.WebViewAction?>) {
        self.settings = settings
        self._navigationAction = navigationAction
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Traffic Light margin
            Spacer().frame(width: 72)

            // Navigation Controls
            HStack(spacing: 4) {
                Button(action: { navigationAction = .goBack }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .disabled(!settings.canGoBack)
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)

                Button(action: { navigationAction = .goForward }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .disabled(!settings.canGoForward)
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)

                Button(action: {
                    if settings.isLoading {
                        navigationAction = .reload
                    } else {
                        navigationAction = .reload
                    }
                }) {
                    Image(systemName: settings.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)

                Button(action: {
                    navigationAction = .load(URL(string: "https://www.youtube.com")!)
                }) {
                    Image(systemName: "house")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
            }

            // Draggable Spacer left of Search
            WindowDragHandle()
                .frame(width: 16)

            // Search & URL Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("Search or enter YouTube URL...", text: $searchInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit {
                        submitSearch()
                    }
                if !searchInput.isEmpty {
                    Button(action: { searchInput = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )

            // Draggable Spacer right of Search
            WindowDragHandle()
                .frame(minWidth: 10)

            // Shields / Stats Badge
            HStack(spacing: 4) {
                Image(systemName: "shield.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 11))
                Text("\(settings.adBlockedCount)")
                    .font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.12))
            .cornerRadius(6)
            .help("Ads and trackers blocked")

            // Feature Quick-Actions
            HStack(spacing: 6) {
                // Bookmark Current Video
                Button(action: {
                    settings.addBookmark(title: settings.currentVideoTitle, url: settings.currentURLString)
                }) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Bookmark current video")

                // Transcripts / Captions
                Button(action: {
                    settings.isShowingCaptions.toggle()
                }) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 12))
                        .foregroundColor(settings.currentCaptions.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .help("View Captions / Transcript")

                // Cinema Mode
                Button(action: {
                    settings.cinemaMode.toggle()
                }) {
                    Image(systemName: settings.cinemaMode ? "theatermasks.fill" : "theatermasks")
                        .font(.system(size: 12))
                        .foregroundColor(settings.cinemaMode ? .yellow : .primary)
                }
                .buttonStyle(.plain)
                .help("Toggle Cinema Mode")

                // Always on Top (PiP)
                Button(action: {
                    settings.isAlwaysOnTop.toggle()
                    if let window = NSApplication.shared.windows.first {
                        FloatingPanelController.updateWindowLevel(window, isAlwaysOnTop: settings.isAlwaysOnTop)
                    }
                }) {
                    Image(systemName: settings.isAlwaysOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(settings.isAlwaysOnTop ? .orange : .primary)
                }
                .buttonStyle(.plain)
                .help("Toggle Always on Top (Floating PiP)")

                // Settings Sheet
                Button(action: {
                    settings.isShowingSettings.toggle()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Preferences")
            }
            .padding(.trailing, 10)
        }
        .frame(height: 38)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(settings.$currentURLString) { url in
            if !url.contains("youtube.com/results") {
                self.searchInput = url
            }
        }
    }

    private func submitSearch() {
        let trimmed = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            if let url = URL(string: trimmed) {
                navigationAction = .load(url)
            }
        } else if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let searchURL = URL(string: "https://www.youtube.com/results?search_query=\(encoded)") {
            navigationAction = .load(searchURL)
        }
    }
}
