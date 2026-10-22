import SwiftUI
import Combine

public struct CaptionLine: Identifiable, Codable, Equatable {
    public var id = UUID()
    public let start: Double
    public let duration: Double
    public let text: String

    public var timestampFormatted: String {
        let totalSeconds = Int(start)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

public struct VideoItem: Identifiable, Codable, Equatable {
    public var id = UUID()
    public let title: String
    public let urlString: String
    public let timestamp: Date

    public init(title: String, urlString: String, timestamp: Date = Date()) {
        self.title = title
        self.urlString = urlString
        self.timestamp = timestamp
    }
}

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    // Feature Toggles (backed by UserDefaults)
    @Published public var blockAds: Bool {
        didSet { UserDefaults.standard.set(blockAds, forKey: "blockAds") }
    }
    @Published public var hideShorts: Bool {
        didSet { UserDefaults.standard.set(hideShorts, forKey: "hideShorts") }
    }
    @Published public var hideComments: Bool {
        didSet { UserDefaults.standard.set(hideComments, forKey: "hideComments") }
    }
    @Published public var hideEndCards: Bool {
        didSet { UserDefaults.standard.set(hideEndCards, forKey: "hideEndCards") }
    }
    @Published public var cinemaMode: Bool {
        didSet { UserDefaults.standard.set(cinemaMode, forKey: "cinemaMode") }
    }
    @Published public var isAlwaysOnTop: Bool {
        didSet { UserDefaults.standard.set(isAlwaysOnTop, forKey: "isAlwaysOnTop") }
    }
    @Published public var adBlockedCount: Int {
        didSet { UserDefaults.standard.set(adBlockedCount, forKey: "adBlockedCount") }
    }

    // Active Runtime State
    @Published public var currentURLString: String = "https://www.youtube.com"
    @Published public var currentVideoTitle: String = "YouTube"
    @Published public var currentCaptions: [CaptionLine] = []
    @Published public var isShowingCaptions: Bool = false
    @Published public var isShowingSettings: Bool = false
    @Published public var isSidebarVisible: Bool = true
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var isLoading: Bool = false

    // Library Data
    @Published public var bookmarks: [VideoItem] = []
    @Published public var history: [VideoItem] = []

    private let libraryURL: URL

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "blockAds": true,
            "hideShorts": true,
            "hideComments": false,
            "hideEndCards": true,
            "cinemaMode": false,
            "isAlwaysOnTop": false,
            "adBlockedCount": 0
        ])

        self.blockAds = defaults.bool(forKey: "blockAds")
        self.hideShorts = defaults.bool(forKey: "hideShorts")
        self.hideComments = defaults.bool(forKey: "hideComments")
        self.hideEndCards = defaults.bool(forKey: "hideEndCards")
        self.cinemaMode = defaults.bool(forKey: "cinemaMode")
        self.isAlwaysOnTop = defaults.bool(forKey: "isAlwaysOnTop")
        self.adBlockedCount = defaults.integer(forKey: "adBlockedCount")

        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("com.antigravity.adblocker", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.libraryURL = appDir.appendingPathComponent("library.json")

        loadLibrary()
    }

    public func incrementBlockedAds(by count: Int = 1) {
        self.adBlockedCount += count
    }

    public func addBookmark(title: String, url: String) {
        guard !bookmarks.contains(where: { $0.urlString == url }) else { return }
        bookmarks.insert(VideoItem(title: title, urlString: url), at: 0)
        saveLibrary()
    }

    public func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        saveLibrary()
    }

    public func addHistory(title: String, url: String) {
        guard !url.isEmpty, url != "https://www.youtube.com" else { return }
        history.removeAll { $0.urlString == url }
        history.insert(VideoItem(title: title, urlString: url), at: 0)
        if history.count > 200 { history.removeLast() }
        saveLibrary()
    }

    public func clearHistory() {
        history.removeAll()
        saveLibrary()
    }

    private struct LibraryContainer: Codable {
        let bookmarks: [VideoItem]
        let history: [VideoItem]
    }

    private func saveLibrary() {
        do {
            let container = LibraryContainer(bookmarks: bookmarks, history: history)
            let data = try JSONEncoder().encode(container)
            try data.write(to: libraryURL, options: .atomic)
        } catch {
            print("[Storage] Failed to save library: \(error)")
        }
    }

    private func loadLibrary() {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else { return }
        do {
            let data = try Data(contentsOf: libraryURL)
            let container = try JSONDecoder().decode(LibraryContainer.self, from: data)
            self.bookmarks = container.bookmarks
            self.history = container.history
        } catch {
            print("[Storage] Failed to load library: \(error)")
        }
    }
}
