import SwiftUI
import AppKit

/// Shared layout constants used by `SwitcherView`, `SwitcherPanelController`,
/// and `PreviewPanelController` so panels can size and position to match.
enum PreviewMetrics {
    /// Inner width of the window list column.
    static let listWidth: CGFloat = 590
    /// Horizontal padding applied on each side of the panel content.
    static let horizontalPadding: CGFloat = 12
    /// Vertical padding applied above and below the panel content.
    static let verticalPadding: CGFloat = 7
    /// Size of the single large preview in "selected window only" mode.
    static let paneSize = CGSize(width: 260, height: 168)
    /// Padding around the preview inside its standalone panel.
    static let panePadding: CGFloat = 8
    /// Gap between the list panel and the standalone preview panel.
    static let paneGap: CGFloat = 12
    /// Row height without a thumbnail. Sizes that scale with the preview size
    /// setting live on `PreviewSize`.
    static let baseRowHeight: CGFloat = 27
    /// Spacing between rows in the list.
    static let rowSpacing: CGFloat = 1
}

struct SwitcherView: View {
    @ObservedObject var model: SwitcherModel
    @ObservedObject var settings: PreviewSettings
    let onActivateSelected: () -> Void

    /// Physical cursor position (screen coordinates) seen on the last hover
    /// event this session. Hover only changes the selection when this actually
    /// changes, so neither a panel appearing under a stationary cursor nor a
    /// keyboard-driven re-render (which re-delivers hover) can steal it.
    @State private var lastMouseLocation: CGPoint?

    private var showsRowThumbnails: Bool {
        settings.isEnabled && settings.mode == .all && !model.windows.isEmpty
    }

    private var rowHeight: CGFloat {
        showsRowThumbnails ? settings.size.rowHeight : PreviewMetrics.baseRowHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(width: PreviewMetrics.listWidth)
        .padding(.horizontal, PreviewMetrics.horizontalPadding)
        .padding(.vertical, PreviewMetrics.verticalPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .onChange(of: model.sessionID) { _, _ in
            lastMouseLocation = nil
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.windows.isEmpty {
            Text(model.statusText.isEmpty ? "No windows" : model.statusText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
        } else {
            VStack(spacing: PreviewMetrics.rowSpacing) {
                ForEach(Array(model.windows.enumerated()), id: \.element.id) { index, window in
                    WindowRow(
                        window: window,
                        isSelected: index == model.selectedIndex,
                        thumbnail: showsRowThumbnails ? model.thumbnail(for: window) : nil,
                        showsThumbnail: showsRowThumbnails,
                        thumbnailLeading: settings.position.isLeading,
                        previewSize: settings.size
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.selectWindow(at: index)
                        onActivateSelected()
                    }
                }
            }
            .onContinuousHover(coordinateSpace: .local) { phase in
                if case let .active(location) = phase {
                    handleHover(at: location)
                }
            }
        }
    }

    /// Updates the selection from a hover, but only when the physical cursor
    /// actually moved. The SwiftUI `location` (used for row mapping) is
    /// re-delivered on keyboard-driven re-renders without any real movement, so
    /// movement is judged from `NSEvent.mouseLocation` (true screen position).
    private func handleHover(at location: CGPoint) {
        let mouseLocation = NSEvent.mouseLocation
        defer { lastMouseLocation = mouseLocation }

        guard let last = lastMouseLocation else {
            // Session baseline; wait for an actual move before selecting.
            return
        }
        guard mouseLocation != last else {
            // No physical movement (re-render or keyboard) — leave selection.
            return
        }

        let stride = rowHeight + PreviewMetrics.rowSpacing
        let index = Int(location.y / stride)
        if model.windows.indices.contains(index), index != model.selectedIndex {
            model.selectWindow(at: index)
        }
    }
}

/// A single window preview image with a graceful placeholder. Shared between
/// the standalone selected-window preview panel and any inline use.
struct WindowPreview: View {
    let image: NSImage?
    let appIcon: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.black.opacity(0.18))

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.medium)
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            } else if let appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .opacity(0.6)
            } else {
                Image(systemName: "macwindow")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct WindowRow: View {
    let window: AppWindow
    let isSelected: Bool
    let thumbnail: NSImage?
    let showsThumbnail: Bool
    let thumbnailLeading: Bool
    let previewSize: PreviewSize

    var body: some View {
        HStack(spacing: 8) {
            if showsThumbnail && thumbnailLeading { rowThumbnail }

            Text(window.appName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
                .frame(width: 82, alignment: .leading)

            if let appIcon = window.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 19, height: 19)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? .white.opacity(0.28) : .secondary.opacity(0.18))
                    .frame(width: 19, height: 19)
            }

            Text(window.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            if showsThumbnail && !thumbnailLeading { rowThumbnail }
        }
        .frame(height: showsThumbnail ? previewSize.rowHeight : PreviewMetrics.baseRowHeight)
        .padding(.horizontal, 7)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var rowThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.black.opacity(0.18))
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .interpolation(.low)
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
            }
        }
        .frame(width: previewSize.rowThumbnail.width, height: previewSize.rowThumbnail.height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
