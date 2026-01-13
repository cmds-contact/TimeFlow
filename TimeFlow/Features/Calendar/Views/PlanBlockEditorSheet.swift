import SwiftUI

/// Sheet for creating or editing a plan block
struct PlanBlockEditorSheet: View {
    // Existing block (for editing)
    var block: PlanBlockModel?
    let date: Date

    // Callbacks
    var onSave: ((String, Date, Date, String?, UUID?) -> Void)?
    var onSaveExisting: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note: String
    @State private var isFixed: Bool
    @State private var showDeleteConfirmation = false

    // Editing mode initializer
    init(
        block: PlanBlockModel,
        onSave: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.block = block
        self.date = block.date
        self.onSaveExisting = onSave
        self.onDelete = onDelete

        _title = State(initialValue: block.title)
        _startTime = State(initialValue: block.startAt)
        _endTime = State(initialValue: block.endAt)
        _note = State(initialValue: block.note ?? "")
        _isFixed = State(initialValue: block.isFixed)
    }

    // Creating mode initializer
    init(
        date: Date,
        onSave: @escaping (String, Date, Date, String?, UUID?) -> Void
    ) {
        self.block = nil
        self.date = date
        self.onSave = onSave

        let now = Date()
        let calendar = Calendar.current
        let startOfHour = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour], from: now)
        ) ?? now
        let endOfHour = startOfHour.adding(hours: 1)

        _title = State(initialValue: "")
        _startTime = State(initialValue: startOfHour)
        _endTime = State(initialValue: endOfHour)
        _note = State(initialValue: "")
        _isFixed = State(initialValue: false)
    }

    private var isEditing: Bool {
        block != nil
    }

    private var isValid: Bool {
        !title.isEmpty && endTime > startTime
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Form
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)

                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)

                    Toggle("Fixed (cannot be auto-moved)", isOn: $isFixed)
                }

                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Actions
            HStack {
                if isEditing {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    save()
                }
                .keyboardShortcut(.return)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 400, height: 450)
        .confirmationDialog(
            "Delete this block?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(isEditing ? "Edit Block" : "New Block")
                .font(.headline)

            Spacer()

            Text(date.shortDateString)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Actions

    private func save() {
        if isEditing {
            // Update existing block
            block?.title = title
            block?.startAt = startTime
            block?.endAt = endTime
            block?.note = note.isEmpty ? nil : note
            block?.isFixed = isFixed
            onSaveExisting?()
        } else {
            // Create new block
            onSave?(title, startTime, endTime, note.isEmpty ? nil : note, nil)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("New Block") {
    PlanBlockEditorSheet(date: Date()) { _, _, _, _, _ in }
}

#Preview("Edit Block") {
    let block = PlanBlockModel(
        date: Date(),
        startAt: Date().withTime(hour: 9, minute: 0),
        endAt: Date().withTime(hour: 10, minute: 0),
        title: "Meeting"
    )

    return PlanBlockEditorSheet(
        block: block,
        onSave: {},
        onDelete: {}
    )
}
