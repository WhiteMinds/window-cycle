import SwiftUI

struct SwitcherView: View {
    @ObservedObject var model: SwitcherModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(width: 680)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var content: some View {
        if model.windows.isEmpty {
            Text(model.statusText.isEmpty ? "No windows" : model.statusText)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
        } else {
            VStack(spacing: 2) {
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
        HStack(spacing: 10) {
            Text(keyHint)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white.opacity(0.88) : .secondary)
                .frame(width: 42, alignment: .leading)

            Text(window.appName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
                .frame(width: 102, alignment: .leading)

            if let appIcon = window.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? .white.opacity(0.28) : .secondary.opacity(0.18))
                    .frame(width: 22, height: 22)
            }

            Text(window.title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(height: 32)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var keyHint: String {
        let appPrefix = firstVisibleString(in: window.appName) ?? "?"
        let titlePrefix = firstVisibleString(in: window.title) ?? "\(window.indexHint)"
        return "\(appPrefix)\(titlePrefix)".lowercased()
    }

    private func firstVisibleString(in value: String) -> String? {
        value.first { !$0.isWhitespace }.map(String.init)
    }
}
