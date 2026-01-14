import SwiftUI

/// Detail view for editing a selected block in the right sidebar
struct BlockDetailView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @EnvironmentObject private var selectionState: SelectionState

    // Editing state
    @State private var title: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var note: String = ""
    @State private var isFixed: Bool = false
    @State private var hasChanges: Bool = false

    // For Actual blocks
    @State private var actualTitle: String = ""
    @State private var actualStartTime: Date = Date()
    @State private var actualEndTime: Date = Date()

    private var isPlanBlock: Bool {
        selectionState.selectedPlanBlock != nil
    }

    private var isActualBlock: Bool {
        selectionState.selectedActualBlock != nil
    }

    private var isValid: Bool {
        if isPlanBlock {
            return !title.trimmingCharacters(in: .whitespaces).isEmpty && endTime > startTime
        } else if isActualBlock {
            return actualEndTime > actualStartTime
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isPlanBlock {
                        planBlockForm
                    } else if isActualBlock {
                        actualBlockForm
                    }
                }
                .padding()
            }

            Divider()

            // Actions
            actionButtons
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            loadBlockData()
        }
        .onChange(of: selectionState.selectedPlanBlock) { _, _ in
            loadBlockData()
        }
        .onChange(of: selectionState.selectedActualBlock) { _, _ in
            loadBlockData()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if isPlanBlock {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.accentColor)
                Text("Plan Block")
                    .font(.headline)
            } else if isActualBlock {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.green)
                Text("Actual Block")
                    .font(.headline)
            }

            Spacer()

            Button {
                selectionState.clearSelection()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Plan Block Form

    private var planBlockForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: title) { _, _ in hasChanges = true }
            }

            // Time
            VStack(alignment: .leading, spacing: 4) {
                Text("Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: startTime) { _, _ in hasChanges = true }

                    Text("-")
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: endTime) { _, _ in hasChanges = true }
                }
            }

            // Duration display
            if let duration = durationText {
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Fixed toggle
            Toggle("Fixed (cannot be auto-moved)", isOn: $isFixed)
                .onChange(of: isFixed) { _, _ in hasChanges = true }

            // Notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $note)
                    .frame(minHeight: 80)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                    .onChange(of: note) { _, _ in hasChanges = true }
            }
        }
    }

    // MARK: - Actual Block Form

    private var actualBlockForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title (optional for actual blocks)
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Title (optional)", text: $actualTitle)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: actualTitle) { _, _ in hasChanges = true }
            }

            // Time
            VStack(alignment: .leading, spacing: 4) {
                Text("Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    DatePicker("", selection: $actualStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: actualStartTime) { _, _ in hasChanges = true }

                    Text("-")
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: $actualEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: actualEndTime) { _, _ in hasChanges = true }
                }
            }

            // Duration display
            if let duration = actualDurationText {
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Source info
            if let block = selectionState.selectedActualBlock {
                HStack {
                    Image(systemName: block.source.icon)
                        .foregroundStyle(.secondary)
                    Text("Source: \(block.source.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack {
            // Delete button
            Button(role: .destructive) {
                deleteBlock()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Spacer()

            // Cancel button
            Button("Cancel") {
                loadBlockData() // Reset changes
                hasChanges = false
            }
            .disabled(!hasChanges)

            // Save button
            Button("Save") {
                saveChanges()
            }
            .disabled(!hasChanges || !isValid)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
    }

    // MARK: - Helper Properties

    private var durationText: String? {
        guard endTime > startTime else { return nil }
        let minutes = Int(endTime.timeIntervalSince(startTime) / 60)
        return TimeFormatter.shared.formatDuration(minutes: minutes)
    }

    private var actualDurationText: String? {
        guard actualEndTime > actualStartTime else { return nil }
        let minutes = Int(actualEndTime.timeIntervalSince(actualStartTime) / 60)
        return TimeFormatter.shared.formatDuration(minutes: minutes)
    }

    // MARK: - Actions

    private func loadBlockData() {
        if let block = selectionState.selectedPlanBlock {
            title = block.title
            startTime = block.startAt
            endTime = block.endAt
            note = block.note ?? ""
            isFixed = block.isFixed
        } else if let block = selectionState.selectedActualBlock {
            actualTitle = block.title ?? ""
            actualStartTime = block.startAt
            actualEndTime = block.endAt
        }
        hasChanges = false
    }

    private func saveChanges() {
        if let block = selectionState.selectedPlanBlock {
            do {
                try appEnvironment.useCases.updatePlanBlock.execute(
                    id: block.id,
                    title: title,
                    startAt: startTime,
                    endAt: endTime,
                    note: note.isEmpty ? nil : note,
                    categoryId: block.categoryId,
                    isFixed: isFixed
                )
                hasChanges = false
            } catch {
                print("Error saving plan block: \(error)")
            }
        } else if let block = selectionState.selectedActualBlock {
            do {
                try appEnvironment.useCases.updateActualBlock.execute(
                    id: block.id,
                    title: actualTitle.isEmpty ? nil : actualTitle,
                    startAt: actualStartTime,
                    endAt: actualEndTime
                )
                hasChanges = false
            } catch {
                print("Error saving actual block: \(error)")
            }
        }
    }

    private func deleteBlock() {
        if let block = selectionState.selectedPlanBlock {
            do {
                try appEnvironment.useCases.deletePlanBlock.execute(id: block.id)
                selectionState.clearSelection()
            } catch {
                print("Error deleting plan block: \(error)")
            }
        } else if let block = selectionState.selectedActualBlock {
            do {
                try appEnvironment.useCases.deleteActualBlock.execute(id: block.id)
                selectionState.clearSelection()
            } catch {
                print("Error deleting actual block: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BlockDetailView()
        .environmentObject(AppEnvironment())
        .environmentObject(SelectionState())
        .frame(width: 300, height: 500)
}
