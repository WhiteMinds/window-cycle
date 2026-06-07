import SwiftUI

struct SwitcherView: View {
    @ObservedObject var model: SwitcherModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .frame(width: 560)
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text(model.appName)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text("Cmd+`")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.windows.isEmpty {
            Text(model.statusText.isEmpty ? "No windows" : model.statusText)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
        } else {
            VStack(spacing: 6) {
                ForEach(Array(model.windows.enumerated()), id: \.element.id) { index, window in
                    WindowRow(
                        window: window,
                        isSelected: index == model.selectedIndex
                    )
                }
            }
        }
    }
}

private struct WindowRow: View {
    let window: AppWindow
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(window.indexHint)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            VStack(alignment: .leading, spacing: 3) {
                Text(window.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var subtitle: String {
        let frame = window.frame
        let state = window.isMinimized ? "minimized" : "visible"
        return "\(state) - \(Int(frame.width)) x \(Int(frame.height))"
    }
}

