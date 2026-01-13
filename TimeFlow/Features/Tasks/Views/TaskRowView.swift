import SwiftUI

/// Single task row in task list
struct TaskRowView: View {
    let task: TaskItemModel
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                    if task.priority > 0 {
                        priorityBadge
                    }
                }

                HStack(spacing: 8) {
                    // Estimated time
                    Label(task.estimatedTimeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Scheduled date
                    if let scheduled = task.scheduledDate {
                        Label(scheduled.relativeDateString, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                }
            }

            Spacer()

            // Delete button (on hover)
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Priority Badge

    private var priorityBadge: some View {
        Text(priorityLabel)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundStyle(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityLabel: String {
        switch task.priority {
        case 2: return "Urgent"
        case 1: return "High"
        default: return ""
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case 2: return .red
        case 1: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TaskRowView(
            task: TaskItemModel(
                title: "Review PRs",
                estimatedMinutes: 30,
                scheduledDate: Date(),
                priority: 1
            ),
            onToggle: {},
            onDelete: {}
        )

        TaskRowView(
            task: TaskItemModel(
                title: "Completed task",
                estimatedMinutes: 15,
                status: .done
            ),
            onToggle: {},
            onDelete: {}
        )
    }
    .padding()
}
