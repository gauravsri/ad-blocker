import Foundation
import WebKit

public enum ContentRuleBuilder {
    public static let ruleListIdentifier = "com.antigravity.adblocker.rules"

    public static func buildRuleListJSON() -> String {
        let json: [[String: Any]] = [
            // 1. Declarative CSS Element Hiding (Native WebKit C++ layout engine, zero JS overhead)
            [
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": ["*youtube.com"]
                ],
                "action": [
                    "type": "css-display-none",
                    "selector": """
                    .ytd-ad-slot-renderer,
                    ytd-in-feed-ad-layout-renderer,
                    #masthead-ad,
                    ytd-banner-promo-renderer,
                    ytd-statement-banner-renderer,
                    .ytp-ad-overlay-container,
                    .ytp-ad-message-container,
                    .ytp-ad-action-interstitial,
                    .ytd-merch-shelf-renderer,
                    ytd-engagement-panel-section-list-renderer[target-id='engagement-panel-ads'],
                    ytd-ad-slot-renderer,
                    .ytd-player-legacy-desktop-watch-ads-renderer,
                    ytd-promoted-sparkles-web-renderer,
                    ytd-promoted-video-renderer
                    """
                ]
            ],
            // 2. Third-Party Tracker & Ad Network Blockers (Do not block youtube.com/videoplayback directly to avoid FSM crashes)
            [
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": [
                        "*doubleclick.net",
                        "*googleadservices.com",
                        "*googlesyndication.com",
                        "*adservice.google.com",
                        "*pubads.g.doubleclick.net"
                    ]
                ],
                "action": [
                    "type": "block"
                ]
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }

        return "[]"
    }

    public static func compileRules(completion: @escaping (WKContentRuleList?) -> Void) {
        guard let store = WKContentRuleListStore.default() else {
            print("[ContentRuleBuilder] Failed to access default WKContentRuleListStore.")
            completion(nil)
            return
        }
        let rulesJSON = buildRuleListJSON()

        store.compileContentRuleList(forIdentifier: ruleListIdentifier, encodedContentRuleList: rulesJSON) { ruleList, error in
            if let error = error {
                print("[ContentRuleBuilder] Rule compilation error: \(error.localizedDescription)")
            } else {
                print("[ContentRuleBuilder] Rules successfully compiled into WebKit bytecode.")
            }
            completion(ruleList)
        }
    }
}
