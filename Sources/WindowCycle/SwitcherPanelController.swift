import AppKit
import SwiftUI

@MainActor
final class SwitcherPanelController {
    let model = SwitcherModel()

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 614, height: 150),
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
        positionNearTopOfActiveScreen()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func resizeToFitContent() {
        let rowHeight: CGFloat = 28
        let verticalPadding: CGFloat = 14
        let minHeight: CGFloat = 66
        let maxHeight: CGFloat = 294
        let targetHeight = model.windows.isEmpty
            ? minHeight
            : min(maxHeight, max(minHeight, verticalPadding + CGFloat(model.windows.count) * rowHeight))

        panel.setContentSize(NSSize(width: 614, height: targetHeight))
    }

    private func positionNearTopOfActiveScreen() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let panelFrame = panel.frame
        let topMargin = min(max(frame.height * 0.16, 88), 160)
        let origin = NSPoint(
            x: frame.midX - panelFrame.width / 2,
            y: frame.maxY - panelFrame.height - topMargin
        )
        panel.setFrameOrigin(origin)
    }
}
