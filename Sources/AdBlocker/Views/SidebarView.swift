import SwiftUI

public struct SidebarView: View {
    @ObservedObject var settings: AppSettings
    @Binding var navigationAction: YouTubeWebView.WebViewAction?
    @State private var selectedTab: String = "home"

    public init(settings: AppSettings, navigationAction: Binding<YouTubeWebView.WebViewAction?>) {
        self.settings = settings
        self._navigationAction = navigationAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Links
            List {
                Section("Discover") {
                    Button(action: {
                        selectedTab = "home"
                        navigationAction = .load(URL(string: "https://www.youtube.com")!)
                    }) {
                        Label("Home", systemImage: "house")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        selectedTab = "subscriptions"
                        navigationAction = .load(URL(string: "https://www.youtube.com/feed/subscriptions")!)
                    }) {
                        Label("Subscriptions", systemImage: "play.rectangle.on.rectangle")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        selectedTab = "trending"
                        navigationAction = .load(URL(string: "https://www.youtube.com/feed/trending")!)
                    }) {
                        Label("Trending", systemImage: "flame")
                    }
                    .buttonStyle(.plain)
                }

                Section("Bookmarks (\(settings.bookmarks.count))") {
                    if settings.bookmarks.isEmpty {
                        Text("No bookmarks yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settings.bookmarks) { item in
                            HStack {
                                Button(action: {
                                    if let url = URL(string: item.urlString) {
                                        navigationAction = .load(url)
                                    }
                                }) {
                                    Text(item.title)
                                        .lineLimit(1)
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(action: { settings.removeBookmark(id: item.id) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("History") {
                    if settings.history.isEmpty {
                        Text("No watch history")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Text("Recent")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear") {
                                settings.clearHistory()
                            }
                            .font(.caption2)
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }

                        ForEach(settings.history.prefix(15)) { item in
                            Button(action: {
                                if let url = URL(string: item.urlString) {
                                    navigationAction = .load(url)
                                }
                            }) {
                                Text(item.title)
                                    .lineLimit(1)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Distraction Controls") {
                    Toggle("Block Video & Banner Ads", isOn: $settings.blockAds)
                        .font(.system(size: 12))
                    Toggle("Hide Shorts", isOn: $settings.hideShorts)
                        .font(.system(size: 12))
                    Toggle("Hide Comments", isOn: $settings.hideComments)
                        .font(.system(size: 12))
                    Toggle("Hide End Cards", isOn: $settings.hideEndCards)
                        .font(.system(size: 12))
                    Toggle("Cinema Mode", isOn: $settings.cinemaMode)
                        .font(.system(size: 12))
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
    }
}
