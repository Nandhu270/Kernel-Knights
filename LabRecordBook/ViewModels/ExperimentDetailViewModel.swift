import Foundation
import Observation

/// ViewModel managing state, permissions, and actions for viewing experiment details.
@Observable
public final class ExperimentDetailViewModel {
    public let experimentId: UUID
    public let currentUser: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    
    public var isShowingEditSheet: Bool = false
    public var isShowingDeleteConfirmation: Bool = false
    public var showSubmitConfirmation: Bool = false
    public var submitSuccessToast: String? = nil
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var isDeleted: Bool = false
    
    public init(experimentId: UUID, currentUser: User, dataStore: AppDataStore) {
        self.experimentId = experimentId
        self.currentUser = currentUser
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
    }
    
    public var experiment: Experiment? {
        dataStore.experiment(byId: experimentId)
    }
    
    public var subject: Subject? {
        guard let exp = experiment else { return nil }
        return dataStore.subject(byId: exp.subjectId)
    }
    
    public var student: User? {
        guard let exp = experiment, let sid = exp.studentId else { return nil }
        return dataStore.user(byId: sid)
    }
    
    public var mentor: User? {
        guard let exp = experiment, let mentorId = exp.mentorId else { return nil }
        return dataStore.user(byId: mentorId)
    }
    
    public var assignment: Assignment? {
        guard let exp = experiment, let aid = exp.assignmentId else { return nil }
        return dataStore.assignments.first { $0.id == aid }
    }
    
    public var verifications: [Verification] {
        dataStore.verifications(forExperimentId: experimentId)
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    public var canEdit: Bool {
        guard let exp = experiment, currentUser.role == .student else { return false }
        return experimentService.canStudentEdit(experiment: exp, studentId: currentUser.id)
    }
    
    public var canDelete: Bool {
        guard let exp = experiment, currentUser.role == .student else { return false }
        return experimentService.canStudentDelete(experiment: exp, studentId: currentUser.id)
    }
    
    public var canSubmit: Bool {
        guard let exp = experiment, currentUser.role == .student else { return false }
        return exp.studentId == currentUser.id && exp.status.isEligibleForSubmission
    }
    
    public var canMentorReview: Bool {
        guard let exp = experiment, currentUser.role == .mentor else { return false }
        let isSupervising = exp.studentId.map { currentUser.assignedStudentIds.contains($0) } ?? false
        return exp.status == .submitted && (isSupervising || exp.mentorId == currentUser.id)
    }
    
    public func submitExperiment() -> Bool {
        do {
            try experimentService.submitExperiment(id: experimentId, studentId: currentUser.id)
            self.submitSuccessToast = "Experiment submitted successfully for mentor verification!"
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
    
    public func deleteExperiment() -> Bool {
        guard canDelete else {
            self.errorMessage = "You are not authorized to delete this experiment."
            self.showError = true
            return false
        }
        
        do {
            try experimentService.deleteExperiment(id: experimentId, studentId: currentUser.id)
            self.isDeleted = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
}
