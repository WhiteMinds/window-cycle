import AppKit

@MainActor
final class AppController: NSObject, NSApplicationDelegate {
    private let axWindowService = AXWindowService()
    private let panelController = SwitcherPanelController()
    private var hotKeyService: HotKeyService?
    private var modifierReleaseMonitor: ModifierReleaseMonitor?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        _ = axWindowService.requestAccessibilityIfNeeded()

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
                self?.showSwitcher(.next)
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
            showPanel()
        }

        modifierReleaseMonitor?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyService?.stop()
        modifierReleaseMonitor?.stop()
    }

    private func handleHotKey(_ direction: WindowCycleDirection) {
        if panelController.isVisible {
            panelController.model.moveSelection(direction)
            showPanel()
            return
        }

        showSwitcher(direction)
    }

    private func showSwitcher(_ direction: WindowCycleDirection) {
        do {
            let windows = try axWindowService.currentApplicationWindows()
            panelController.model.setWindows(windows, direction: direction)
            showPanel()
        } catch {
            panelController.model.windows = []
            panelController.model.statusText = String(describing: error)
            showPanel()
        }
    }

    private func cancelSwitcher() {
        guard panelController.isVisible else {
            return
        }
        hidePanel()
    }

    private func moveSelectionIfNeeded(_ direction: WindowCycleDirection) {
        guard panelController.isVisible else {
            return
        }

        panelController.model.moveSelection(direction)
        showPanel()
    }

    private func activateSelectedWindowIfNeeded() {
        guard panelController.isVisible else {
            return
        }

        defer {
            hidePanel()
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

    private func showPanel() {
        panelController.show()
        modifierReleaseMonitor?.setSwitcherVisible(true)
    }

    private func hidePanel() {
        panelController.hide()
        modifierReleaseMonitor?.setSwitcherVisible(false)
    }
}
