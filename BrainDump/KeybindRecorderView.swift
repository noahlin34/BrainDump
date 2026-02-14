import SwiftUI
import AppKit

struct KeybindRecorderView: View {
    @Environment(KeybindStore.self) private var keybindStore
    let action: KeybindAction
    @State private var isRecording = false
    @State private var conflictMessage: String?
    @State private var keyMonitor: Any?

    var body: some View {
        HStack {
            Text(action.label)
                .frame(width: 120, alignment: .leading)

            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Text(isRecording ? "Press shortcut..." : keybindStore.binding(for: action).displayString)
                    .frame(minWidth: 120)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(isRecording ? .orange : .primary)

            Button {
                keybindStore.resetBinding(for: action)
                conflictMessage = nil
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.plain)
            .help("Reset to default")
        }
        .overlay(alignment: .trailing) {
            if let msg = conflictMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .offset(x: 0, y: 20)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        conflictMessage = nil
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Esc cancels recording
            if event.keyCode == 53 /* kVK_Escape */ && mods.isEmpty {
                stopRecording()
                return nil
            }

            // Require at least one modifier
            guard !mods.isEmpty else { return nil }

            let display = buildDisplayString(keyCode: event.keyCode, modifierFlags: event.modifierFlags)
            let chars = event.charactersIgnoringModifiers ?? ""
            let keybind = Keybind(
                keyCode: event.keyCode,
                modifierFlags: mods.rawValue,
                characters: chars,
                displayString: display
            )

            let success = keybindStore.setBinding(keybind, for: action)
            if !success {
                conflictMessage = "Already in use"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    conflictMessage = nil
                }
            }
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
