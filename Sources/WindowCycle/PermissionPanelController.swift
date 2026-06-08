import AppKit
import SwiftUI

struct PermissionSnapshot {
    let accessibilityGranted: Bool
    let keyboardEventsGranted: Bool

    var allGranted: Bool {
        accessibilityGranted && keyboardEventsGranted
    }
}

@MainActor
final class PermissionModel: ObservableObject {
    @Published var accessibilityGranted = false
    @Published var keyboardEventsGranted = false

    func update(_ snapshot: PermissionSnapshot) {
        accessibilityGranted = snapshot.accessibilityGranted
        keyboardEventsGranted = snapshot.keyboardEventsGranted
    }
}

@MainActor
final class PermissionPanelController {
    private let model = PermissionModel()
    private let onRefresh: () -> Void

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        panel.title = "WindowCycle Permissions"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.contentView = NSHostingView(
            rootView: PermissionView(
                model: model,
                onRefresh: onRefresh,
                onClose: { [weak self] in
                    self?.hide()
                }
            )
        )
        return panel
    }()

    init(onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh
    }

    func show(_ snapshot: PermissionSnapshot) {
        model.update(snapshot)
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func update(_ snapshot: PermissionSnapshot) {
        model.update(snapshot)
    }

    func hide() {
        panel.orderOut(nil)
    }
}

private struct PermissionView: View {
    @ObservedObject var model: PermissionModel
    let onRefresh: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permissions")
                .font(.system(size: 18, weight: .semibold))

            PermissionRow(
                title: "Accessibility",
                detail: "Required to read and raise app windows.",
                isGranted: model.accessibilityGranted,
                buttonTitle: "Open Accessibility",
                action: {
                    openPrivacyPane("Privacy_Accessibility")
                }
            )

            PermissionRow(
                title: "Input Monitoring",
                detail: "Required to consume navigation keys while switching.",
                isGranted: model.keyboardEventsGranted,
                buttonTitle: "Open Input Monitoring",
                action: {
                    openPrivacyPane("Privacy_ListenEvent")
                }
            )

            Text("If WindowCycle is missing from System Settings, click + in that privacy list and choose WindowCycle.app from Applications.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Show App in Finder") {
                    revealAppInFinder()
                }

                Button("Refresh") {
                    onRefresh()
                }

                Spacer()

                Button("Done") {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private func openPrivacyPane(_ anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
}

private struct PermissionRow: View {
    let title: String
    let detail: String
    let isGranted: Bool
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isGranted ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(buttonTitle) {
                action()
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
