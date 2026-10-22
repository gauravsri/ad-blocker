import AppKit

public enum FloatingPanelController {

    public static func configureWindow(_ window: NSWindow, isAlwaysOnTop: Bool) {
        window.isMovableByWindowBackground = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbar = nil

        updateWindowLevel(window, isAlwaysOnTop: isAlwaysOnTop)
    }

    public static func updateWindowLevel(_ window: NSWindow, isAlwaysOnTop: Bool) {
        if isAlwaysOnTop {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.contentAspectRatio = NSSize(width: 16, height: 9)
        } else {
            window.level = .normal
            window.collectionBehavior = [.managed, .participatesInCycle]
            window.resizeIncrements = NSSize(width: 1, height: 1)
        }
    }
}
