import Foundation
import Observation

/// ViewModel managing state, metrics, and assigned student queue for the Mentor Dashboard.
@Observable
public final class MentorViewModel {
    public let mentor: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    public let assignmentService: AssignmentService
    public let verificationService: VerificationService
    
    public init(mentor: User, dataStore: AppDataStore) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
        self.assignmentService = AssignmentService(dataStore: dataStore)
        self.verificationService = VerificationService(dataStore: dataStore)
    }
    
    // MARK: - Phase 5 Mentorship Metrics (Calculated dynamically from AppDataStore)
    
    /// Students currently assigned to this mentor
    public var assignedStudents: [User] {
        dataStore.users.filter { $0.role == .student && $0.assignedMentorId == mentor.id && $0.isActive }
    }
    
    public var assignedStudentsCount: Int {
        assignedStudents.count
    }
    
    /// Master templates created by this mentor for assignment
    public var mentorTemplates: [Experiment] {
        dataStore.experiments.filter { $0.mentorId == mentor.id && $0.studentId == nil }
    }
    
    public var totalMentorCreatedExperimentsCount: Int {
        mentorTemplates.count
    }
    
    /// Total assignments created by this mentor
    public var mentorAssignments: [Assignment] {
        dataStore.assignments.filter { $0.mentorId == mentor.id }
    }
    
    public var totalAssignmentsCount: Int {
        mentorAssignments.count
    }
    
    public var pendingAssignmentsCount: Int {
        mentorAssignments.filter { !$0.isCompleted }.count
    }
    
    public var completedAssignmentsCount: Int {
        mentorAssignments.filter { $0.isCompleted }.count
    }
    
    /// All experiments supervised by this mentor (from assigned students)
    public var mentorExperiments: [Experiment] {
        experimentService.getExperiments(forMentorId: mentor.id)
    }
    
    /// Submissions awaiting mentor verification
    public var pendingReviews: [Experiment] {
        mentorExperiments.filter { $0.status == .submitted }
    }
    
    public var pendingReviewsCount: Int {
        pendingReviews.count
    }
    
    /// Experiments verified by this mentor
    public var verifiedCount: Int {
        mentorExperiments.filter { $0.status == .verified }.count
    }
    
    /// Experiments rejected and awaiting student correction
    public var rejectedCount: Int {
        mentorExperiments.filter { $0.status == .rejected }.count
    }
}
