import SwiftUI
import SwiftData

/// Table view for daily plan items with estimated time
struct DailyPlanTableView: View {
    let selectedDate: Date

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Query private var allItems: [DailyPlanItemModel]

    @State private var newItemTitle: String = ""
    @State private var newItemMinutes: Int = 30
    @State private var editingItemId: UUID?

    private var items: [DailyPlanItemModel] {
        let calendar = Calendar.current
        return allItems.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var stats: DailyPlanStats? {
        try? appEnvironment.useCases.calculateDailyPlanStats.execute(for: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            tableHeader

            Divider()

            // Item list
            if items.isEmpty {
                emptyState
            } else {
                itemList
            }

            Divider()

            // Add new item form
            addItemForm

            Divider()

            // Stats footer
            if let stats = stats {
                PlanStatsFooter(stats: stats)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Header

    private var tableHeader: some View {
        HStack {
            Text("Daily Plan")
                .font(.headline)

            Spacer()

            Text("\(items.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No items planned")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add items below to plan your day")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Item List

    private var itemList: some View {
        List {
            ForEach(items) { item in
                DailyPlanRowView(
                    item: item,
                    isEditing: editingItemId == item.id,
                    onToggleCompletion: {
                        toggleCompletion(item)
                    },
                    onStartEditing: {
                        editingItemId = item.id
                    },
                    onEndEditing: { title, minutes in
                        updateItem(item, title: title, minutes: minutes)
                        editingItemId = nil
                    },
                    onDelete: {
                        deleteItem(item)
                    }
                )
            }
            .onMove(perform: moveItems)
        }
        .listStyle(.plain)
    }

    // MARK: - Add Item Form

    private var addItemForm: some View {
        HStack(spacing: 12) {
            TextField("Add new item...", text: $newItemTitle)
                .textFieldStyle(.roundedBorder)

            Picker("", selection: $newItemMinutes) {
                Text("15m").tag(15)
                Text("30m").tag(30)
                Text("45m").tag(45)
                Text("1h").tag(60)
                Text("1.5h").tag(90)
                Text("2h").tag(120)
                Text("3h").tag(180)
            }
            .frame(width: 80)

            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }

    // MARK: - Actions

    private func addItem() {
        let title = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        do {
            _ = try appEnvironment.useCases.createDailyPlanItem.execute(
                date: selectedDate,
                title: title,
                estimatedMinutes: newItemMinutes
            )
            newItemTitle = ""
        } catch {
            print("Error creating daily plan item: \(error)")
        }
    }

    private func toggleCompletion(_ item: DailyPlanItemModel) {
        do {
            try appEnvironment.useCases.updateDailyPlanItem.toggleCompletion(id: item.id)
        } catch {
            print("Error toggling completion: \(error)")
        }
    }

    private func updateItem(_ item: DailyPlanItemModel, title: String, minutes: Int) {
        do {
            try appEnvironment.useCases.updateDailyPlanItem.execute(
                id: item.id,
                title: title,
                estimatedMinutes: minutes
            )
        } catch {
            print("Error updating item: \(error)")
        }
    }

    private func deleteItem(_ item: DailyPlanItemModel) {
        do {
            try appEnvironment.useCases.deleteDailyPlanItem.execute(id: item.id)
        } catch {
            print("Error deleting item: \(error)")
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var mutableItems = items
        mutableItems.move(fromOffsets: source, toOffset: destination)

        do {
            try appEnvironment.useCases.reorderDailyPlanItems.execute(items: mutableItems)
        } catch {
            print("Error reordering items: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    DailyPlanTableView(selectedDate: Date())
        .environmentObject(AppEnvironment())
        .frame(width: 350)
}
