import Foundation
import Observation

/// ViewModel for creating a master experiment template by a mentor.
@Observable
public final class CreateMentorExperimentViewModel {
    public let mentor: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    
    public var experimentNumber: String = ""
    public var title: String = ""
    public var selectedSubjectId: UUID?
    public var date: Date = Date()
    public var aim: String = ""
    public var procedure: String = ""
    public var result: String = ""
    
    public var errorMessage: String?
    public var showError: Bool = false
    public var isSaved: Bool = false
    public var createdExperiment: Experiment?
    
    public init(mentor: User, dataStore: AppDataStore) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
        
        if let firstSubject = dataStore.subjects.first {
            self.selectedSubjectId = firstSubject.id
        }
        
        let nextCount = dataStore.experiments.filter { $0.mentorId == mentor.id && $0.studentId == nil }.count + 1
        self.experimentNumber = String(format: "EXP-%02d", nextCount)
    }
    
    public var availableSubjects: [Subject] {
        dataStore.subjects
    }
    
    public var isFormValid: Bool {
        let trimmedNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedNo.isEmpty &&
               !trimmedTitle.isEmpty &&
               selectedSubjectId != nil &&
               !trimmedAim.isEmpty &&
               !trimmedProc.isEmpty
    }
    
    public func validate() -> Bool {
        let trimmedNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedNo.isEmpty {
            errorMessage = "Experiment number cannot be empty."
            showError = true
            return false
        }
        
        if trimmedTitle.isEmpty {
            errorMessage = "Experiment title cannot be empty."
            showError = true
            return false
        }
        
        guard let subjectId = selectedSubjectId else {
            errorMessage = "Please select a subject."
            showError = true
            return false
        }
        
        if trimmedAim.isEmpty {
            errorMessage = "Aim cannot be empty."
            showError = true
            return false
        }
        
        if trimmedProc.isEmpty {
            errorMessage = "Procedure cannot be empty."
            showError = true
            return false
        }
        
        let duplicate = dataStore.experiments.contains {
            $0.mentorId == mentor.id &&
            $0.studentId == nil &&
            $0.subjectId == subjectId &&
            $0.experimentNumber.caseInsensitiveCompare(trimmedNo) == .orderedSame
        }
        if duplicate {
            errorMessage = "An experiment template with number '\(trimmedNo)' already exists for this subject."
            showError = true
            return false
        }
        
        return true
    }
    
    public func createExperiment() -> Bool {
        guard validate(), let subjectId = selectedSubjectId else {
            return false
        }
        
        do {
            let created = try experimentService.createMentorExperiment(
                mentor: mentor,
                experimentNumber: experimentNumber,
                title: title,
                subjectId: subjectId,
                date: date,
                aim: aim,
                procedure: procedure,
                result: result
            )
            self.createdExperiment = created
            self.isSaved = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
}
