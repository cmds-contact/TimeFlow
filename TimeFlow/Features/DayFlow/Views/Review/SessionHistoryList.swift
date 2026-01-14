import SwiftUI

/// List showing session history (plan blocks and actual blocks)
struct SessionHistoryList: View {
    let planBlocks: [PlanBlockModel]
    let actualBlocks: [ActualBlockModel]

    @State private var selectedTab: HistoryTab = .all

    enum HistoryTab: String, CaseIterable {
        case all = "All"
        case planned = "Planned"
        case actual = "Actual"
    }

    private var allItems: [SessionHistoryItem] {
        var items: [SessionHistoryItem] = []

        items.append(contentsOf: planBlocks.map { block in
            SessionHistoryItem(
                id: block.id,
                type: .plan,
                title: block.title,
                startAt: block.startAt,
                endAt: block.endAt,
                source: nil
            )
        })

        items.append(contentsOf: actualBlocks.map { block in
            SessionHistoryItem(
                id: block.id,
                type: .actual,
                title: block.title ?? "Untitled",
                startAt: block.startAt,
                endAt: block.endAt,
                source: block.source
            )
        })

        return items.sorted { $0.startAt < $1.startAt }
    }

    private var filteredItems: [SessionHistoryItem] {
        switch selectedTab {
        case .all:
            return allItems
        case .planned:
            return allItems.filter { $0.type == .plan }
        case .actual:
            return allItems.filter { $0.type == .actual }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with tabs
            HStack {
                Text("Session History")
                    .font(.headline)

                Spacer()

                Picker("Filter", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            // List
            if filteredItems.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        SessionHistoryRow(item: item)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No sessions yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Session History Item

struct SessionHistoryItem: Identifiable {
    let id: UUID
    let type: SessionType
    let title: String
    let startAt: Date
    let endAt: Date
    let source: RecordSource?

    enum SessionType {
        case plan
        case actual
    }

    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startAt)) - \(formatter.string(from: endAt))"
    }

    var durationString: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Session History Row

struct SessionHistoryRow: View {
    let item: SessionHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Circle()
                .fill(item.type == .plan ? Color.blue : Color.green)
                .frame(width: 8, height: 8)

            // Time range
            Text(item.timeRange)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            // Title
            Text(item.title)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // Source (for actual blocks)
            if let source = item.source {
                sourceIcon(source)
            }

            // Duration
            Text(item.durationString)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func sourceIcon(_ source: RecordSource) -> some View {
        switch source {
        case .manual:
            Image(systemName: "pencil")
                .font(.caption)
                .foregroundColor(.secondary)
        case .timer:
            Image(systemName: "stopwatch")
                .font(.caption)
                .foregroundColor(.orange)
        case .pomodoro:
            Image(systemName: "timer")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}

// MARK: - Preview

#Preview {
    SessionHistoryList(
        planBlocks: [],
        actualBlocks: []
    )
    .frame(width: 500)
}
