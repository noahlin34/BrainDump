import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var permissionTimer: Timer?

    private let totalPages = 5

    private let pages: [(icon: String, title: String, body: String)] = [
        ("brain.head.profile",
         "Welcome to BrainDump",
         "A quick-capture tool.\nDump thoughts, review later, keep what matters."),
        ("square.and.pencil",
         "Capture",
         "Type and press Cmd+Return to save.\nNo organizing needed."),
        ("keyboard",
         "Quick Access & Review",
         "Press Ctrl+Shift+D from anywhere.\nSwipe right to keep, left to trash."),
        // Page 3 (permissions) is custom — not in this array
        ("archivebox",
         "Saved Notes",
         "Kept notes live in Saved Notes.\nYou're ready to go.")
    ]

    /// Maps page index to the pages array index (skipping the custom permissions page at index 3)
    private func dataIndex(for page: Int) -> Int? {
        switch page {
        case 0, 1, 2: return page
        case 3: return nil // custom permissions page
        case 4: return 3
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if currentPage == 3 {
                permissionsPage
            } else if let idx = dataIndex(for: currentPage) {
                Image(systemName: pages[idx].icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text(pages[idx].title)
                    .font(.title2.bold())

                Text(pages[idx].body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 300)
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }

            Button {
                if currentPage < totalPages - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
                    appState.currentMode = .capture
                }
            } label: {
                Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: currentPage) {
            if currentPage == 3 {
                startPermissionPolling()
            } else {
                stopPermissionPolling()
            }
        }
        .onDisappear {
            stopPermissionPolling()
        }
    }

    // MARK: - Permissions Page

    private var permissionsPage: some View {
        VStack(spacing: 16) {
            Image(systemName: accessibilityGranted ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(accessibilityGranted ? .green : .secondary)

            Text("Enable Global Shortcut")
                .font(.title2.bold())

            Text("BrainDump needs **Accessibility** permission so the Ctrl+Shift+D shortcut works from any app — even when BrainDump isn't in the foreground.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 320)

            if accessibilityGranted {
                Label("Permission granted — you're all set!", systemImage: "checkmark.circle.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.green)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Here's how:")
                        .font(.callout.bold())

                    stepRow(number: "1", text: "Click **Open Settings** below")
                    stepRow(number: "2", text: "Find **BrainDump** in the list")
                    stepRow(number: "3", text: "Flip the toggle **on**")
                    stepRow(number: "4", text: "Come back here — we'll detect it automatically")
                }
                .padding(16)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)

                Text("You can always do this later in\nSystem Settings → Privacy & Security → Accessibility")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func stepRow(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Circle())

            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        accessibilityGranted = AXIsProcessTrusted()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let granted = AXIsProcessTrusted()
            if granted != accessibilityGranted {
                withAnimation { accessibilityGranted = granted }
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }
}
