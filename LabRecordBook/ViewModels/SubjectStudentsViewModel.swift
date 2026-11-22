import Foundation
import Observation

/// ViewModel for Mentor managing students in a specific subject.
/// Supports search, department filter, status filter, and 7 sorting modes.
@Observable
public final class SubjectStudentsViewModel {
    public enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "Name (A–Z)"
        case nameDescending = "Name (Z–A)"
        case progressHighest = "Progress (Highest First)"
        case progressLowest = "Progress (Lowest First)"
        case experimentsCount = "Experiments (Most First)"
        case pendingReviews = "Pending (Most First)"
        case attentionRequired = "Attention Required First"
        
        public var id: String { rawValue }
    }
    
    public enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case verified = "Completed (100%)"
        case inProgress = "In Progress"
        case needsAttention = "Needs Attention"
        
        public var id: String { rawValue }
    }
    
    public let subject: Subject
    public let mentor: User
    public let dataStore: AppDataStore
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var statusFilter: StatusFilter = .all
    public var sortOption: SortOption = .nameAscending
    
    public init(subject: Subject, mentor: User, dataStore: AppDataStore) {
        self.subject = subject
        self.mentor = mentor
        self.dataStore = dataStore
    }
    
    /// Students allocated to this mentor in this subject
    public var allocatedStudents: [User] {
        let studentIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.subjectId == subject.id && $0.mentorId == mentor.id && $0.isActive }
            .map { $0.studentId })
        return dataStore.users.filter { studentIds.contains($0.id) && $0.isActive }
    }
    
    public var availableDepartments: [String] {
        let depts = Set(allocatedStudents.map { $0.department })
        return ["All"] + Array(depts).sorted()
    }
    
    public func progressSummary(for student: User) -> StudentProgressSummary {
        let exps = dataStore.experiments.filter {
            $0.studentId == student.id && $0.subjectId == subject.id
        }
        let verified = exps.filter { $0.status == .verified }.count
        let rejected = exps.filter { $0.status == .rejected }.count
        let pending = exps.filter { $0.status != .verified && $0.status != .rejected }.count
        
        return StudentProgressSummary(
            student: student,
            totalAssigned: exps.count,
            verifiedCount: verified,
            pendingCount: pending,
            rejectedCount: rejected
        )
    }
    
    public var filteredAndSortedStudents: [User] {
        var result = allocatedStudents.filter { student in
            let summary = progressSummary(for: student)
            
            // Status Filter
            switch statusFilter {
            case .all:
                break
            case .verified:
                if summary.completionPercentage < 100 || summary.totalAssigned == 0 { return false }
            case .inProgress:
                if summary.completionPercentage >= 100 && summary.totalAssigned > 0 { return false }
            case .needsAttention:
                if !summary.requiresAttention { return false }
            }
            
            // Department Filter
            if selectedDepartment != "All" && student.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                return false
            }
            
            // Search Text (name or username)
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                let nameMatch = student.name.lowercased().contains(query)
                let userMatch = student.username.lowercased().contains(query)
                return nameMatch || userMatch
            }
            return true
        }
        
        // 7 Sorting Options
        result.sort { a, b in
            let summaryA = progressSummary(for: a)
            let summaryB = progressSummary(for: b)
            
            switch sortOption {
            case .nameAscending:
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .nameDescending:
                return a.name.localizedStandardCompare(b.name) == .orderedDescending
            case .progressHighest:
                if summaryA.completionPercentage != summaryB.completionPercentage {
                    return summaryA.completionPercentage > summaryB.completionPercentage
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .progressLowest:
                if summaryA.completionPercentage != summaryB.completionPercentage {
                    return summaryA.completionPercentage < summaryB.completionPercentage
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .experimentsCount:
                if summaryA.totalAssigned != summaryB.totalAssigned {
                    return summaryA.totalAssigned > summaryB.totalAssigned
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .pendingReviews:
                if summaryA.pendingCount != summaryB.pendingCount {
                    return summaryA.pendingCount > summaryB.pendingCount
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .attentionRequired:
                if summaryA.requiresAttention != summaryB.requiresAttention {
                    return summaryA.requiresAttention && !summaryB.requiresAttention
                }
                return summaryA.rejectedCount > summaryB.rejectedCount
            }
        }
        
        return result
    }
}
