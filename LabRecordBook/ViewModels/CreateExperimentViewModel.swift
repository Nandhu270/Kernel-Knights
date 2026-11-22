import Foundation
import Observation

/// ViewModel managing experiment creation input, validation, and submission.
@Observable
public final class CreateExperimentViewModel {
    public let student: User
    public let dataStore: AppDataStore
    
    public var experimentNumber: String = ""
    public var title: String = ""
    public var selectedSubjectId: UUID? = nil
    public var date: Date = Date()
    public var aim: String = ""
    public var procedure: String = ""
    public var result: String = ""
    
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var isSaved: Bool = false
    
    public init(student: User, dataStore: AppDataStore) {
        self.student = student
        self.dataStore = dataStore
        
        // Auto-suggest next experiment number
        let nextCount = dataStore.experiments.filter { $0.studentId == student.id }.count + 1
        self.experimentNumber = String(format: "EXP-%02d", nextCount)
        
        // Default to first enrolled subject if present
        let enrolled = dataStore.studentSubjectAssignments
            .filter { $0.studentId == student.id && $0.isActive }
            .compactMap { dataStore.subject(byId: $0.subjectId) }
            .filter { $0.isActive }
        self.selectedSubjectId = enrolled.first?.id ?? dataStore.subjects.first?.id
    }
    
    public var availableSubjects: [Subject] {
        let enrolled = dataStore.studentSubjectAssignments
            .filter { $0.studentId == student.id && $0.isActive }
            .compactMap { dataStore.subject(byId: $0.subjectId) }
            .filter { $0.isActive }
        return enrolled.isEmpty ? dataStore.subjects.filter { $0.isActive } : enrolled
    }
    
    public func validate() -> String? {
        let trimmedExpNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedExpNo.isEmpty {
            return "Please provide an experiment number (e.g. EXP-01)."
        }
        if trimmedTitle.isEmpty {
            return "Experiment title cannot be empty."
        }
        guard let subjectId = selectedSubjectId else {
            return "Please select a course subject."
        }
        if trimmedAim.isEmpty {
            return "Aim of the experiment cannot be empty."
        }
        if trimmedProc.isEmpty {
            return "Algorithm or procedure cannot be empty."
        }
        
        // Check for duplicate experiment number for this student and subject
        let duplicate = dataStore.experiments.contains {
            $0.studentId == student.id &&
            $0.subjectId == subjectId &&
            $0.experimentNumber.caseInsensitiveCompare(trimmedExpNo) == .orderedSame
        }
        if duplicate {
            return "An experiment with number '\(trimmedExpNo)' already exists for this subject. Please choose a unique experiment number."
        }
        
        return nil
    }
    
    public func createExperiment(experimentService: ExperimentService) -> Bool {
        if let validationError = validate() {
            self.errorMessage = validationError
            self.showError = true
            return false
        }
        
        guard let subjectId = selectedSubjectId else {
            self.errorMessage = "Please select a subject."
            self.showError = true
            return false
        }
        
        do {
            try experimentService.createExperiment(
                experimentNumber: experimentNumber,
                title: title,
                subjectId: subjectId,
                studentId: student.id,
                date: date,
                aim: aim,
                procedure: procedure,
                result: result,
                isAssignedByMentor: false,
                mentorId: student.assignedMentorId
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
