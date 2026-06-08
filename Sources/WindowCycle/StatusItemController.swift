import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let onShowWindows: () -> Void
    private let onShowPermissions: () -> Void
    private let onHideSwitcher: () -> Void
    private let onQuit: () -> Void

    init(
        onShowWindows: @escaping () -> Void,
        onShowPermissions: @escaping () -> Void,
        onHideSwitcher: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.onShowWindows = onShowWindows
        self.onShowPermissions = onShowPermissions
        self.onHideSwitcher = onHideSwitcher
        self.onQuit = onQuit
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.stack",
                accessibilityDescription: "WindowCycle"
            )
            button.toolTip = "WindowCycle"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Show Current App Windows",
            action: #selector(showWindows),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Hide Switcher",
            action: #selector(hideSwitcher),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Permissions...",
            action: #selector(showPermissions),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit WindowCycle",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func showWindows() {
        onShowWindows()
    }

    @objc private func hideSwitcher() {
        onHideSwitcher()
    }

    @objc private func showPermissions() {
        onShowPermissions()
    }

    @objc private func quit() {
        onQuit()
    }
}
