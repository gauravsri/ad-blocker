import SwiftUI
import WebKit

public struct YouTubeWebView: NSViewRepresentable {
    @ObservedObject var settings: AppSettings
    @Binding var navigationAction: WebViewAction?

    public enum WebViewAction {
        case goBack
        case goForward
        case reload
        case load(URL)
        case seekTo(Double)
        case togglePlayPause
    }

    public init(settings: AppSettings, navigationAction: Binding<WebViewAction?>) {
        self.settings = settings
        self._navigationAction = navigationAction
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // 1. Core Defuser Script (runs before page loads)
        let coreScript = WKUserScript(
            source: PlayerDefuserScript.coreDefuserScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false,
            in: .page
        )
        userContentController.addUserScript(coreScript)

        // 2. Message Handlers
        userContentController.add(context.coordinator, contentWorld: .page, name: "captionsHandler")
        userContentController.add(context.coordinator, contentWorld: .page, name: "captionsDataHandler")
        userContentController.add(context.coordinator, contentWorld: .page, name: "adBlockedStatsHandler")
        userContentController.add(context.coordinator, contentWorld: .page, name: "fKeyPressHandler")
        userContentController.add(context.coordinator, contentWorld: .page, name: "contextMenuHandler")

        // 3. Declarative Content Rules
        ContentRuleBuilder.compileRules { ruleList in
            if let ruleList = ruleList {
                userContentController.add(ruleList)
            }
        }

        config.userContentController = userContentController
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsMagnification = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"

        context.coordinator.webView = webView

        if let initialURL = URL(string: settings.currentURLString) {
            webView.load(URLRequest(url: initialURL))
        }

        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // Execute pending navigation actions
        if let action = navigationAction {
            switch action {
            case .goBack:
                if nsView.canGoBack { nsView.goBack() }
            case .goForward:
                if nsView.canGoForward { nsView.goForward() }
            case .reload:
                nsView.reload()
            case .load(let url):
                nsView.load(URLRequest(url: url))
            case .seekTo(let seconds):
                nsView.evaluateJavaScript(PlayerDefuserScript.seekToScript(seconds: seconds), completionHandler: nil)
            case .togglePlayPause:
                nsView.evaluateJavaScript("document.querySelector('video')?.paused ? document.querySelector('video')?.play() : document.querySelector('video')?.pause();", completionHandler: nil)
            }

            DispatchQueue.main.async {
                self.navigationAction = nil
            }
        }

        // Apply updated user preferences to live DOM
        let prefScript = PlayerDefuserScript.buildPreferenceScript(
            hideShorts: settings.hideShorts,
            hideComments: settings.hideComments,
            hideEndCards: settings.hideEndCards,
            cinemaMode: settings.cinemaMode
        )
        nsView.evaluateJavaScript(prefScript, completionHandler: nil)
    }

    public final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandlerWithReply, WKScriptMessageHandler {
        var parent: YouTubeWebView
        weak var webView: WKWebView?

        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }

        // MARK: - Script Messages
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            let name = message.name
            guard let body = message.body as? [String: Any] else { return }

            Task { @MainActor in
                switch name {
                case "adBlockedStatsHandler":
                    if let blocked = body["blocked"] as? Int {
                        self.parent.settings.incrementBlockedAds(by: blocked)
                    }
                case "captionsHandler":
                    if let tracks = body["tracks"] as? [[String: Any]],
                       let firstTrack = tracks.first,
                       let baseUrl = firstTrack["baseUrl"] as? String {
                        self.webView?.evaluateJavaScript(PlayerDefuserScript.fetchCaptionsScript(trackURL: baseUrl), completionHandler: nil)
                    }
                case "captionsDataHandler":
                    if let linesData = body["lines"] as? [[String: Any]] {
                        var parsed: [CaptionLine] = []
                        for item in linesData {
                            if let start = item["start"] as? Double,
                               let duration = item["duration"] as? Double,
                               let text = item["text"] as? String {
                                parsed.append(CaptionLine(start: start, duration: duration, text: text))
                            }
                        }
                        self.parent.settings.currentCaptions = parsed
                    }
                case "fKeyPressHandler":
                    self.parent.settings.cinemaMode.toggle()
                default:
                    break
                }
            }
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
            return (nil, nil)
        }

        // MARK: - Navigation Delegate
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                self.parent.settings.isLoading = true
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                self.parent.settings.isLoading = false
                self.parent.settings.canGoBack = webView.canGoBack
                self.parent.settings.canGoForward = webView.canGoForward

                if let currentURL = webView.url?.absoluteString {
                    self.parent.settings.currentURLString = currentURL
                    let title = webView.title ?? "YouTube"
                    self.parent.settings.currentVideoTitle = title
                    self.parent.settings.addHistory(title: title, url: currentURL)
                }

                // Re-apply preferences to freshly loaded page
                let prefScript = PlayerDefuserScript.buildPreferenceScript(
                    hideShorts: self.parent.settings.hideShorts,
                    hideComments: self.parent.settings.hideComments,
                    hideEndCards: self.parent.settings.hideEndCards,
                    cinemaMode: self.parent.settings.cinemaMode
                )
                webView.evaluateJavaScript(prefScript, completionHandler: nil)
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                self.parent.settings.isLoading = false
            }
        }

        // MARK: - UI Delegate
        public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Open links clicked with target="_blank" inside the same web view
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
