import Foundation
import Observation

/// ViewModel managing student's view of experiments assigned by their mentor.
@Observable
public final class StudentAssignedExperimentsViewModel {
    public let student: User
    public let dataStore: AppDataStore
    public let assignmentService: AssignmentService
    public let experimentService: ExperimentService
    
    public var searchText: String = ""
    public var selectedStatus: AssignmentStatus?
    
    public init(student: User, dataStore: AppDataStore) {
        self.student = student
        self.dataStore = dataStore
        self.assignmentService = AssignmentService(dataStore: dataStore)
        self.experimentService = ExperimentService(dataStore: dataStore)
    }
    
    /// Assignments received by this student
    public var studentAssignments: [Assignment] {
        assignmentService.getAssignments(forStudentId: student.id, requestingUser: student)
    }
    
    /// Filtered assignments matching search text and status
    public var filteredAssignments: [Assignment] {
        studentAssignments.filter { assignment in
            let matchesQuery: Bool
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty {
                matchesQuery = true
            } else {
                matchesQuery = assignment.title.lowercased().contains(trimmed) ||
                               assignment.experimentNumber.lowercased().contains(trimmed)
            }
            
            let matchesStatus: Bool
            if let st = selectedStatus {
                matchesStatus = assignment.status == st
            } else {
                matchesStatus = true
            }
            
            return matchesQuery && matchesStatus
        }
    }
    
    public func mentor(for assignment: Assignment) -> User? {
        dataStore.user(byId: assignment.mentorId)
    }
    
    public func subject(for assignment: Assignment) -> Subject? {
        dataStore.subject(byId: assignment.subjectId)
    }
    
    /// The student's individual independent experiment record for this assignment
    public func studentExperiment(for assignment: Assignment) -> Experiment? {
        if let sid = assignment.studentExperimentId {
            return dataStore.experiment(byId: sid)
        }
        // Fallback search by assignmentId
        return dataStore.experiments.first { $0.assignmentId == assignment.id && $0.studentId == student.id }
    }
}
