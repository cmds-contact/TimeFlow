import SwiftUI
import SwiftData

/// Main task list view
struct TaskListView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject private var appEnvironment: AppEnvironment

    @Query(sort: \TaskItemModel.sortOrder) private var allTasks: [TaskItemModel]

    @State private var filterMode: FilterMode = .all
    @State private var isAddingTask = false
    @State private var editingTask: TaskItemModel?
    @State private var dailyLoad: DailyLoadResult?

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case overdue = "Overdue"

        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "sun.max"
            case .upcoming: return "calendar"
            case .overdue: return "exclamationmark.circle"
            }
        }
    }

    private var filteredTasks: [TaskItemModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch filterMode {
        case .all:
            return allTasks.filter { $0.status == .todo }
        case .today:
            return allTasks.filter { task in
                guard let scheduled = task.scheduledDate else { return false }
                return calendar.isDate(scheduled, inSameDayAs: selectedDate) && task.status == .todo
            }
        case .upcoming:
            return allTasks.filter { task in
                guard let scheduled = task.scheduledDate else { return false }
                return scheduled >= today && task.status == .todo
            }
        case .overdue:
            return allTasks.filter { task in
                guard let scheduled = task.scheduledDate else { return false }
                return scheduled < today && task.status == .todo
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Daily load for today
            if filterMode == .today, let load = dailyLoad {
                DailyLoadIndicator(result: load)
                    .padding()
                Divider()
            }

            // Task list
            if filteredTasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .navigationTitle("Tasks")
        .sheet(isPresented: $isAddingTask) {
            TaskEditorSheet(date: selectedDate) { title, estimatedMinutes, notes, priority in
                try? createTask(
                    title: title,
                    estimatedMinutes: estimatedMinutes,
                    notes: notes,
                    priority: priority
                )
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditorSheet(
                task: task,
                onSave: { try? updateTask(task) },
                onDelete: { try? deleteTask(task) }
            )
        }
        .task(id: selectedDate) {
            await loadDailyLoad()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTask)) { _ in
            isAddingTask = true
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            // Filter picker
            Picker("Filter", selection: $filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Spacer()

            // Date picker for "Today" filter
            if filterMode == .today {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            // Add button
            Button(action: { isAddingTask = true }) {
                Label("Add Task", systemImage: "plus")
            }
            .keyboardShortcut("t", modifiers: .command)
        }
        .padding()
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: { toggleTask(task) },
                    onDelete: { try? deleteTask(task) }
                )
                .onTapGesture {
                    editingTask = task
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(emptyStateMessage)
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Add Task") {
                isAddingTask = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateMessage: String {
        switch filterMode {
        case .all:
            return "No tasks"
        case .today:
            return "No tasks for \(selectedDate.relativeDateString)"
        case .upcoming:
            return "No upcoming tasks"
        case .overdue:
            return "No overdue tasks"
        }
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
            scheduledDate: filterMode == .today ? selectedDate : nil,
            notes: notes,
            priority: priority
        )
        Task { await loadDailyLoad() }
    }

    private func updateTask(_ task: TaskItemModel) throws {
        try appEnvironment.useCases.updateTask.execute(
            id: task.id,
            title: task.title,
            estimatedMinutes: task.estimatedMinutes,
            scheduledDate: task.scheduledDate,
            notes: task.notes,
            priority: task.priority
        )
        editingTask = nil
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

    private func deleteTask(_ task: TaskItemModel) throws {
        try appEnvironment.useCases.deleteTask.execute(id: task.id)
        Task { await loadDailyLoad() }
    }
}

// MARK: - Preview

#Preview {
    TaskListView(selectedDate: .constant(Date()))
        .environmentObject(AppEnvironment())
}
