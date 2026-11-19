import Foundation
import Observation

/// ViewModel handling the student experiment submission confirmation and execution.
@Observable
public final class SubmitExperimentViewModel {
    public let experimentId: UUID
    public let student: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    
    public var isSubmitting: Bool = false
    public var isSubmittedSuccessfully: Bool = false
    public var showError: Bool = false
    public var errorMessage: String?
    
    public init(experimentId: UUID, student: User, dataStore: AppDataStore) {
        self.experimentId = experimentId
        self.student = student
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
    }
    
    public var experiment: Experiment? {
        dataStore.experiment(byId: experimentId)
    }
    
    public var assignedMentor: User? {
        guard let mentorId = student.assignedMentorId else { return nil }
        return dataStore.user(byId: mentorId)
    }
    
    /// Pre-submission validation
    public var canSubmit: Bool {
        guard let exp = experiment else { return false }
        let titleValid = !exp.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let aimValid = !exp.aim.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let procValid = !exp.procedure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let resultValid = !exp.result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasMentor = student.assignedMentorId != nil
        
        return titleValid && aimValid && procValid && resultValid && hasMentor && exp.status.isEligibleForSubmission
    }
    
    public func validateSubmission() -> Bool {
        guard let exp = experiment else {
            errorMessage = "Experiment could not be found."
            showError = true
            return false
        }
        
        if exp.aim.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter an Aim before submitting."
            showError = true
            return false
        }
        
        if exp.procedure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter the Algorithm or Procedure before submitting."
            showError = true
            return false
        }
        
        if exp.result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter experimental Results/Observations before submitting for verification."
            showError = true
            return false
        }
        
        if student.assignedMentorId == nil {
            errorMessage = "You do not have an assigned supervising mentor. Please contact your administrator."
            showError = true
            return false
        }
        
        if !exp.status.isEligibleForSubmission {
            errorMessage = "This experiment cannot be submitted in its current status (\(exp.status.displayName))."
            showError = true
            return false
        }
        
        return true
    }
    
    public func submit() -> Bool {
        guard validateSubmission() else { return false }
        
        isSubmitting = true
        do {
            try experimentService.submitExperiment(id: experimentId, studentId: student.id)
            isSubmitting = false
            isSubmittedSuccessfully = true
            return true
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
}
