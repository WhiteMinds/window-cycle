import AppKit
import SwiftUI

@MainActor
final class SwitcherPanelController {
    let model = SwitcherModel()
    let settings: PreviewSettings
    private let onActivateSelected: () -> Void
    private lazy var previewPanelController = PreviewPanelController(model: model, settings: settings)

    init(settings: PreviewSettings, onActivateSelected: @escaping () -> Void) {
        self.settings = settings
        self.onActivateSelected = onActivateSelected
    }

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
        panel.acceptsMouseMovedEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(
            rootView: SwitcherView(
                model: model,
                settings: settings,
                onActivateSelected: onActivateSelected
            )
        )
        return panel
    }()

    var isVisible: Bool {
        panel.isVisible
    }

    func show() {
        resizeToFitContent()
        positionNearTopOfActiveScreen()
        panel.orderFrontRegardless()
        updatePreviewPanel()
    }

    func hide() {
        panel.orderOut(nil)
        previewPanelController.hide()
    }

    /// Shows or hides the standalone selected-window preview panel beside the
    /// list. The list panel's own size is never affected by previews.
    private func updatePreviewPanel() {
        let shouldShow = settings.isEnabled
            && settings.mode == .selectedOnly
            && !model.windows.isEmpty
            && ScreenRecordingPermission.isGranted()

        if shouldShow {
            previewPanelController.show(relativeTo: panel.frame, on: settings.position)
        } else {
            previewPanelController.hide()
        }
    }

    private func resizeToFitContent() {
        panel.setContentSize(targetContentSize())
    }

    /// Computes the list panel size for the current window count. Only the
    /// "all windows" mode changes row height; width is always the list width.
    private func targetContentSize() -> NSSize {
        let count = model.windows.count
        let allMode = settings.isEnabled && count > 0 && settings.mode == .all

        let outerPadding = PreviewMetrics.verticalPadding * 2
        let rowStride = (allMode ? settings.size.rowHeight : PreviewMetrics.baseRowHeight)
            + PreviewMetrics.rowSpacing
        let minHeight: CGFloat = 66
        let maxHeight: CGFloat = allMode ? 760 : 294

        let height = count == 0
            ? minHeight
            : min(maxHeight, max(minHeight, outerPadding + CGFloat(count) * rowStride))
        let width = PreviewMetrics.listWidth + PreviewMetrics.horizontalPadding * 2

        return NSSize(width: width, height: height)
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
