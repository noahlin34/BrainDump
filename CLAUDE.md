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

BrainDump is a **macOS menu bar app** (`LSUIElement=YES`, no dock icon) for quick-capturing and reviewing notes. It uses a SwiftUI + AppKit hybrid approach:

- **AppDelegate** (`BrainDumpApp.swift`) — Owns the status bar item, floating panel, and global hotkey (Ctrl+Shift+D via Carbon Events). Entry point for all system integration.
- **AppState** (`AppState.swift`) — `@Observable` class holding `currentMode: AppMode` and `isPanelVisible`. Injected via SwiftUI `.environment()`.
- **NoteStore** (`NoteStore.swift`) — `@Observable` data layer. Persists notes as `.md` files under `~/Documents/BrainDump/` with `inbox/` (uncategorized) and `saved/` (kept) subdirectories.
- **ContentView** (`ContentView.swift`) — Router that switches views based on `appState.currentMode`.
- **FloatingPanel** (`FloatingPanel.swift`) — Custom `NSPanel` subclass (floating level, transparent titlebar, Esc to close).

### User flow

Capture (Cmd+Enter saves) → notes land in `inbox/` → ReviewView shows swipeable cards (right=keep, left=trash) → kept notes appear in SavedNotesView → tap to edit in NoteEditorView (debounced auto-save).

### State management

`AppState` and `NoteStore` are created in `AppDelegate` and injected into the SwiftUI view hierarchy via `.environment()`. Views read them with `@Environment(AppState.self)` / `@Environment(NoteStore.self)`.

### Key conventions

- Note filenames: `yyyy-MM-dd_HHmmss_XXXXXX.md` (date + 6-char UUID prefix)
- UserDefaults key: `hasSeenTutorial` — controls first-launch tutorial
- Menu order: New Brain Dump → Review Notes → Saved Notes → separator → Show Tutorial → About → separator → Quit

### FloatingPanel & NSTextView gotchas

The app runs inside a `.nonactivatingPanel` (`LSUIElement=YES`), which causes several AppKit/SwiftUI pitfalls:

- **`NSApp.keyWindow` is always nil.** The app is never "active" in the macOS sense, so `NSApp.keyWindow` returns nil. Never use it. Use `NSApp.windows` iteration or stored references instead.
- **`NSApp.keyWindow?.firstResponder` is unreliable.** Even `window.firstResponder` can change when SwiftUI buttons are clicked, making it useless for finding the NSTextView at action time.
- **Don't use SwiftUI `TextEditor` when you need programmatic NSTextView access.** SwiftUI's `TextEditor` wraps an NSTextView but provides no API to reach it. Searching the view hierarchy (`findTextView(in: window.contentView)`) is fragile — the NSTextView may not exist yet, or the search may run at the wrong time. Use a custom `NSViewRepresentable` wrapping `NSTextView` instead (see `MarkdownTextView`).
- **`insertText` on NSTextView does NOT sync SwiftUI `TextEditor` bindings.** If you call `insertText` on the underlying NSTextView of a SwiftUI `TextEditor`, the `@State` binding is not updated. On the next SwiftUI re-render, the old value overwrites the change — making it look like nothing happened. The fix is to use a custom `NSViewRepresentable` with a `NSTextViewDelegate` coordinator whose `textDidChange` updates the binding.
- **SwiftUI `.keyboardShortcut` doesn't work for Cmd+B/I.** NSTextView intercepts these as standard key bindings (bold/italic) before SwiftUI sees them. Use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` instead. Remember to remove the monitor in `onDisappear`.
- **`NoteStore.updateNote()` calls `refresh()` which re-reads all notes.** This triggers `@Observable` observation. Avoid calling it in the same synchronous block as a state toggle (like preview mode) — the observation side effects can interfere. Prefer simple state toggles without save side effects when possible.
- **Use `TextViewHolder` (reference type) to share NSTextView refs with event monitor closures.** `@State` on a struct can't be reliably captured in `@escaping` closures for event monitors. Store the `weak var textView: NSTextView?` in a class instance held by `@State`, and capture that class in the closure.
