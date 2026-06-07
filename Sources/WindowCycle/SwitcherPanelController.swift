import AppKit
import SwiftUI

@MainActor
final class SwitcherPanelController {
    let model = SwitcherModel()

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 708, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: SwitcherView(model: model))
        return panel
    }()

    var isVisible: Bool {
        panel.isVisible
    }

    func show() {
        resizeToFitContent()
        centerOnActiveScreen()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func resizeToFitContent() {
        let rowHeight: CGFloat = 34
        let verticalPadding: CGFloat = 18
        let minHeight: CGFloat = 82
        let maxHeight: CGFloat = 356
        let targetHeight = model.windows.isEmpty
            ? minHeight
            : min(maxHeight, max(minHeight, verticalPadding + CGFloat(model.windows.count) * rowHeight))

        panel.setContentSize(NSSize(width: 708, height: targetHeight))
    }

    private func centerOnActiveScreen() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let panelFrame = panel.frame
        let origin = NSPoint(
            x: frame.midX - panelFrame.width / 2,
            y: frame.midY - panelFrame.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}
