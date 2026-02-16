import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(KeybindStore.self) private var keybindStore

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    appState.currentMode = .capture
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("General")
                        .font(.title3.bold())

                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }

                    Divider()
                        .padding(.vertical, 4)

                    Text("Keyboard Shortcuts")
                        .font(.title3.bold())

                    ForEach(KeybindAction.allCases, id: \.self) { action in
                        KeybindRecorderView(action: action)
                    }

                    Divider()

                    Button("Reset All to Defaults") {
                        keybindStore.resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
            }
        }
    }
}
