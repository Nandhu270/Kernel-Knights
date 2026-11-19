import Foundation
import Observation

/// ViewModel managing editing existing experiments with pre-populated values and eligibility validation.
@Observable
public final class EditExperimentViewModel {
    public let originalExperiment: Experiment
    public let student: User
    public let dataStore: AppDataStore
    
    public var experimentNumber: String
    public var title: String
    public var selectedSubjectId: UUID
    public var date: Date
    public var aim: String
    public var procedure: String
    public var result: String
    
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var isSaved: Bool = false
    
    public init(experiment: Experiment, student: User, dataStore: AppDataStore) {
        self.originalExperiment = experiment
        self.student = student
        self.dataStore = dataStore
        
        self.experimentNumber = experiment.experimentNumber
        self.title = experiment.title
        self.selectedSubjectId = experiment.subjectId
        self.date = experiment.date
        self.aim = experiment.aim
        self.procedure = experiment.procedure
        self.result = experiment.result
    }
    
    public var availableSubjects: [Subject] {
        dataStore.subjects
    }
    
    public var isEligibleForEdit: Bool {
        originalExperiment.studentId == student.id &&
        originalExperiment.status != .submitted &&
        originalExperiment.status != .verified
    }
    
    public func validate() -> String? {
        guard isEligibleForEdit else {
            return "This experiment is currently under review or has been verified and cannot be edited."
        }
        
        let trimmedExpNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedExpNo.isEmpty {
            return "Experiment number cannot be empty."
        }
        if trimmedTitle.isEmpty {
            return "Experiment title cannot be empty."
        }
        if trimmedAim.isEmpty {
            return "Aim cannot be empty."
        }
        if trimmedProc.isEmpty {
            return "Procedure cannot be empty."
        }
        
        // Prevent duplicate experiment number for this student and subject (excluding this experiment)
        let duplicate = dataStore.experiments.contains {
            $0.id != originalExperiment.id &&
            $0.studentId == student.id &&
            $0.subjectId == selectedSubjectId &&
            $0.experimentNumber.caseInsensitiveCompare(trimmedExpNo) == .orderedSame
        }
        if duplicate {
            return "An experiment with number '\(trimmedExpNo)' already exists for this subject. Please choose a unique number."
        }
        
        return nil
    }
    
    public func saveChanges(experimentService: ExperimentService) -> Bool {
        if let validationError = validate() {
            self.errorMessage = validationError
            self.showError = true
            return false
        }
        
        do {
            let nextStatus: ExperimentStatus? = (originalExperiment.status == .rejected) ? .inProgress : nil
            try experimentService.updateExperiment(
                id: originalExperiment.id,
                studentId: student.id,
                experimentNumber: experimentNumber,
                title: title,
                subjectId: selectedSubjectId,
                date: date,
                aim: aim,
                procedure: procedure,
                result: result,
                status: nextStatus
            )
            self.isSaved = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
}
