import SwiftUI

/// Container view for the right sidebar that switches between block detail and task list
struct RightSidebarView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject private var selectionState: SelectionState

    var body: some View {
        VStack(spacing: 0) {
            if selectionState.hasSelection {
                BlockDetailView()
            } else {
                TaskSidebarView(selectedDate: $selectedDate)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Preview

#Preview("No Selection") {
    RightSidebarView(selectedDate: .constant(Date()))
        .environmentObject(SelectionState())
        .frame(width: 300, height: 600)
}

#Preview("With Selection") {
    RightSidebarView(selectedDate: .constant(Date()))
        .environmentObject(SelectionState())
        .frame(width: 300, height: 600)
}
