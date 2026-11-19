import Foundation
import Observation

/// ViewModel managing state, metrics, and experiments for the Student Dashboard.
@Observable
public final class StudentViewModel {
    public let student: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    public let assignmentService: AssignmentService
    
    public init(student: User, dataStore: AppDataStore) {
        self.student = student
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
        self.assignmentService = AssignmentService(dataStore: dataStore)
    }
    
    // MARK: - Phase 5 Student Metrics (Calculated dynamically from AppDataStore)
    
    public var studentExperiments: [Experiment] {
        experimentService.getExperiments(forStudentId: student.id)
    }
    
    public var totalExperimentsCount: Int {
        studentExperiments.count
    }
    
    public var assignedCount: Int {
        studentExperiments.filter { $0.status == .assigned }.count
    }
    
    public var inProgressCount: Int {
        studentExperiments.filter { $0.status == .inProgress || $0.status == .pending }.count
    }
    
    public var submittedCount: Int {
        studentExperiments.filter { $0.status == .submitted }.count
    }
    
    public var rejectedCount: Int {
        studentExperiments.filter { $0.status == .rejected }.count
    }
    
    public var verifiedCount: Int {
        studentExperiments.filter { $0.status == .verified }.count
    }
    
    public var pendingCount: Int {
        studentExperiments.filter { $0.status == .pending || $0.status == .assigned || $0.status == .inProgress }.count
    }
    
    public var assignedFromMentorCount: Int {
        studentExperiments.filter { $0.isAssignedByMentor }.count
    }
    
    public var assignedMentor: User? {
        guard let mentorId = student.assignedMentorId else { return nil }
        return dataStore.user(byId: mentorId)
    }
}
