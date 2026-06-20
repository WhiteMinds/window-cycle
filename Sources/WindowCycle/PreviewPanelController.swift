import AppKit
import SwiftUI

/// A standalone floating panel that shows a single preview of the currently
/// selected window. It lives beside the switcher list panel and never affects
/// the list panel's size or layout. Used only in "selected window only" mode.
@MainActor
final class PreviewPanelController {
    private let model: SwitcherModel
    private let settings: PreviewSettings

    init(model: SwitcherModel, settings: PreviewSettings) {
        self.model = model
        self.settings = settings
    }

    private var contentSize: NSSize {
        let pane = settings.size.paneSize
        return NSSize(
            width: pane.width + PreviewMetrics.panePadding * 2,
            height: pane.height + PreviewMetrics.panePadding * 2
        )
    }

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
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
        panel.contentView = NSHostingView(
            rootView: SelectedWindowPreviewView(model: model, settings: settings)
        )
        return panel
    }()

    var isVisible: Bool {
        panel.isVisible
    }

    /// Positions the panel next to `switcherFrame` on the given side and shows
    /// it. Clamps to the active screen so it always stays on-screen.
    func show(relativeTo switcherFrame: NSRect, on side: PreviewPosition) {
        panel.setContentSize(contentSize)
        let size = panel.frame.size
        let gap = PreviewMetrics.paneGap

        var origin: NSPoint
        switch side {
        case .left:
            // Beside the list, top edges aligned.
            origin = NSPoint(x: switcherFrame.minX - gap - size.width, y: switcherFrame.maxY - size.height)
        case .right:
            origin = NSPoint(x: switcherFrame.maxX + gap, y: switcherFrame.maxY - size.height)
        case .top:
            // Above the list, horizontally centered on it.
            origin = NSPoint(x: switcherFrame.midX - size.width / 2, y: switcherFrame.maxY + gap)
        case .bottom:
            origin = NSPoint(x: switcherFrame.midX - size.width / 2, y: switcherFrame.minY - gap - size.height)
        }

        if let visible = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - size.height)
        }

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}

/// SwiftUI content for the standalone preview panel. Observes the model so the
/// image updates as the selection changes, without re-showing the panel.
private struct SelectedWindowPreviewView: View {
    @ObservedObject var model: SwitcherModel
    @ObservedObject var settings: PreviewSettings

    var body: some View {
        WindowPreview(
            image: model.selectedWindow.flatMap { model.thumbnail(for: $0) },
            appIcon: model.selectedWindow?.appIcon
        )
        .frame(width: settings.size.paneSize.width, height: settings.size.paneSize.height)
        .padding(PreviewMetrics.panePadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
