import Foundation
import Observation

/// ViewModel for Admin allocating and reassigning students to a subject under specific supervising mentors.
@Observable
public final class StudentSubjectAllocationViewModel {
    public enum AllocationFilter: String, CaseIterable, Identifiable {
        case all = "All Students"
        case allocated = "Allocated"
        case unallocated = "Unallocated"
        
        public var id: String { rawValue }
    }
    
    public let subject: Subject
    public let dataStore: AppDataStore
    public let allocationService: SubjectAllocationService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var filter: AllocationFilter = .all
    
    public var studentToAllocate: User? = nil
    public var selectedMentorId: UUID? = nil
    public var showError: Bool = false
    public var errorMessage: String? = nil
    
    public init(subject: Subject, dataStore: AppDataStore) {
        self.subject = subject
        self.dataStore = dataStore
        self.allocationService = SubjectAllocationService(dataStore: dataStore)
    }
    
    /// Mentors actively assigned to teach this subject
    public var subjectMentors: [User] {
        allocationService.getMentors(forSubjectId: subject.id)
    }
    
    /// Active students eligible for allocation
    public var allStudents: [User] {
        dataStore.users.filter { $0.role == .student && $0.isActive }
    }
    
    public var filteredStudents: [User] {
        allStudents.filter { student in
            let allocation = allocationService.getActiveAllocation(studentId: student.id, subjectId: subject.id)
            
            switch filter {
            case .all:
                break
            case .allocated:
                if allocation == nil { return false }
            case .unallocated:
                if allocation != nil { return false }
            }
            
            if selectedDepartment != "All" && student.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                return false
            }
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                return student.name.lowercased().contains(query) ||
                       student.username.lowercased().contains(query) ||
                       student.department.lowercased().contains(query)
            }
            return true
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    public func allocatedMentor(for student: User) -> User? {
        allocationService.getAllocatedMentor(studentId: student.id, subjectId: subject.id)
    }
    
    public func selectStudentForAllocation(_ student: User) {
        self.studentToAllocate = student
        let current = allocationService.getActiveAllocation(studentId: student.id, subjectId: subject.id)
        self.selectedMentorId = current?.mentorId ?? subjectMentors.first?.id
    }
    
    public func saveAllocation() -> Bool {
        guard let student = studentToAllocate, let mentorId = selectedMentorId else {
            errorMessage = "Please select a supervising mentor for this student."
            showError = true
            return false
        }
        
        do {
            let current = allocationService.getActiveAllocation(studentId: student.id, subjectId: subject.id)
            if current != nil {
                // Reassign: deactivates old, creates new active, preserves history
                try allocationService.reassignStudentMentor(
                    studentId: student.id,
                    subjectId: subject.id,
                    newMentorId: mentorId
                )
            } else {
                // Initial allocation
                try allocationService.allocateStudentToSubject(
                    studentId: student.id,
                    subjectId: subject.id,
                    mentorId: mentorId
                )
            }
            self.studentToAllocate = nil
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
    
    public func removeAllocation(for student: User) {
        do {
            try allocationService.removeStudentFromSubject(studentId: student.id, subjectId: subject.id)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
}
