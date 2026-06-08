import SwiftUI

struct SwitcherView: View {
    @ObservedObject var model: SwitcherModel
    let onActivateSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(width: 590)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var content: some View {
        if model.windows.isEmpty {
            Text(model.statusText.isEmpty ? "No windows" : model.statusText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
        } else {
            VStack(spacing: 1) {
                ForEach(Array(model.windows.enumerated()), id: \.element.id) { index, window in
                    WindowRow(
                        window: window,
                        isSelected: index == model.selectedIndex
                    )
                    .contentShape(Rectangle())
                    .onHover { isHovering in
                        if isHovering {
                            model.selectWindow(at: index)
                        }
                    }
                    .onTapGesture {
                        model.selectWindow(at: index)
                        onActivateSelected()
                    }
                }
            }
        }
    }
}

private struct WindowRow: View {
    let window: AppWindow
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
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
        }
        .frame(height: 27)
        .padding(.horizontal, 7)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
