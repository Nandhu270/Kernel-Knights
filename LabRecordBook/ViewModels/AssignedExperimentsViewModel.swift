import Foundation
import Observation

/// ViewModel for viewing and filtering mentor's assigned experiments and tracking status.
@Observable
public final class AssignedExperimentsViewModel {
    public let mentor: User
    public let dataStore: AppDataStore
    public let assignmentService: AssignmentService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var selectedStudentId: UUID?
    public var selectedStatus: AssignmentStatus?
    
    public init(mentor: User, dataStore: AppDataStore) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.assignmentService = AssignmentService(dataStore: dataStore)
    }
    
    /// All assignments created by this mentor
    public var allMentorAssignments: [Assignment] {
        assignmentService.getAssignments(forMentorId: mentor.id, requestingUser: mentor)
    }
    
    /// Supervised students for filtering
    public var assignedStudents: [User] {
        assignmentService.getAssignedStudents(forMentor: mentor)
    }
    
    public var availableDepartments: [String] {
        let depts = Set(assignedStudents.map { $0.department })
        return ["All"] + Array(depts).sorted()
    }
    
    /// Filtered assignments matching search text, department filter, student filter, and status filter
    public var filteredAssignments: [Assignment] {
        let base = assignmentService.filter(
            assignments: allMentorAssignments,
            query: searchText,
            studentId: selectedStudentId,
            status: selectedStatus
        )
        if selectedDepartment == "All" {
            return base
        }
        return base.filter { assignment in
            guard let student = dataStore.user(byId: assignment.studentId) else { return false }
            return student.department.caseInsensitiveCompare(selectedDepartment) == .orderedSame
        }
    }
    
    public func student(for assignment: Assignment) -> User? {
        dataStore.user(byId: assignment.studentId)
    }
    
    public func subject(for assignment: Assignment) -> Subject? {
        dataStore.subject(byId: assignment.subjectId)
    }
    
    public func templateExperiment(for assignment: Assignment) -> Experiment? {
        guard let expId = assignment.experimentId else { return nil }
        return dataStore.experiment(byId: expId)
    }
    
    public func studentExperiment(for assignment: Assignment) -> Experiment? {
        guard let expId = assignment.studentExperimentId else { return nil }
        return dataStore.experiment(byId: expId)
    }
    
    public func clearFilters() {
        searchText = ""
        selectedDepartment = "All"
        selectedStudentId = nil
        selectedStatus = nil
    }
}
