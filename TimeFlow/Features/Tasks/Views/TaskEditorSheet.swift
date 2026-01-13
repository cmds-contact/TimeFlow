import SwiftUI

/// Sheet for creating or editing a task
struct TaskEditorSheet: View {
    // Existing task (for editing)
    var task: TaskItemModel?
    let date: Date?

    // Callbacks
    var onSave: ((String, Int, String?, Int) -> Void)?
    var onSaveExisting: (() -> Void)?
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var estimatedMinutes: Int
    @State private var scheduledDate: Date?
    @State private var notes: String
    @State private var priority: Int
    @State private var showDeleteConfirmation = false

    // Common time presets
    private let timePresets = [15, 30, 45, 60, 90, 120]

    // Creating mode
    init(
        date: Date?,
        onSave: @escaping (String, Int, String?, Int) -> Void
    ) {
        self.task = nil
        self.date = date
        self.onSave = onSave

        _title = State(initialValue: "")
        _estimatedMinutes = State(initialValue: 30)
        _scheduledDate = State(initialValue: date)
        _notes = State(initialValue: "")
        _priority = State(initialValue: 0)
    }

    // Editing mode
    init(
        task: TaskItemModel,
        onSave: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.date = task.scheduledDate
        self.onSaveExisting = onSave
        self.onDelete = onDelete

        _title = State(initialValue: task.title)
        _estimatedMinutes = State(initialValue: task.estimatedMinutes)
        _scheduledDate = State(initialValue: task.scheduledDate)
        _notes = State(initialValue: task.notes ?? "")
        _priority = State(initialValue: task.priority)
    }

    private var isEditing: Bool {
        task != nil
    }

    private var isValid: Bool {
        !title.isEmpty && estimatedMinutes > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Form
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    // Time estimation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated Time: \(TimeFormatter.shared.formatDuration(minutes: estimatedMinutes))")
                            .font(.subheadline)

                        // Preset buttons
                        HStack {
                            ForEach(timePresets, id: \.self) { minutes in
                                Button(TimeFormatter.shared.formatDuration(minutes: minutes)) {
                                    estimatedMinutes = minutes
                                }
                                .buttonStyle(.bordered)
                                .tint(estimatedMinutes == minutes ? .accentColor : .secondary)
                            }
                        }

                        // Custom slider
                        Slider(value: Binding(
                            get: { Double(estimatedMinutes) },
                            set: { estimatedMinutes = Int($0) }
                        ), in: 5...240, step: 5)
                    }

                    // Priority
                    Picker("Priority", selection: $priority) {
                        Text("Normal").tag(0)
                        Text("High").tag(1)
                        Text("Urgent").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Schedule") {
                    Toggle("Schedule for a date", isOn: Binding(
                        get: { scheduledDate != nil },
                        set: { scheduledDate = $0 ? Date() : nil }
                    ))

                    if scheduledDate != nil {
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: { scheduledDate ?? Date() },
                                set: { scheduledDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
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
        .frame(width: 450, height: 550)
        .confirmationDialog(
            "Delete this task?",
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
            Text(isEditing ? "Edit Task" : "New Task")
                .font(.headline)

            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func save() {
        if isEditing {
            task?.title = title
            task?.estimatedMinutes = estimatedMinutes
            task?.scheduledDate = scheduledDate
            task?.notes = notes.isEmpty ? nil : notes
            task?.priority = priority
            onSaveExisting?()
        } else {
            onSave?(title, estimatedMinutes, notes.isEmpty ? nil : notes, priority)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("New Task") {
    TaskEditorSheet(date: Date()) { _, _, _, _ in }
}

#Preview("Edit Task") {
    TaskEditorSheet(
        task: TaskItemModel(
            title: "Review PRs",
            estimatedMinutes: 45,
            scheduledDate: Date(),
            priority: 1
        ),
        onSave: {},
        onDelete: {}
    )
}
