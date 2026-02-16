import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.nonactivatingPanel, .titled, .closable],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .windowBackgroundColor
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView

        let size = NSSize(width: 500, height: 400)
        setContentSize(size)
        minSize = size
        maxSize = size
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    func showBelow(statusItem: NSStatusItem) {
        guard let buttonWindow = statusItem.button?.window else {
            showFallbackCentered()
            return
        }

        let buttonFrame = buttonWindow.frame
        // Center horizontally under the status item, panel top edge flush with menu bar bottom
        let x = buttonFrame.midX - frame.width / 2
        let y = buttonFrame.minY - frame.height
        setFrameOrigin(clampToScreen(NSPoint(x: x, y: y)))
        makeKeyAndOrderFront(nil)
    }

    private func showFallbackCentered() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        let y = screenFrame.midY - frame.height / 2
        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
    }

    /// Keep the panel fully on-screen
    private func clampToScreen(_ origin: NSPoint) -> NSPoint {
        guard let screen = NSScreen.main else { return origin }
        let visibleFrame = screen.visibleFrame
        var x = origin.x
        var y = origin.y

        // Clamp horizontally
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - frame.width))
        // Clamp vertically (don't go below dock/visible area)
        y = max(visibleFrame.minY, y)

        return NSPoint(x: x, y: y)
    }
}
