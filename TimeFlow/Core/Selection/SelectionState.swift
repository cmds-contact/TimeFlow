import SwiftUI
import Combine

/// Manages selection state for plan and actual blocks across the calendar
@MainActor
final class SelectionState: ObservableObject {
    @Published var selectedPlanBlock: PlanBlockModel?
    @Published var selectedActualBlock: ActualBlockModel?

    /// Returns true if any block is selected
    var hasSelection: Bool {
        selectedPlanBlock != nil || selectedActualBlock != nil
    }

    /// Select a plan block (clears any actual block selection)
    func selectPlan(_ block: PlanBlockModel?) {
        selectedActualBlock = nil
        selectedPlanBlock = block
    }

    /// Select an actual block (clears any plan block selection)
    func selectActual(_ block: ActualBlockModel?) {
        selectedPlanBlock = nil
        selectedActualBlock = block
    }

    /// Clear all selections
    func clearSelection() {
        selectedPlanBlock = nil
        selectedActualBlock = nil
    }

    /// Check if a specific plan block is selected
    func isPlanBlockSelected(_ block: PlanBlockModel) -> Bool {
        selectedPlanBlock?.id == block.id
    }

    /// Check if a specific actual block is selected
    func isActualBlockSelected(_ block: ActualBlockModel) -> Bool {
        selectedActualBlock?.id == block.id
    }
}
