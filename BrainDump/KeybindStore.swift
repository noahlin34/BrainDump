import AppKit
import Carbon.HIToolbox

struct Keybind: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlags: UInt
    var characters: String
    var displayString: String

    var nsModifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
            .intersection(.deviceIndependentFlagsMask)
    }
}

enum KeybindAction: String, CaseIterable, Codable {
    case globalCapture
    case newBrainDump
    case bold
    case italic
    case saveNote

    var label: String {
        switch self {
        case .globalCapture: "Global Capture"
        case .newBrainDump: "New Brain Dump"
        case .bold: "Bold"
        case .italic: "Italic"
        case .saveNote: "Save Note"
        }
    }

    var defaultKeybind: Keybind {
        switch self {
        case .globalCapture:
            Keybind(
                keyCode: UInt16(kVK_ANSI_D),
                modifierFlags: NSEvent.ModifierFlags([.control, .shift]).rawValue,
                characters: "d",
                displayString: "Ctrl+Shift+D"
            )
        case .newBrainDump:
            Keybind(
                keyCode: UInt16(kVK_ANSI_N),
                modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
                characters: "n",
                displayString: "⌘Shift+N"
            )
        case .bold:
            Keybind(
                keyCode: UInt16(kVK_ANSI_B),
                modifierFlags: NSEvent.ModifierFlags.command.rawValue,
                characters: "b",
                displayString: "⌘B"
            )
        case .italic:
            Keybind(
                keyCode: UInt16(kVK_ANSI_I),
                modifierFlags: NSEvent.ModifierFlags.command.rawValue,
                characters: "i",
                displayString: "⌘I"
            )
        case .saveNote:
            Keybind(
                keyCode: UInt16(kVK_Return),
                modifierFlags: NSEvent.ModifierFlags.command.rawValue,
                characters: "\r",
                displayString: "⌘Enter"
            )
        }
    }
}

@Observable
class KeybindStore {
    private static let userDefaultsKey = "customKeybindings"

    private(set) var bindings: [KeybindAction: Keybind]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([KeybindAction: Keybind].self, from: data) {
            self.bindings = decoded
        } else {
            var defaults: [KeybindAction: Keybind] = [:]
            for action in KeybindAction.allCases {
                defaults[action] = action.defaultKeybind
            }
            self.bindings = defaults
        }
    }

    func binding(for action: KeybindAction) -> Keybind {
        bindings[action] ?? action.defaultKeybind
    }

    func matches(event: NSEvent, action: KeybindAction) -> Bool {
        let keybind = binding(for: action)
        let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let bindMods = NSEvent.ModifierFlags(rawValue: keybind.modifierFlags)
            .intersection(.deviceIndependentFlagsMask)
        return event.keyCode == keybind.keyCode && eventMods == bindMods
    }

    /// Returns false if another action already uses this key combo (conflict).
    @discardableResult
    func setBinding(_ keybind: Keybind, for action: KeybindAction) -> Bool {
        for (existingAction, existingBind) in bindings where existingAction != action {
            if existingBind.keyCode == keybind.keyCode && existingBind.modifierFlags == keybind.modifierFlags {
                return false
            }
        }
        bindings[action] = keybind
        persist()
        return true
    }

    func resetToDefaults() {
        for action in KeybindAction.allCases {
            bindings[action] = action.defaultKeybind
        }
        persist()
    }

    func resetBinding(for action: KeybindAction) {
        bindings[action] = action.defaultKeybind
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(bindings) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}

// MARK: - Display String Builder

func buildDisplayString(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> String {
    var parts: [String] = []
    let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)

    if flags.contains(.control) { parts.append("Ctrl") }
    if flags.contains(.option) { parts.append("⌥") }
    if flags.contains(.shift) { parts.append("Shift") }
    if flags.contains(.command) { parts.append("⌘") }

    let keyName: String
    switch Int(keyCode) {
    case kVK_Return: keyName = "Enter"
    case kVK_Tab: keyName = "Tab"
    case kVK_Space: keyName = "Space"
    case kVK_Delete: keyName = "Delete"
    case kVK_ForwardDelete: keyName = "Fwd Delete"
    case kVK_Escape: keyName = "Esc"
    case kVK_LeftArrow: keyName = "←"
    case kVK_RightArrow: keyName = "→"
    case kVK_UpArrow: keyName = "↑"
    case kVK_DownArrow: keyName = "↓"
    case kVK_F1: keyName = "F1"
    case kVK_F2: keyName = "F2"
    case kVK_F3: keyName = "F3"
    case kVK_F4: keyName = "F4"
    case kVK_F5: keyName = "F5"
    case kVK_F6: keyName = "F6"
    case kVK_F7: keyName = "F7"
    case kVK_F8: keyName = "F8"
    case kVK_F9: keyName = "F9"
    case kVK_F10: keyName = "F10"
    case kVK_F11: keyName = "F11"
    case kVK_F12: keyName = "F12"
    default:
        // Map common key codes to characters
        let keyMap: [Int: String] = [
            kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
            kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
            kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
            kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
            kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
            kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
            kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
            kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
            kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
            kVK_ANSI_8: "8", kVK_ANSI_9: "9",
            kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=",
            kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",
            kVK_ANSI_Semicolon: ";", kVK_ANSI_Quote: "'",
            kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".",
            kVK_ANSI_Slash: "/", kVK_ANSI_Backslash: "\\",
            kVK_ANSI_Grave: "`",
        ]
        keyName = keyMap[Int(keyCode)] ?? "Key\(keyCode)"
    }

    parts.append(keyName)

    // Use "+" as separator but compact ⌘/⌥ symbols with the key
    return parts.joined(separator: "+")
}
