import Foundation
import SwiftUI

/// Represents the lifecycle states of an experiment.
/// Conforms to the project requirements: Assigned, In Progress, Submitted, Verified, Rejected,
/// alongside existing compatibility states: Pending and Completed.
public enum ExperimentStatus: String, Codable, CaseIterable, Identifiable {
    case assigned = "Assigned"
    case inProgress = "In Progress"
    case pending = "Pending"
    case completed = "Completed"
    case submitted = "Submitted"
    case verified = "Verified"
    case rejected = "Rejected"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var badgeColor: Color {
        switch self {
        case .assigned:
            return .blue
        case .inProgress:
            return .indigo
        case .pending:
            return .orange
        case .completed:
            return .teal
        case .submitted:
            return .purple
        case .verified:
            return .green
        case .rejected:
            return .red
        }
    }
    
    public var iconName: String {
        switch self {
        case .assigned:
            return "arrow.down.doc.fill"
        case .inProgress:
            return "hourglass.circle.fill"
        case .pending:
            return "clock.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .submitted:
            return "paperplane.fill"
        case .verified:
            return "checkmark.seal.fill"
        case .rejected:
            return "exclamationmark.triangle.fill"
        }
    }
    
    /// Determines if a student is permitted to edit content in this status.
    public var isEligibleForStudentEdit: Bool {
        switch self {
        case .assigned, .inProgress, .pending, .completed, .rejected:
            return true
        case .submitted, .verified:
            return false // Locked while under review or once verified
        }
    }
    
    /// Determines if a student can submit or resubmit this experiment for mentor verification.
    public var isEligibleForSubmission: Bool {
        switch self {
        case .assigned, .inProgress, .pending, .completed, .rejected:
            return true
        case .submitted, .verified:
            return false
        }
    }
}
