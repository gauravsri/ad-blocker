# YouTube Ad Blocker (Native macOS)

A lightweight, bloat-free, high-performance native macOS YouTube desktop client with built-in ad blocking, distraction-free controls, floating Picture-in-Picture, and instant subtitle/transcript extraction.

Reverse-engineered from commercial macOS adblocker wrappers using **REA (Reverse Engineer Anything)** and re-architected via the **Deliberation Council** to eliminate fragile DOM hacks, predatory subscription paywalls, and telemetry.

---

## Features

- **Multi-Tier Ad Blocking:**
  - **Tier 1 (Declarative C++ Engine):** Compiles native `WKContentRuleList` rules dropping third-party tracking/ad domains (`doubleclick.net`, `googlesyndication.com`, `googleadservices.com`, `pubads.g.doubleclick.net`) and hiding ad elements via `css-display-none` before page paint.
  - **Tier 2 (Payload Sanitization):** Injected at `.atDocumentStart` in `WKContentWorld.page` to strip `adPlacements` and `playerAds` directly from `window.ytInitialPlayerResponse` and `/youtubei/v1/player` fetch payloads.
  - **Tier 3 (Failsafe In-Stream Mute & Fast-Forward):** Automatically mutes audio and accelerates playback cleanly if an unskippable video ad ever renders, without force-mutating `currentTime` (preventing player black-screen FSM crashes).
- **Distraction-Free Controls:**
  - **Hide Shorts:** Removes Shorts shelves (`grid-shelf-view-model`, `ytd-reel-shelf-renderer`, `ytd-rich-shelf-renderer[is-shorts]`) and navigation tabs.
  - **Hide Comments:** Removes the video comments section (`ytd-comments#comments`).
  - **Hide End Cards:** Hides intrusive floating video cards (`.ytp-ce-element`).
  - **True OLED Cinema Mode:** Pitch-black background (`#000000`), hiding chat, sidebars, and below-video metadata. Press `F` or `Cmd+F` to toggle.
- **Floating Picture-in-Picture (Always on Top):**
  - Toggles `.floating` window level and locks resizing to a **16:9 widescreen aspect ratio** without letterboxing.
  - Includes a dedicated native AppKit drag header that never interferes with the video scrubber or player controls. Press `Cmd+Shift+P` to toggle.
- **Instant Transcript & Captions Viewer:**
  - Extracts YouTube's native timed-text subtitles in <50ms with 0% CPU overhead (bypassing macOS Screen Recording TCC permission prompts).
  - Searchable transcript with one-click timestamp seeking, clipboard copying, and `.srt` subtitle file export. Press `Cmd+T` to toggle.
- **Local Persistence:**
  - Watch History and Bookmarks saved locally to `~/Library/Application Support/com.antigravity.adblocker/library.json`.

---

## Quick Start

### Build & Run

```bash
# Clone or navigate to the workspace
cd /Users/gaurav/workspace/claude/ad-blocker

# Fast build & launch
./run.sh
```

Or using Swift Package Manager directly:

```bash
swift run -c release
```

---

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Cmd + F` or `F` | Toggle OLED Cinema Mode |
| `Cmd + Shift + P` | Toggle Always-on-Top Floating PiP (16:9) |
| `Cmd + T` | Open Video Transcript & Subtitle Viewer |
| `Cmd + Left / Right` | History Back / Forward |
| `Cmd + R` | Reload Web Player |
