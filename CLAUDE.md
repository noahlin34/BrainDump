# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
xcodebuild build -scheme BrainDump -configuration Debug -quiet
```

No external dependencies. Pure Swift/SwiftUI/AppKit. Xcode 16+ required (uses `PBXFileSystemSynchronizedRootGroup` — new files in `BrainDump/` are auto-discovered without manual project file edits).

- **Deployment target:** macOS 15.6
- **Swift default actor isolation:** MainActor

## Architecture

BrainDump is a **macOS menu bar app** (`LSUIElement=YES`, no dock icon) for quick-capturing and reviewing notes. It uses a SwiftUI + AppKit hybrid approach and behaves like a lightweight dropdown overlay (think Spotlight/Raycast).

### Core components

- **AppDelegate** (`BrainDumpApp.swift`) — Owns the status bar item, floating panel, global hotkey (configurable via `KeybindStore`), click-outside-to-dismiss monitor, and save notification observer. Entry point for all system integration.
- **AppState** (`AppState.swift`) — `@Observable` class holding `currentMode: AppMode` and `isPanelVisible`. Injected via `.environment()`.
- **NoteStore** (`NoteStore.swift`) — `@Observable` data layer. Persists notes as `.md` files under `~/Documents/BrainDump/` with `inbox/` (uncategorized) and `saved/` (kept) subdirectories.
- **KeybindStore** (`KeybindStore.swift`) — `@Observable` keybind manager. Persists custom shortcuts as JSON in UserDefaults. Provides `matches(event:action:)` for event matching and conflict detection.
- **ContentView** (`ContentView.swift`) — Router that switches views based on `appState.currentMode`.
- **FloatingPanel** (`FloatingPanel.swift`) — Custom `NSPanel` subclass. Fixed 500×400, anchored below the menu bar icon as a dropdown, visible across all Spaces and over fullscreen apps.

### Views

| View | File | Purpose |
|------|------|---------|
| CaptureView | `CaptureView.swift` | Markdown note input with formatting toolbar, preview toggle, auto-close after save |
| ReviewView | `ReviewView.swift` | Swipeable card interface for inbox notes |
| NoteCardView | `NoteCardView.swift` | Drag-gesture card with KEEP/NOPE labels |
| SavedNotesView | `SavedNotesView.swift` | List of saved notes with context menu |
| NoteEditorView | `NoteEditorView.swift` | Edit saved notes with debounced auto-save, markdown preview, share/finder |
| SettingsView | `SettingsView.swift` | Launch at login toggle, keybind customization |
| KeybindRecorderView | `KeybindRecorderView.swift` | Click-to-record shortcut row with conflict detection |
| TutorialView | `TutorialView.swift` | 5-page onboarding with accessibility permission polling |
| MarkdownTextView | `TextViewIntrospect.swift` | NSViewRepresentable wrapping NSTextView with delegate coordinator |

### User flow

Capture → auto-close after save → notes land in `inbox/` → ReviewView shows swipeable cards (right=keep, left=trash) → kept notes appear in SavedNotesView → tap to edit in NoteEditorView (debounced auto-save).

### AppMode cases

`capture` | `review` | `savedNotes` | `editNote(Note)` | `tutorial` | `settings`

### State management

`AppState`, `NoteStore`, and `KeybindStore` are created in `AppDelegate` and injected into the SwiftUI view hierarchy via `.environment()`. Views read them with `@Environment(AppState.self)` / `@Environment(NoteStore.self)` / `@Environment(KeybindStore.self)`.

### Key conventions

- Note filenames: `yyyy-MM-dd_HHmmss_XXXXXX.md` (date + 6-char UUID prefix)
- UserDefaults keys: `hasSeenTutorial` (bool), `customKeybindings` (JSON data)
- Launch at login: managed by `SMAppService.mainApp` (ServiceManagement framework)
- Menu order: New Brain Dump → Review Notes → Saved Notes → separator → Show Tutorial → About → Settings... → separator → Quit
- Notification: `.closePanelAfterSave` — posted by CaptureView after 0.5s, observed by AppDelegate to close panel

### Configurable keybinds

5 actions with defaults: Global Capture (Ctrl+Shift+D), New Brain Dump (⌘Shift+N), Bold (⌘B), Italic (⌘I), Save Note (⌘Enter). All customizable via Settings. Menu item key equivalents sync from the store in `menuNeedsUpdate`.

### Panel behavior

- **Dropdown anchoring:** `showBelow(statusItem:)` positions the panel directly under the menu bar icon, centered horizontally, with screen-edge clamping. Falls back to centered if button frame unavailable.
- **Click-outside-to-dismiss:** Global mouse monitor closes the panel on outside clicks, but **only in `.capture` mode**. Other modes (review, settings, tutorial, edit) require explicit navigation.
- **Auto-close after save:** CaptureView shows a "Saved!" overlay for 0.5s, then posts a notification that AppDelegate observes to close the panel.
- **Cross-space visibility:** `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`
- **Fixed size:** 500×400, not resizable

### FloatingPanel & NSTextView gotchas

The app runs inside a `.nonactivatingPanel` (`LSUIElement=YES`), which causes several AppKit/SwiftUI pitfalls:

- **`NSApp.keyWindow` is always nil.** The app is never "active" in the macOS sense, so `NSApp.keyWindow` returns nil. Never use it. Use `NSApp.windows` iteration or stored references instead.
- **`NSApp.keyWindow?.firstResponder` is unreliable.** Even `window.firstResponder` can change when SwiftUI buttons are clicked, making it useless for finding the NSTextView at action time.
- **Don't use SwiftUI `TextEditor` when you need programmatic NSTextView access.** SwiftUI's `TextEditor` wraps an NSTextView but provides no API to reach it. Searching the view hierarchy is fragile. Use a custom `NSViewRepresentable` wrapping `NSTextView` instead (see `MarkdownTextView` in `TextViewIntrospect.swift`).
- **`insertText` on NSTextView does NOT sync SwiftUI `TextEditor` bindings.** The fix is a custom `NSViewRepresentable` with a `NSTextViewDelegate` coordinator whose `textDidChange` updates the binding.
- **SwiftUI `.keyboardShortcut` doesn't work for Cmd+B/I.** NSTextView intercepts these as standard key bindings before SwiftUI sees them. Use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` with `keybindStore.matches()` instead. Remove the monitor in `onDisappear`.
- **`NoteStore.updateNote()` calls `refresh()` which re-reads all notes.** This triggers `@Observable` observation. Avoid calling it in the same synchronous block as a state toggle — the observation side effects can interfere.
- **Use `TextViewHolder` (reference type) to share NSTextView refs with event monitor closures.** `@State` on a struct can't be reliably captured in `@escaping` closures for event monitors. Store the `weak var textView: NSTextView?` in a class instance held by `@State`, and capture that class in the closure.
