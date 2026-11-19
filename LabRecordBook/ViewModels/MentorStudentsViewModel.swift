import Foundation
import Observation

/// ViewModel for viewing, searching, and filtering students assigned to the current mentor by department and progress status.
@Observable
public final class MentorStudentsViewModel {
    public enum StudentStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case pendingReview = "Pending Review"
        case needsRevision = "Needs Revision"
        case completed = "Completed"
        case active = "Active"
        case inactive = "Inactive"
        
        public var id: String { rawValue }
    }
    
    public let mentor: User
    public let dataStore: AppDataStore
    public let assignmentService: AssignmentService
    public let experimentService: ExperimentService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var statusFilter: StudentStatusFilter = .all
    
    public init(mentor: User, dataStore: AppDataStore) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.assignmentService = AssignmentService(dataStore: dataStore)
        self.experimentService = ExperimentService(dataStore: dataStore)
    }
    
    /// All students assigned to this mentor
    public var assignedStudents: [User] {
        assignmentService.getAssignedStudents(forMentor: mentor)
    }
    
    /// Unique departments among the mentor's assigned students (plus institution departments)
    public var availableDepartments: [String] {
        let depts = Set(assignedStudents.map { $0.department })
        return ["All"] + Array(depts).sorted()
    }
    
    /// Filtered students matching department, status filter, and search query
    public var filteredStudents: [User] {
        assignedStudents.filter { student in
            // Department filter
            if selectedDepartment != "All" {
                if student.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                    return false
                }
            }
            
            // Status / progress filter
            switch statusFilter {
            case .all:
                break
            case .pendingReview:
                if !hasPendingReview(student: student) { return false }
            case .needsRevision:
                if !hasNeedsRevision(student: student) { return false }
            case .completed:
                if !isCompleted(student: student) { return false }
            case .active:
                if !student.isActive { return false }
            case .inactive:
                if student.isActive { return false }
            }
            
            // Search text
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmed.isEmpty {
                let nameMatch = student.name.lowercased().contains(trimmed)
                let usernameMatch = student.username.lowercased().contains(trimmed)
                let deptMatch = student.department.lowercased().contains(trimmed)
                return nameMatch || usernameMatch || deptMatch
            }
            
            return true
        }
    }
    
    public func hasPendingReview(student: User) -> Bool {
        dataStore.experiments.contains {
            $0.studentId == student.id && $0.status == .submitted
        }
    }
    
    public func hasNeedsRevision(student: User) -> Bool {
        dataStore.experiments.contains {
            $0.studentId == student.id && $0.status == .rejected
        }
    }
    
    public func isCompleted(student: User) -> Bool {
        let total = assignmentsCount(for: student)
        return total > 0 && completedCount(for: student) == total
    }
    
    /// Total assignments for a specific student from this mentor
    public func assignmentsCount(for student: User) -> Int {
        dataStore.assignments.filter {
            $0.mentorId == mentor.id && $0.studentId == student.id
        }.count
    }
    
    /// Completed assignments for a specific student from this mentor
    public func completedCount(for student: User) -> Int {
        dataStore.assignments.filter {
            $0.mentorId == mentor.id && $0.studentId == student.id && $0.isCompleted
        }.count
    }
    
    /// Completion progress percentage (0.0 to 1.0)
    public func progress(for student: User) -> Double {
        let total = assignmentsCount(for: student)
        guard total > 0 else { return 0.0 }
        let completed = completedCount(for: student)
        return Double(completed) / Double(total)
    }
    
    /// Formatted progress text: e.g. "1 of 3 completed (33%)"
    public func progressText(for student: User) -> String {
        let total = assignmentsCount(for: student)
        guard total > 0 else { return "0 assigned" }
        let completed = completedCount(for: student)
        let percent = Int((Double(completed) / Double(total)) * 100)
        return "\(completed) of \(total) completed (\(percent)%)"
    }
    
    public func clearFilters() {
        searchText = ""
        selectedDepartment = "All"
        statusFilter = .all
    }
}
