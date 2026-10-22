import SwiftUI
import AppKit

public struct CaptionViewerSheet: View {
    @ObservedObject var settings: AppSettings
    @Binding var navigationAction: YouTubeWebView.WebViewAction?
    @State private var filterText: String = ""

    public init(settings: AppSettings, navigationAction: Binding<YouTubeWebView.WebViewAction?>) {
        self.settings = settings
        self._navigationAction = navigationAction
    }

    private var filteredCaptions: [CaptionLine] {
        if filterText.isEmpty {
            return settings.currentCaptions
        }
        return settings.currentCaptions.filter {
            $0.text.localizedCaseInsensitiveContains(filterText)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video Transcript")
                        .font(.headline)
                    Text(settings.currentVideoTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: copyTranscript) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.system(size: 11))
                    }

                    Button(action: exportSRT) {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.system(size: 11))
                    }

                    Button(action: { settings.isShowingCaptions = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Filter Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search transcript...", text: $filterText)
                    .textFieldStyle(.plain)
                if !filterText.isEmpty {
                    Button(action: { filterText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Transcript Lines List
            if settings.currentCaptions.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No transcript available for this video.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Text("Transcripts will appear automatically when you start playing a video with captions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredCaptions) { line in
                            Button(action: {
                                navigationAction = .seekTo(line.start)
                            }) {
                                HStack(alignment: .top, spacing: 10) {
                                    Text(line.timestampFormatted)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 44, alignment: .leading)

                                    Text(line.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.primary.opacity(0.001))
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 460, minHeight: 480, idealHeight: 560)
    }

    private func copyTranscript() {
        let fullText = settings.currentCaptions.map { "[\($0.timestampFormatted)] \($0.text)" }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullText, forType: .string)
    }

    private func exportSRT() {
        var srt = ""
        for (i, line) in settings.currentCaptions.enumerated() {
            let startSec = line.start
            let endSec = line.start + max(line.duration, 1.0)

            let sH = Int(startSec) / 3600
            let sM = (Int(startSec) % 3600) / 60
            let sS = Int(startSec) % 60
            let sMs = Int((startSec.truncatingRemainder(dividingBy: 1.0)) * 1000)

            let eH = Int(endSec) / 3600
            let eM = (Int(endSec) % 3600) / 60
            let eS = Int(endSec) % 60
            let eMs = Int((endSec.truncatingRemainder(dividingBy: 1.0)) * 1000)

            srt += "\(i + 1)\n"
            srt += String(format: "%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n", sH, sM, sS, sMs, eH, eM, eS, eMs)
            srt += "\(line.text)\n\n"
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(settings.currentVideoTitle.prefix(30)).srt"
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? srt.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
