import SwiftUI
import Carbon.HIToolbox

@main
struct BrainDumpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel!
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var clickOutsideMonitor: Any?

    let appState = AppState()
    let noteStore = NoteStore()
    let keybindStore = KeybindStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupPanel()
        registerGlobalHotKey()

        if !UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
            showPanel(mode: .tutorial)
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("closePanelAfterSave"), object: nil, queue: .main) { [weak self] _ in
            self?.panel.close()
            self?.appState.isPanelVisible = false
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "BrainDump")
        }

        let menu = NSMenu()
        let newDump = NSMenuItem(title: "New Brain Dump", action: #selector(openCapture), keyEquivalent: "n")
        newDump.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(newDump)

        let reviewItem = NSMenuItem(title: "Review Notes", action: #selector(openReview), keyEquivalent: "")
        menu.addItem(reviewItem)

        let savedItem = NSMenuItem(title: "Saved Notes", action: #selector(openSaved), keyEquivalent: "")
        menu.addItem(savedItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Show Tutorial", action: #selector(openTutorial), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "About BrainDump", action: #selector(showAbout), keyEquivalent: ""))

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit BrainDump", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - Panel

    private func setupPanel() {
        let contentView = ContentView()
            .environment(appState)
            .environment(noteStore)
            .environment(keybindStore)

        panel = FloatingPanel(contentView: contentView)
        panel.delegate = self
    }

    private func showPanel(mode: AppMode) {
        appState.currentMode = mode
        if mode == .review {
            noteStore.refresh()
        }
        panel.showCentered()
        appState.isPanelVisible = true
        installClickOutsideMonitor()
    }

    @objc private func openCapture() {
        showPanel(mode: .capture)
    }

    @objc private func openReview() {
        showPanel(mode: .review)
    }

    @objc private func showAbout() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }

    @objc private func openSaved() {
        showPanel(mode: .savedNotes)
    }

    @objc private func openTutorial() {
        showPanel(mode: .tutorial)
    }

    @objc private func openSettings() {
        showPanel(mode: .settings)
    }

    private func installClickOutsideMonitor() {
        removeClickOutsideMonitor()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.panel.isVisible else { return }
            // Only auto-dismiss in capture mode
            guard self.appState.currentMode == .capture else { return }
            let mouseLocation = NSEvent.mouseLocation
            let panelFrame = self.panel.frame
            if !panelFrame.contains(mouseLocation) {
                self.panel.close()
                self.appState.isPanelVisible = false
            }
        }
    }

    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    func toggleCapture() {
        if panel.isVisible {
            panel.close()
            appState.isPanelVisible = false
        } else {
            showPanel(mode: .capture)
        }
    }

    // MARK: - Global Hot Key

    private func registerGlobalHotKey() {
        let handler: (NSEvent) -> Bool = { [weak self] event in
            guard let self, self.keybindStore.matches(event: event, action: .globalCapture) else {
                return false
            }
            self.toggleCapture()
            return true
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handler(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event) ? nil : event
        }

        // Prompt for accessibility permissions if not already granted
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        noteStore.refresh()
        let inboxCount = noteStore.inboxNotes.count
        if let reviewItem = menu.item(withTitle: "Review Notes") ?? menu.items.first(where: { $0.action == #selector(openReview) }) {
            reviewItem.title = inboxCount > 0 ? "Review Notes (\(inboxCount))" : "Review Notes"
        }

        // Sync "New Brain Dump" key equivalent from keybind store
        if let newDumpItem = menu.items.first(where: { $0.action == #selector(openCapture) }) {
            let binding = keybindStore.binding(for: .newBrainDump)
            newDumpItem.keyEquivalent = binding.characters
            newDumpItem.keyEquivalentModifierMask = binding.nsModifierFlags
        }
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        appState.isPanelVisible = false
        removeClickOutsideMonitor()
    }
}
