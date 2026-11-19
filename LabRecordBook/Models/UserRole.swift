import Foundation
import SwiftUI

/// Defines the three core roles within the Lab Record Book system.
public enum UserRole: String, Codable, CaseIterable, Identifiable {
    case admin = "Admin"
    case mentor = "Mentor"
    case student = "Student"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .admin:
            return "person.badge.key.fill"
        case .mentor:
            return "person.crop.rectangle.badge.plus"
        case .student:
            return "graduationcap.fill"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .admin:
            return .purple
        case .mentor:
            return .indigo
        case .student:
            return .blue
        }
    }
}
