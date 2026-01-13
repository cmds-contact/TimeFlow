import SwiftUI
import SwiftData

/// Sidebar showing tasks for the selected date
struct TaskSidebarView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject private var appEnvironment: AppEnvironment

    @Query private var allTasks: [TaskItemModel]

    private var todayTasks: [TaskItemModel] {
        let calendar = Calendar.current
        return allTasks
            .filter { task in
                guard let scheduled = task.scheduledDate else { return false }
                return calendar.isDate(scheduled, inSameDayAs: selectedDate)
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    @State private var dailyLoad: DailyLoadResult?
    @State private var isAddingTask = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Daily load indicator
            if let load = dailyLoad {
                DailyLoadIndicator(result: load)
                    .padding()

                Divider()
            }

            // Task list
            if todayTasks.isEmpty {
                emptyState
            } else {
                taskList
            }

            Divider()

            // Add task button
            Button(action: { isAddingTask = true }) {
                Label("Add Task", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding()
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $isAddingTask) {
            TaskEditorSheet(
                date: selectedDate,
                onSave: { title, estimatedMinutes, notes, priority in
                    try? createTask(
                        title: title,
                        estimatedMinutes: estimatedMinutes,
                        notes: notes,
                        priority: priority
                    )
                }
            )
        }
        .task(id: selectedDate) {
            await loadDailyLoad()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTask)) { _ in
            isAddingTask = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Tasks")
                .font(.headline)

            Spacer()

            Text("\(todayTasks.count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.2)))
        }
        .padding()
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(todayTasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: { toggleTask(task) },
                    onDelete: { deleteTask(task) }
                )
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No tasks scheduled")
                .foregroundStyle(.secondary)

            Text("for \(selectedDate.relativeDateString)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func loadDailyLoad() async {
        do {
            dailyLoad = try appEnvironment.useCases.calculateDailyLoad.execute(for: selectedDate)
        } catch {
            print("Error loading daily load: \(error)")
        }
    }

    private func createTask(
        title: String,
        estimatedMinutes: Int,
        notes: String?,
        priority: Int
    ) throws {
        _ = try appEnvironment.useCases.createTask.execute(
            title: title,
            estimatedMinutes: estimatedMinutes,
            scheduledDate: selectedDate,
            notes: notes,
            priority: priority
        )
        Task { await loadDailyLoad() }
    }

    private func toggleTask(_ task: TaskItemModel) {
        do {
            try appEnvironment.useCases.completeTask.toggle(id: task.id)
            Task { await loadDailyLoad() }
        } catch {
            print("Error toggling task: \(error)")
        }
    }

    private func deleteTask(_ task: TaskItemModel) {
        do {
            try appEnvironment.useCases.deleteTask.execute(id: task.id)
            Task { await loadDailyLoad() }
        } catch {
            print("Error deleting task: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    TaskSidebarView(selectedDate: .constant(Date()))
        .environmentObject(AppEnvironment())
        .frame(width: 300, height: 600)
}
