import Foundation

public enum PlayerDefuserScript {

    /// Script injected at `.atDocumentStart` in `WKContentWorld.page`
    /// Intercepts YouTube's initial bootstrap data and fetch requests before the player starts.
    public static var coreDefuserScript: String {
        """
        (function() {
            if (window.__antigravityDefuserInstalled) return;
            window.__antigravityDefuserInstalled = true;

            // 1. Sanitize adPlacements from ytInitialPlayerResponse
            function sanitizePlayerResponse(resp) {
                if (!resp || typeof resp !== 'object') return resp;
                if (resp.adPlacements) {
                    delete resp.adPlacements;
                }
                if (resp.playerAds) {
                    delete resp.playerAds;
                }
                if (resp.adSlots) {
                    delete resp.adSlots;
                }
                // Check for caption tracks and notify host
                try {
                    const captions = resp?.captions?.playerCaptionsTracklistRenderer?.captionTracks;
                    if (captions && captions.length > 0 && window.webkit?.messageHandlers?.captionsHandler) {
                        window.webkit.messageHandlers.captionsHandler.postMessage({
                            tracks: captions
                        });
                    }
                } catch(e) {}

                return resp;
            }

            let initialPlayerResponse = window.ytInitialPlayerResponse;
            Object.defineProperty(window, 'ytInitialPlayerResponse', {
                configurable: true,
                enumerable: true,
                get: function() { return initialPlayerResponse; },
                set: function(val) {
                    initialPlayerResponse = sanitizePlayerResponse(val);
                }
            });

            // 2. Intercept window.fetch for /youtubei/v1/player requests
            const originalFetch = window.fetch;
            window.fetch = async function(...args) {
                const response = await originalFetch.apply(this, args);
                try {
                    const url = typeof args[0] === 'string' ? args[0] : (args[0]?.url || '');
                    if (url.includes('/youtubei/v1/player')) {
                        const clone = response.clone();
                        const json = await clone.json();
                        const sanitized = sanitizePlayerResponse(json);
                        return new Response(JSON.stringify(sanitized), {
                            status: response.status,
                            statusText: response.statusText,
                            headers: response.headers
                        });
                    }
                } catch(e) {}
                return response;
            };

            // 3. Failsafe In-Stream Ad Neutralizer
            // When an ad slipstream occurs, mute immediately and fast-forward cleanly
            let previousRate = 1.0;
            let adActive = false;

            function checkAdStatus() {
                const player = document.querySelector('.html5-video-player');
                const video = document.querySelector('video');
                if (!player || !video) return;

                const isAdShowing = player.classList.contains('ad-showing') || player.classList.contains('ad-interrupting');
                if (isAdShowing) {
                    if (!adActive) {
                        adActive = true;
                        previousRate = video.playbackRate || 1.0;
                        video.muted = true;
                        video.playbackRate = 8.0;

                        if (window.webkit?.messageHandlers?.adBlockedStatsHandler) {
                            window.webkit.messageHandlers.adBlockedStatsHandler.postMessage({ blocked: 1 });
                        }
                    }

                    // Auto-click close overlay buttons if present
                    const closeBtn = document.querySelector('.ytp-ad-overlay-close-button, .ytp-ad-skip-button-modern');
                    if (closeBtn) closeBtn.click();
                } else if (adActive) {
                    adActive = false;
                    video.playbackRate = previousRate || 1.0;
                }
            }

            const adObserver = new MutationObserver(checkAdStatus);
            document.addEventListener('DOMContentLoaded', () => {
                const target = document.querySelector('.html5-video-player') || document.body;
                if (target) {
                    adObserver.observe(target, { attributes: true, attributeFilter: ['class'], subtree: true });
                }
                setInterval(checkAdStatus, 500);
            });

            // 4. Intercept 'f' key for Cinema / Fullscreen override
            document.addEventListener('keydown', function(e) {
                if (e.key.toLowerCase() !== 'f') return;
                if (e.ctrlKey || e.metaKey || e.altKey || e.shiftKey) return;
                const active = document.activeElement;
                const isEditable = active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable);
                if (isEditable) return;

                e.preventDefault();
                e.stopPropagation();
                if (window.webkit?.messageHandlers?.fKeyPressHandler) {
                    window.webkit.messageHandlers.fKeyPressHandler.postMessage({});
                }
            }, true);

            // 5. Intercept context menu on links
            document.addEventListener('contextmenu', function(e) {
                const link = e.target.closest('a');
                if (link && link.href && window.webkit?.messageHandlers?.contextMenuHandler) {
                    window.webkit.messageHandlers.contextMenuHandler.postMessage({
                        url: link.href,
                        title: link.innerText || link.title || ''
                    });
                }
            }, true);
        })();
        """
    }

    /// Script to apply live user preferences (Shorts, Comments, End Cards, Cinema Mode)
    public static func buildPreferenceScript(
        hideShorts: Bool,
        hideComments: Bool,
        hideEndCards: Bool,
        cinemaMode: Bool
    ) -> String {
        return """
        (function() {
            // Shorts Toggle
            const hideShorts = \(hideShorts);
            document.querySelectorAll("grid-shelf-view-model, ytd-reel-shelf-renderer, ytd-rich-shelf-renderer[is-shorts], a#endpoint[title='Shorts']").forEach(el => {
                el.style.display = hideShorts ? 'none' : '';
            });

            // Comments Toggle
            const hideComments = \(hideComments);
            const commentsSection = document.querySelector('ytd-comments#comments');
            if (commentsSection) {
                commentsSection.style.display = hideComments ? 'none' : '';
            }

            // End Cards Toggle
            const hideEndCards = \(hideEndCards);
            document.querySelectorAll('.ytp-ce-element, .ytp-ce-element-container, .ytp-ce-hide-button-container').forEach(el => {
                el.style.display = hideEndCards ? 'none' : '';
            });

            // Cinema Mode
            const cinema = \(cinemaMode);
            const below = document.querySelector('#below');
            const chat = document.querySelector('#chat-container');
            const masthead = document.querySelector('#masthead-container');
            if (below) below.style.display = cinema ? 'none' : '';
            if (chat) chat.style.display = cinema ? 'none' : '';
            if (masthead) masthead.style.opacity = cinema ? '0.1' : '1.0';
            document.body.style.backgroundColor = cinema ? '#000000' : '';
        })();
        """
    }

    /// Script to seek the video to a specific timestamp
    public static func seekToScript(seconds: Double) -> String {
        return """
        (function() {
            const video = document.querySelector('video');
            if (video) {
                video.currentTime = \(seconds);
                video.play();
            }
        })();
        """
    }

    /// Script to fetch and parse subtitle XML/JSON from a caption track URL
    public static func fetchCaptionsScript(trackURL: String) -> String {
        return """
        (async function() {
            try {
                const res = await fetch('\(trackURL)&fmt=json3');
                const data = await res.json();
                const lines = [];
                if (data && data.events) {
                    for (const ev of data.events) {
                        if (ev.segs && ev.tStartMs !== undefined) {
                            const text = ev.segs.map(s => s.utf8).join('').trim();
                            if (text) {
                                lines.push({
                                    start: ev.tStartMs / 1000.0,
                                    duration: (ev.dDurationMs || 0) / 1000.0,
                                    text: text
                                });
                            }
                        }
                    }
                }
                if (window.webkit?.messageHandlers?.captionsDataHandler) {
                    window.webkit.messageHandlers.captionsDataHandler.postMessage({ lines: lines });
                }
            } catch(e) {
                console.error('Failed to parse captions:', e);
            }
        })();
        """
    }
}
