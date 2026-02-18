import AppKit
import SwiftUI

// MARK: - Panel geometry (shared between panel and SwiftUI)

@Observable
final class PanelGeometry {
    var arrowXOffset: CGFloat = 250
}

// MARK: - Popover shape + container

private let arrowHeight: CGFloat = 10
private let arrowHalfWidth: CGFloat = 10
private let popoverCornerRadius: CGFloat = 12

private struct PopoverArrowShape: Shape {
    var arrowX: CGFloat

    var animatableData: CGFloat {
        get { arrowX }
        set { arrowX = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = popoverCornerRadius
        // Clamp arrow tip so it stays within the rounded corners
        let tipX = max(arrowHalfWidth + r, min(arrowX, rect.width - arrowHalfWidth - r))
        let bodyTop = arrowHeight

        var p = Path()
        // Arrow tip → arrow right base
        p.move(to: CGPoint(x: tipX, y: 0))
        p.addLine(to: CGPoint(x: tipX + arrowHalfWidth, y: bodyTop))
        // Top-right corner
        p.addLine(to: CGPoint(x: rect.width - r, y: bodyTop))
        p.addArc(center: CGPoint(x: rect.width - r, y: bodyTop + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // Right edge → bottom-right corner
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - r))
        p.addArc(center: CGPoint(x: rect.width - r, y: rect.height - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // Bottom → bottom-left corner
        p.addLine(to: CGPoint(x: r, y: rect.height))
        p.addArc(center: CGPoint(x: r, y: rect.height - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        // Left edge → top-left corner
        p.addLine(to: CGPoint(x: 0, y: bodyTop + r))
        p.addArc(center: CGPoint(x: r, y: bodyTop + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        // Arrow left base → back to tip
        p.addLine(to: CGPoint(x: tipX - arrowHalfWidth, y: bodyTop))
        p.closeSubpath()
        return p
    }
}

struct PopoverContainer<Content: View>: View {
    let geometry: PanelGeometry
    @ViewBuilder let content: () -> Content

    var body: some View {
        PopoverArrowShape(arrowX: geometry.arrowXOffset)
            .fill(Color(NSColor.windowBackgroundColor))
            .overlay(alignment: .top) {
                content()
                    .padding(.top, arrowHeight)
                    .clipShape(PopoverArrowShape(arrowX: geometry.arrowXOffset))
            }
    }
}

// MARK: - FloatingPanel

class FloatingPanel: NSPanel {
    let geometry = PanelGeometry()

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isMovableByWindowBackground = false
        backgroundColor = .clear
        isOpaque = false
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(
            rootView: PopoverContainer(geometry: geometry) { contentView }
        )
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
            geometry.arrowXOffset = frame.width / 2
            showFallbackCentered()
            return
        }

        let buttonFrame = buttonWindow.frame
        let x = buttonFrame.midX - frame.width / 2
        let y = buttonFrame.minY - frame.height
        let origin = clampToScreen(NSPoint(x: x, y: y))

        // Arrow tip points at the center of the status item icon
        geometry.arrowXOffset = buttonFrame.midX - origin.x

        setFrameOrigin(origin)
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
