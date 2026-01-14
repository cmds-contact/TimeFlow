import SwiftUI

/// Single row in the daily plan table
struct DailyPlanRowView: View {
    let item: DailyPlanItemModel
    let isEditing: Bool
    let onToggleCompletion: () -> Void
    let onStartEditing: () -> Void
    let onEndEditing: (String, Int) -> Void
    let onDelete: () -> Void

    @State private var editTitle: String = ""
    @State private var editMinutes: Int = 30
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundColor(.secondary.opacity(isHovering ? 0.8 : 0.3))

            // Checkbox
            Button(action: onToggleCompletion) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                editingContent
            } else {
                normalContent
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.secondary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture(count: 2) {
            startEditing()
        }
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        HStack {
            // Title
            Text(item.title)
                .font(.body)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .secondary : .primary)

            Spacer()

            // Estimated time
            Text(item.estimatedTimeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
    }

    // MARK: - Editing Content

    @State private var customMinutesText: String = ""
    @State private var useCustomMinutes: Bool = false

    private var editingContent: some View {
        HStack(spacing: 8) {
            TextField("Title", text: $editTitle)
                .textFieldStyle(.roundedBorder)

            // Time picker with custom option
            HStack(spacing: 4) {
                if useCustomMinutes {
                    HStack(spacing: 2) {
                        TextField("", text: $customMinutesText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                            .onChange(of: customMinutesText) { _, newValue in
                                if let minutes = Int(newValue), minutes > 0 {
                                    editMinutes = minutes
                                }
                            }
                        Text("m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Picker("", selection: $editMinutes) {
                        Text("15m").tag(15)
                        Text("30m").tag(30)
                        Text("45m").tag(45)
                        Text("1h").tag(60)
                        Text("1.5h").tag(90)
                        Text("2h").tag(120)
                        Text("3h").tag(180)
                    }
                    .frame(width: 70)
                }

                Button(action: {
                    useCustomMinutes.toggle()
                    if useCustomMinutes {
                        customMinutesText = "\(editMinutes)"
                    }
                }) {
                    Image(systemName: useCustomMinutes ? "list.bullet" : "pencil")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help(useCustomMinutes ? "Use preset times" : "Enter custom time")
            }

            Button("Done") {
                onEndEditing(editTitle, editMinutes)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button("Cancel") {
                onEndEditing(item.title, item.estimatedMinutes)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Actions

    private func startEditing() {
        editTitle = item.title
        editMinutes = item.estimatedMinutes
        onStartEditing()
    }
}

// MARK: - Preview

#Preview {
    VStack {
        DailyPlanRowView(
            item: DailyPlanItemModel(
                date: Date(),
                title: "Sample task",
                estimatedMinutes: 60
            ),
            isEditing: false,
            onToggleCompletion: {},
            onStartEditing: {},
            onEndEditing: { _, _ in },
            onDelete: {}
        )

        DailyPlanRowView(
            item: DailyPlanItemModel(
                date: Date(),
                title: "Completed task",
                estimatedMinutes: 30,
                isCompleted: true
            ),
            isEditing: false,
            onToggleCompletion: {},
            onStartEditing: {},
            onEndEditing: { _, _ in },
            onDelete: {}
        )
    }
    .padding()
}
