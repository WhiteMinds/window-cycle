import AppKit

@MainActor
final class AppController: NSObject, NSApplicationDelegate {
    private static let delayedPanelShowNanoseconds: UInt64 = 125_000_000

    private let axWindowService = AXWindowService()
    private let previewSettings = PreviewSettings()
    private let thumbnailService = WindowThumbnailService()
    private lazy var panelController = SwitcherPanelController(
        settings: previewSettings,
        onActivateSelected: { [weak self] in
            self?.activateSelectedWindowIfNeeded()
        }
    )
    private lazy var settingsWindowController = SettingsWindowController(settings: previewSettings)
    private var hotKeyService: HotKeyService?
    private var modifierReleaseMonitor: ModifierReleaseMonitor?
    private var statusItemController: StatusItemController?
    private var permissionPanelController: PermissionPanelController?
    private var pendingPanelShowTask: Task<Void, Never>?
    private var isSwitcherActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        thumbnailService.onCapture = { [weak self] windowID, image in
            self?.panelController.model.setThumbnail(image, for: windowID)
        }

        let accessibilityTrusted = axWindowService.requestAccessibilityIfNeeded()

        hotKeyService = HotKeyService { [weak self] direction in
            Task { @MainActor in
                self?.handleHotKey(direction)
            }
        }

        modifierReleaseMonitor = ModifierReleaseMonitor(
            onCommandReleased: { [weak self] in
                self?.activateSelectedWindowIfNeeded()
            },
            onEscape: { [weak self] in
                self?.cancelSwitcher()
            },
            onMoveSelection: { [weak self] direction in
                self?.moveSelectionIfNeeded(direction)
            }
        )

        statusItemController = StatusItemController(
            onShowWindows: { [weak self] in
                self?.showSwitcher(.next, delayed: false)
            },
            onShowSettings: { [weak self] in
                self?.settingsWindowController.show()
            },
            onShowPermissions: { [weak self] in
                self?.showPermissions()
            },
            onHideSwitcher: { [weak self] in
                self?.cancelSwitcher()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        do {
            try hotKeyService?.start()
        } catch {
            panelController.model.statusText = String(describing: error)
            beginSwitcher()
            cancelPendingPanelShow()
            showPanel()
        }

        modifierReleaseMonitor?.start()

        permissionPanelController = PermissionPanelController(
            onRefresh: { [weak self] in
                self?.refreshPermissions()
            }
        )

        if !accessibilityTrusted || !(modifierReleaseMonitor?.isEventTapActive ?? false) {
            showPermissions()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyService?.stop()
        modifierReleaseMonitor?.stop()
    }

    private func handleHotKey(_ direction: WindowCycleDirection) {
        if isSwitcherActive {
            panelController.model.moveSelection(direction)
            if panelController.isVisible {
                showPanel()
            }
            return
        }

        showSwitcher(direction, delayed: true)
    }

    private func showSwitcher(_ direction: WindowCycleDirection, delayed: Bool) {
        do {
            let windows = try axWindowService.currentApplicationWindows()
            panelController.model.setWindows(windows, direction: direction)
            prefetchThumbnailsIfNeeded()
            beginSwitcher()

            if delayed {
                schedulePanelShow()
            } else {
                cancelPendingPanelShow()
                showPanel()
            }
        } catch {
            panelController.model.windows = []
            panelController.model.statusText = String(describing: error)
            beginSwitcher()
            cancelPendingPanelShow()
            showPanel()
        }
    }

    /// Pre-warms window previews on session start so thumbnails are ready by
    /// the time the panel appears. Captures the selected window first.
    private func prefetchThumbnailsIfNeeded() {
        guard previewSettings.isEnabled,
              ScreenRecordingPermission.isGranted()
        else {
            return
        }

        let model = panelController.model
        let windowIDs = model.windows.compactMap(\.cgWindowID)
        thumbnailService.prune(keeping: Set(windowIDs))

        // Show any cached image immediately (stale-while-revalidate).
        for window in model.windows {
            if let id = window.cgWindowID, let cached = thumbnailService.image(for: id) {
                model.setThumbnail(cached, for: id)
            }
        }

        // Capture the selected window first, then the rest.
        let selectedID = model.selectedWindow?.cgWindowID
        let prioritized = selectedID.map { [$0] + windowIDs.filter { $0 != selectedID } } ?? windowIDs
        thumbnailService.prefetch(prioritized)
    }

    private func cancelSwitcher() {
        guard isSwitcherActive || panelController.isVisible || pendingPanelShowTask != nil else {
            return
        }

        finishSwitcher()
    }

    private func moveSelectionIfNeeded(_ direction: WindowCycleDirection) {
        guard isSwitcherActive else {
            return
        }

        panelController.model.moveSelection(direction)
        if panelController.isVisible {
            showPanel()
        }
    }

    private func activateSelectedWindowIfNeeded() {
        guard isSwitcherActive else {
            return
        }

        cancelPendingPanelShow()
        defer {
            finishSwitcher()
        }

        guard let window = panelController.model.selectedWindow else {
            return
        }

        do {
            try axWindowService.activate(window)
        } catch {
            NSLog("WindowCycle activation failed: \(String(describing: error))")
        }
    }

    private func showPermissions() {
        permissionPanelController?.show(currentPermissionSnapshot())
    }

    private func refreshPermissions() {
        _ = axWindowService.requestAccessibilityIfNeeded()
        modifierReleaseMonitor?.start()
        permissionPanelController?.update(currentPermissionSnapshot())
    }

    private func currentPermissionSnapshot() -> PermissionSnapshot {
        PermissionSnapshot(
            accessibilityGranted: axWindowService.isAccessibilityTrusted(),
            keyboardEventsGranted: modifierReleaseMonitor?.isEventTapActive ?? false
        )
    }

    private func beginSwitcher() {
        isSwitcherActive = true
        modifierReleaseMonitor?.setSwitcherActive(true)
    }

    private func finishSwitcher() {
        cancelPendingPanelShow()
        isSwitcherActive = false
        hidePanel()
        modifierReleaseMonitor?.setSwitcherActive(false)
    }

    private func schedulePanelShow() {
        cancelPendingPanelShow()

        pendingPanelShowTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.delayedPanelShowNanoseconds)
            } catch {
                return
            }

            guard let self, self.isSwitcherActive, !self.panelController.isVisible else {
                return
            }

            self.pendingPanelShowTask = nil
            self.showPanel()
        }
    }

    private func cancelPendingPanelShow() {
        pendingPanelShowTask?.cancel()
        pendingPanelShowTask = nil
    }

    private func showPanel() {
        panelController.show()
    }

    private func hidePanel() {
        panelController.hide()
    }
}
