import Foundation
import Observation

/// ViewModel managing assigning, reassigning, and unassigning mentors to students,
/// supporting two-stage mapping: department selection followed by department mentor selection.
@Observable
public final class MentorAssignmentViewModel {
    public enum AssignmentFilter: String, CaseIterable, Identifiable {
        case all = "All Students"
        case unassigned = "Unassigned"
        case assigned = "Assigned"
        
        public var id: String { rawValue }
    }
    
    public let dataStore: AppDataStore
    public let userService: UserService
    
    public var searchText: String = ""
    public var filter: AssignmentFilter = .all
    public var selectedDepartment: String = "All"
    
    // Selection for assignment sheet or modal
    public var studentToAssign: User? = nil
    public var selectedMentorDepartment: String = ""
    public var selectedMentorId: UUID? = nil
    
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var successToast: String? = nil
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
        self.userService = UserService(dataStore: dataStore)
    }
    
    // MARK: - Queries
    
    public var activeMentors: [User] {
        dataStore.users.filter { $0.role == .mentor && $0.isActive }
    }
    
    /// Mentors matching the currently chosen mentor department
    public var filteredMentors: [User] {
        dataStore.users.filter {
            $0.role == .mentor &&
            $0.isActive &&
            $0.department.caseInsensitiveCompare(selectedMentorDepartment) == .orderedSame
        }
    }
    
    public var students: [User] {
        dataStore.users.filter { user in
            guard user.role == .student else { return false }
            
            // Department filter
            if selectedDepartment != "All" {
                if user.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                    return false
                }
            }
            
            switch filter {
            case .all:
                break
            case .unassigned:
                if user.assignedMentorId != nil { return false }
            case .assigned:
                if user.assignedMentorId == nil { return false }
            }
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                return user.name.lowercased().contains(query) ||
                       user.username.lowercased().contains(query) ||
                       user.department.lowercased().contains(query)
            }
            
            return true
        }
    }
    
    public func mentor(for student: User) -> User? {
        guard let mentorId = student.assignedMentorId else { return nil }
        return dataStore.user(byId: mentorId)
    }
    
    public func clearFilters() {
        searchText = ""
        filter = .all
        selectedDepartment = "All"
    }
    
    // MARK: - Actions
    
    public func selectStudentForAssignment(_ student: User) {
        self.studentToAssign = student
        self.selectedMentorId = student.assignedMentorId
        
        // If student has a currently assigned mentor, pre-select that mentor's department
        if let currentMentorId = student.assignedMentorId,
           let currentMentor = dataStore.user(byId: currentMentorId) {
            self.selectedMentorDepartment = currentMentor.department
        } else {
            // Otherwise default to the student's own department
            self.selectedMentorDepartment = student.department
        }
    }
    
    public func onDepartmentChanged(to newDept: String) {
        self.selectedMentorDepartment = newDept
        
        // If current selected mentor is not in this department, clear selection
        if let mentorId = selectedMentorId,
           let mentor = dataStore.user(byId: mentorId),
           mentor.department.caseInsensitiveCompare(newDept) != .orderedSame {
            selectedMentorId = nil
        }
    }
    
    public func saveAssignment() {
        guard let student = studentToAssign else { return }
        
        do {
            try userService.assignMentor(mentorId: selectedMentorId, toStudentId: student.id)
            if let mentorId = selectedMentorId, let mentor = dataStore.user(byId: mentorId) {
                successToast = "Assigned \(mentor.name) as mentor to \(student.name)."
            } else {
                successToast = "Unassigned mentor from \(student.name)."
            }
            studentToAssign = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
