import SwiftUI
import Carbon

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
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    let appState = AppState()
    let noteStore = NoteStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupPanel()
        registerGlobalHotKey()
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
        menu.addItem(NSMenuItem(title: "Quit BrainDump", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - Panel

    private func setupPanel() {
        let contentView = ContentView()
            .environment(appState)
            .environment(noteStore)

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
    }

    @objc private func openCapture() {
        showPanel(mode: .capture)
    }

    @objc private func openReview() {
        showPanel(mode: .review)
    }

    @objc private func openSaved() {
        showPanel(mode: .savedNotes)
    }

    func toggleCapture() {
        if panel.isVisible {
            panel.close()
            appState.isPanelVisible = false
        } else {
            showPanel(mode: .capture)
        }
    }

    // MARK: - Global Hot Key (Ctrl+Shift+D)

    private func registerGlobalHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_: EventHandlerCallRef?, _: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                delegate.toggleCapture()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        var hotKeyID = EventHotKeyID(
            signature: OSType(0x4244_4D50), // "BDMP"
            id: 1
        )

        RegisterEventHotKey(
            UInt32(kVK_ANSI_D),
            UInt32(controlKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
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
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        appState.isPanelVisible = false
    }
}
