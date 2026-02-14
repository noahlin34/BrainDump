import SwiftUI

struct TutorialView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0

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
        ("archivebox",
         "Saved Notes",
         "Kept notes live in Saved Notes.\nYou're ready to go.")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: pages[currentPage].icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(pages[currentPage].title)
                .font(.title2.bold())

            Text(pages[currentPage].body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
                    appState.currentMode = .capture
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
