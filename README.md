# 🧠 BrainDump

**A lightweight macOS menu bar app for capturing thoughts instantly.**

BrainDump lives in your menu bar and pops up with a single shortcut — jot down whatever's on your mind, review it later, and keep what matters. No accounts, no cloud, no friction. Just you and your thoughts, saved as plain Markdown files.

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2015.6+-blue?logo=apple" alt="macOS 15.6+"/>
  <img src="https://img.shields.io/badge/swift-5.9+-orange?logo=swift&logoColor=white" alt="Swift 5.9+"/>
  <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="License"/>
</p>

---

## ✨ Features

- **⚡ Instant Capture** — Global hotkey (`Ctrl+Shift+D`) summons a floating panel from anywhere. Type, hit `Cmd+Enter`, done.
- **📋 Smart Review** — Swipeable cards let you triage notes: swipe right to keep, left to trash. Think Tinder for your thoughts.
- **✏️ Markdown Editor** — Full formatting toolbar (bold, italic, headings, lists, code) with live preview toggle.
- **💾 Auto-Save** — Edits save automatically with debounced persistence. Never lose a word.
- **📁 Plain Files** — Notes stored as `.md` files in `~/Documents/BrainDump/`. Open them in any editor, sync them however you want.
- **🫥 Stays Out of the Way** — No dock icon, no window clutter. Just a brain in your menu bar.

---

## 🚀 Getting Started

### Requirements

- macOS 15.6 or later
- Xcode 16+

### Build & Run

```bash
# Clone the repo
git clone https://github.com/noahlin34/BrainDump.git
cd BrainDump

# Build from command line
xcodebuild build -scheme BrainDump -configuration Debug -quiet

# Or just open in Xcode and hit Run
open BrainDump.xcodeproj
```

No CocoaPods, no SPM packages, no `npm install`. Pure Swift/SwiftUI/AppKit.

---

## 🎯 How It Works

```
┌─────────────────────────────────────────────────────┐
│  Ctrl+Shift+D  →  Capture Panel appears             │
│                                                      │
│  Type your thought  →  Cmd+Enter to save             │
│                         ↓                            │
│               ~/Documents/BrainDump/inbox/           │
│                         ↓                            │
│              Review (swipeable cards)                 │
│              ├── → Keep   → ~/saved/                 │
│              └── ← Trash  → deleted                  │
│                         ↓                            │
│             Saved Notes (click to edit)               │
│             └── Auto-saves as you type               │
└─────────────────────────────────────────────────────┘
```

---

## ⌨️ Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Toggle capture panel | `Ctrl+Shift+D` |
| Save note | `Cmd+Enter` |
| Bold | `Cmd+B` |
| Italic | `Cmd+I` |
| Close panel | `Esc` |
| Quit | `Cmd+Q` |

---

## 📂 Note Storage

Notes are plain Markdown files — no proprietary format, no database.

```
~/Documents/BrainDump/
├── inbox/     # Newly captured, awaiting review
└── saved/     # Reviewed and kept
```

**Filename format:** `2026-02-14_153045_a8f2c1.md`
- Date + time + short UUID = unique, sortable, human-readable

Open them in VS Code, Obsidian, iA Writer, or anything else that reads `.md` files.

---

## 🏗️ Architecture

```
BrainDump/
├── BrainDumpApp.swift      # Entry point, AppDelegate, menu bar, global hotkey
├── AppState.swift           # @Observable UI state (current mode, panel visibility)
├── NoteStore.swift          # Data layer — CRUD operations on .md files
├── Note.swift               # Note model struct
├── ContentView.swift        # Router — switches views based on app mode
├── CaptureView.swift        # Quick capture editor
├── ReviewView.swift         # Swipeable card review
├── SavedNotesView.swift     # Saved notes list
├── NoteEditorView.swift     # Full editor with preview toggle
├── NoteCardView.swift       # Draggable card component
├── FloatingPanel.swift      # Custom NSPanel (floating, non-activating)
├── TextViewIntrospect.swift # NSTextView wrapper for reliable markdown editing
└── TutorialView.swift       # First-launch onboarding
```

### Key Design Decisions

- **SwiftUI + AppKit hybrid** — SwiftUI for views, AppKit for window management and text editing where SwiftUI falls short
- **`NSPanel` with `.nonactivatingPanel`** — Panel doesn't steal focus from other apps
- **Custom `NSViewRepresentable`** for text editing — SwiftUI's `TextEditor` doesn't expose the underlying `NSTextView`, which is needed for programmatic formatting
- **Carbon Events** for global hotkey — The only way to register system-wide shortcuts on macOS
- **`@Observable` state** — Modern Swift observation for reactive UI updates without Combine boilerplate

---

## 🤝 Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with 🧠 by <a href="https://github.com/noahlin34">Noah</a>
</p>
