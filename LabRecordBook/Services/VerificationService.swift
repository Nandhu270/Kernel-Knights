import Foundation
import Observation

public enum VerificationError: LocalizedError {
    case experimentNotFound
    case unauthorized
    case mandatoryCommentsRequired
    case studentNotAssignedToMentor
    case invalidStatusForReview
    
    public var errorDescription: String? {
        switch self {
        case .experimentNotFound:
            return "Experiment could not be found."
        case .unauthorized:
            return "Only mentors are authorized to verify or reject experiments."
        case .mandatoryCommentsRequired:
            return "Rejection feedback comments are mandatory. Please specify what needs correction."
        case .studentNotAssignedToMentor:
            return "You are only permitted to review experiments from students currently assigned to your mentorship."
        case .invalidStatusForReview:
            return "Only experiments currently in 'Submitted' status can be verified or rejected."
        }
    }
}

/// Service managing mentor verification, rejection workflows, and audit history.
@Observable
public final class VerificationService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Queries with Role-Based Permissions
    
    /// Returns chronological verification history for a specific experiment with security validation
    public func getVerificationHistory(forExperimentId expId: UUID, requestingUser: User? = nil) -> [Verification] {
        if let user = requestingUser, let exp = dataStore.experiment(byId: expId) {
            switch user.role {
            case .student:
                guard exp.studentId == user.id else { return [] }
            case .mentor:
                let isSupervising = exp.studentId.map { user.assignedStudentIds.contains($0) } ?? false
                guard isSupervising || exp.mentorId == user.id else { return [] }
            case .admin:
                break
            }
        }
        
        return dataStore.verifications
            .filter { $0.experimentId == expId }
            .sorted { $0.timestamp < $1.timestamp } // Chronological order
    }
    
    /// Returns all verifications across the application (for Admin) or scoped to user
    public func getAllVerifications(requestingUser: User) -> [Verification] {
        switch requestingUser.role {
        case .admin:
            return dataStore.verifications.sorted { $0.timestamp > $1.timestamp }
        case .mentor:
            return dataStore.verifications
                .filter { $0.mentorId == requestingUser.id }
                .sorted { $0.timestamp > $1.timestamp }
        case .student:
            let studentExpIds = Set(dataStore.experiments.filter { $0.studentId == requestingUser.id }.map { $0.id })
            return dataStore.verifications
                .filter { studentExpIds.contains($0.experimentId) }
                .sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    // MARK: - Mentor Actions
    
    /// Verifies and approves a submitted experiment.
    public func verifyExperiment(
        experimentId: UUID,
        mentor: User,
        comments: String
    ) throws {
        guard mentor.role == .mentor else {
            throw VerificationError.unauthorized
        }
        
        guard let expIndex = dataStore.experiments.firstIndex(where: { $0.id == experimentId }) else {
            throw VerificationError.experimentNotFound
        }
        
        let experiment = dataStore.experiments[expIndex]
        
        // Experiment must be in .submitted status to be verified
        guard experiment.status == .submitted else {
            throw VerificationError.invalidStatusForReview
        }
        
        // Mentor must supervise this student
        let belongsToAssignedStudent = experiment.studentId.map { mentor.assignedStudentIds.contains($0) } ?? false
        guard belongsToAssignedStudent || experiment.mentorId == mentor.id else {
            throw VerificationError.studentNotAssignedToMentor
        }
        
        // Update experiment status to verified
        dataStore.experiments[expIndex].status = .verified
        dataStore.experiments[expIndex].mentorId = mentor.id
        dataStore.experiments[expIndex].lastUpdated = Date()
        
        // Complete any associated assignment
        if let assignIndex = dataStore.assignments.firstIndex(where: {
            $0.studentExperimentId == experiment.id || (experiment.assignmentId != nil && $0.id == experiment.assignmentId)
        }) {
            dataStore.assignments[assignIndex].isCompleted = true
            dataStore.assignments[assignIndex].status = .completed
        }
        
        // Create audit record in verification history
        let feedbackComment = comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Experiment verified and approved."
            : comments.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let record = Verification(
            experimentId: experimentId,
            mentorId: mentor.id,
            mentorName: mentor.name,
            status: .verified,
            comments: feedbackComment,
            timestamp: Date()
        )
        
        dataStore.verifications.append(record)
    }
    
    /// Rejects a submitted experiment with mandatory feedback comments.
    public func rejectExperiment(
        experimentId: UUID,
        mentor: User,
        comments: String
    ) throws {
        guard mentor.role == .mentor else {
            throw VerificationError.unauthorized
        }
        
        let trimmedComments = comments.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComments.isEmpty else {
            // Rejection comments are strictly mandatory
            throw VerificationError.mandatoryCommentsRequired
        }
        
        guard let expIndex = dataStore.experiments.firstIndex(where: { $0.id == experimentId }) else {
            throw VerificationError.experimentNotFound
        }
        
        let experiment = dataStore.experiments[expIndex]
        
        // Experiment must be in .submitted status to be rejected
        guard experiment.status == .submitted else {
            throw VerificationError.invalidStatusForReview
        }
        
        // Mentor must supervise this student
        let belongsToAssignedStudent = experiment.studentId.map { mentor.assignedStudentIds.contains($0) } ?? false
        guard belongsToAssignedStudent || experiment.mentorId == mentor.id else {
            throw VerificationError.studentNotAssignedToMentor
        }
        
        // Update experiment status to rejected
        dataStore.experiments[expIndex].status = .rejected
        dataStore.experiments[expIndex].mentorId = mentor.id
        dataStore.experiments[expIndex].lastUpdated = Date()
        
        // Ensure associated assignment remains pending
        if let assignIndex = dataStore.assignments.firstIndex(where: {
            $0.studentExperimentId == experiment.id || (experiment.assignmentId != nil && $0.id == experiment.assignmentId)
        }) {
            dataStore.assignments[assignIndex].isCompleted = false
            dataStore.assignments[assignIndex].status = .pending
        }
        
        // Append to non-destructive verification history
        let record = Verification(
            experimentId: experimentId,
            mentorId: mentor.id,
            mentorName: mentor.name,
            status: .rejected,
            comments: trimmedComments,
            timestamp: Date()
        )
        
        dataStore.verifications.append(record)
    }
}
