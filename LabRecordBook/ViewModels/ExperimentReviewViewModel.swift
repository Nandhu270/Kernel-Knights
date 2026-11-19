import Foundation
import Observation

/// ViewModel for reviewing, verifying, or rejecting a submitted student experiment.
@Observable
public final class ExperimentReviewViewModel {
    public let experimentId: UUID
    public let mentor: User
    public let dataStore: AppDataStore
    public let verificationService: VerificationService
    public let experimentService: ExperimentService
    
    public var approvalComments: String = ""
    public var rejectionComments: String = ""
    
    public var showVerificationConfirmation: Bool = false
    public var showRejectSheet: Bool = false
    public var isProcessedSuccessfully: Bool = false
    public var showError: Bool = false
    public var errorMessage: String?
    
    public init(experimentId: UUID, mentor: User, dataStore: AppDataStore) {
        self.experimentId = experimentId
        self.mentor = mentor
        self.dataStore = dataStore
        self.verificationService = VerificationService(dataStore: dataStore)
        self.experimentService = ExperimentService(dataStore: dataStore)
    }
    
    public var experiment: Experiment? {
        dataStore.experiment(byId: experimentId)
    }
    
    public var student: User? {
        guard let exp = experiment, let sid = exp.studentId else { return nil }
        return dataStore.user(byId: sid)
    }
    
    public var subject: Subject? {
        guard let exp = experiment else { return nil }
        return dataStore.subject(byId: exp.subjectId)
    }
    
    public var verificationHistory: [Verification] {
        verificationService.getVerificationHistory(forExperimentId: experimentId, requestingUser: mentor)
    }
    
    public var isEligibleForReview: Bool {
        guard let exp = experiment else { return false }
        return exp.status == .submitted
    }
    
    public func verify() -> Bool {
        guard isEligibleForReview else {
            errorMessage = "This experiment is not currently submitted for review."
            showError = true
            return false
        }
        
        do {
            try verificationService.verifyExperiment(
                experimentId: experimentId,
                mentor: mentor,
                comments: approvalComments
            )
            isProcessedSuccessfully = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
    
    public func reject() -> Bool {
        let trimmed = rejectionComments.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Rejection feedback comments are mandatory. Please explain what corrections are needed."
            showError = true
            return false
        }
        
        guard isEligibleForReview else {
            errorMessage = "This experiment is not currently submitted for review."
            showError = true
            return false
        }
        
        do {
            try verificationService.rejectExperiment(
                experimentId: experimentId,
                mentor: mentor,
                comments: trimmed
            )
            isProcessedSuccessfully = true
            showRejectSheet = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
}
