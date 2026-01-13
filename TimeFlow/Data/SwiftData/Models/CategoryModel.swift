import Foundation
import SwiftUI
import SwiftData

/// SwiftData model for categories (for grouping and coloring blocks)
@Model
final class CategoryModel {

    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// Category name
    var name: String

    /// Color as hex string (e.g., "#FF5733")
    var colorHex: String

    /// Optional icon name (SF Symbol)
    var iconName: String?

    /// Sort order
    var sortOrder: Int

    /// Created timestamp
    var createdAt: Date

    // MARK: - Computed Properties

    /// SwiftUI Color from hex
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        iconName: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Identifiable

extension CategoryModel: Identifiable {}

// MARK: - Hashable

extension CategoryModel: Hashable {
    static func == (lhs: CategoryModel, rhs: CategoryModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Default Categories

extension CategoryModel {
    static let defaultCategories: [(name: String, colorHex: String, icon: String?)] = [
        ("Work", "#3B82F6", "briefcase"),
        ("Personal", "#10B981", "person"),
        ("Health", "#EF4444", "heart"),
        ("Learning", "#8B5CF6", "book"),
        ("Social", "#F59E0B", "person.2"),
        ("Creative", "#EC4899", "paintbrush"),
        ("Admin", "#6B7280", "folder")
    ]
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components else {
            return "#000000"
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
