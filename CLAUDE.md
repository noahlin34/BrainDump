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
