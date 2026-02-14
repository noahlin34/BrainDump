import SwiftUI

struct NoteCardView: View {
    let note: Note
    var onSave: () -> Void
    var onDelete: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    private var dragProgress: CGFloat {
        offset.width / 150
    }

    private var rotation: Angle {
        .degrees(Double(offset.width) / 20)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 12) {
                    ScrollView {
                        Text(note.content)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 0)

                    Text(note.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)

                // KEEP label
                if dragProgress > 0 {
                    Text("KEEP")
                        .font(.title.bold())
                        .foregroundStyle(.green)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.green, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(-15))
                        .opacity(Double(min(dragProgress, 1)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(24)
                }

                // NOPE label
                if dragProgress < 0 {
                    Text("NOPE")
                        .font(.title.bold())
                        .foregroundStyle(.red)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.red, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(15))
                        .opacity(Double(min(-dragProgress, 1)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(offset)
            .rotationEffect(rotation)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        offset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        if value.translation.width > 150 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                offset = CGSize(width: 500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSave()
                            }
                        } else if value.translation.width < -150 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                offset = CGSize(width: -500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete()
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                    }
            )
            .animation(.interactiveSpring, value: isDragging)

            // Accessibility buttons
            HStack(spacing: 40) {
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: -500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: 500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSave()
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
        }
    }
}
