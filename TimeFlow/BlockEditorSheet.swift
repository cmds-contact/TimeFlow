import SwiftUI
import SwiftData

/// Sheet for creating/editing time blocks
struct BlockEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var block: TimeBlock
    let isNew: Bool
    let onDelete: (() -> Void)?

    @State private var showDeleteConfirmation = false

    init(block: TimeBlock, isNew: Bool = false, onDelete: (() -> Void)? = nil) {
        self.block = block
        self.isNew = isNew
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            Divider()

            // Content
            Form {
                Section {
                    TextField("Title", text: $block.title)
                        .textFieldStyle(.plain)
                }

                Section("Time") {
                    DatePicker("Start", selection: $block.startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $block.endAt, displayedComponents: [.date, .hourAndMinute])

                    // Duration display
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(block.durationMinutes))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack {
                        Text("Source")
                        Spacer()
                        Label(
                            block.source == TimeBlock.sourceTimer ? "Timer" : "Manual",
                            systemImage: block.source == TimeBlock.sourceTimer ? "timer" : "pencil"
                        )
                        .foregroundStyle(.secondary)
                    }
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Block", systemImage: "trash")
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 350, minHeight: 400)
        .confirmationDialog("Delete this block?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Cancel") {
                if isNew {
                    modelContext.delete(block)
                }
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Text(isNew ? "New Block" : "Edit Block")
                .fontWeight(.semibold)

            Spacer()

            Button("Save") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!block.isValid)
        }
        .padding()
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 0 {
            return "Invalid"
        }
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    BlockEditorSheet(
        block: TimeBlock(
            startAt: Date(),
            endAt: Date().addingTimeInterval(3600),
            title: "Sample Block"
        ),
        isNew: true
    )
}
