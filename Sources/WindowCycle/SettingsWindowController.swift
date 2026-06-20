import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let settings: PreviewSettings
    private var window: NSWindow?

    init(settings: PreviewSettings) {
        self.settings = settings
    }

    func show() {
        if window == nil {
            window = makeWindow()
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WindowCycle Settings"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(settings: settings))
        return window
    }
}

struct SettingsView: View {
    @ObservedObject var settings: PreviewSettings
    @State private var screenRecordingGranted = ScreenRecordingPermission.isGranted()

    var body: some View {
        Form {
            Section("Window Previews") {
                Toggle("Show window previews", isOn: $settings.isEnabled)
                    .onChange(of: settings.isEnabled) { _, isEnabled in
                        if isEnabled { requestPermission() }
                    }

                Picker("Show", selection: $settings.mode) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .disabled(!settings.isEnabled)

                Picker("Position", selection: $settings.position) {
                    ForEach(PreviewPosition.available(for: settings.mode)) { position in
                        Text(position.title).tag(position)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isEnabled)

                Picker("Size", selection: $settings.size) {
                    ForEach(PreviewSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isEnabled)
            }

            if settings.isEnabled {
                Section("Screen Recording Permission") {
                    LabeledContent("Status") {
                        Label(
                            screenRecordingGranted ? "Granted" : "Not granted",
                            systemImage: screenRecordingGranted
                                ? "checkmark.circle.fill"
                                : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(screenRecordingGranted ? .green : .orange)
                    }

                    if !screenRecordingGranted {
                        Text("Previews need Screen Recording permission. Grant it, then relaunch WindowCycle.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        HStack {
                            Button("Request Permission") { requestPermission() }
                            Button("Open System Settings") { openSystemSettings() }
                            Button("Re-check") { refreshPermission() }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { refreshPermission() }
    }

    private func requestPermission() {
        screenRecordingGranted = ScreenRecordingPermission.request()
    }

    private func refreshPermission() {
        screenRecordingGranted = ScreenRecordingPermission.isGranted()
    }

    private func openSystemSettings() {
        guard let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
