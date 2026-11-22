import Foundation
import Observation

/// ViewModel for Admin assigning and removing faculty mentors to a specific subject.
@Observable
public final class MentorSubjectAllocationViewModel {
    public let subject: Subject
    public let dataStore: AppDataStore
    public let allocationService: SubjectAllocationService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var selectedMentorId: UUID? = nil
    
    public var showAssignSheet: Bool = false
    public var showError: Bool = false
    public var errorMessage: String? = nil
    
    public init(subject: Subject, dataStore: AppDataStore) {
        self.subject = subject
        self.dataStore = dataStore
        self.allocationService = SubjectAllocationService(dataStore: dataStore)
    }
    
    /// Mentors currently assigned to teach this subject
    public var assignedMentors: [User] {
        allocationService.getMentors(forSubjectId: subject.id)
    }
    
    /// Available mentors not yet assigned to this subject
    public var availableMentors: [User] {
        let assignedIds = Set(assignedMentors.map { $0.id })
        return dataStore.users.filter { user in
            user.role == .mentor && user.isActive && !assignedIds.contains(user.id)
        }
    }
    
    public var filteredAvailableMentors: [User] {
        availableMentors.filter { mentor in
            if selectedDepartment != "All" && mentor.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                return false
            }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                return mentor.name.lowercased().contains(query) ||
                       mentor.username.lowercased().contains(query) ||
                       mentor.department.lowercased().contains(query)
            }
            return true
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    public func assignSelectedMentor() -> Bool {
        guard let mentorId = selectedMentorId else {
            errorMessage = "Please select a mentor to assign."
            showError = true
            return false
        }
        do {
            try allocationService.assignMentorToSubject(mentorId: mentorId, subjectId: subject.id)
            selectedMentorId = nil
            showAssignSheet = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
    
    public func removeMentor(_ mentor: User) {
        do {
            try allocationService.removeMentorFromSubject(mentorId: mentor.id, subjectId: subject.id)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    public func allocatedStudentCount(for mentorId: UUID) -> Int {
        dataStore.studentSubjectAssignments.filter {
            $0.subjectId == subject.id && $0.mentorId == mentorId && $0.isActive
        }.count
    }
}
