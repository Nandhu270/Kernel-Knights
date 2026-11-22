import Foundation
import Observation

public enum SubjectServiceError: LocalizedError {
    case emptyFields
    case duplicateSubjectCode
    case subjectNotFound
    case cannotDeleteSubjectWithExperiments
    
    public var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Subject name, code, and department cannot be empty."
        case .duplicateSubjectCode:
            return "A course subject with this code already exists. Please choose a unique subject code."
        case .subjectNotFound:
            return "Subject could not be found."
        case .cannotDeleteSubjectWithExperiments:
            return "Cannot delete a subject that has existing experiment records or student allocations. You may deactivate it instead to preserve academic records."
        }
    }
}

/// Service managing course subjects, subject creation, updates, and active status toggling.
@Observable
public final class SubjectService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Queries
    
    public func getAllSubjects() -> [Subject] {
        dataStore.subjects.sorted {
            $0.code.localizedStandardCompare($1.code) == .orderedAscending
        }
    }
    
    public func getActiveSubjects() -> [Subject] {
        getAllSubjects().filter { $0.isActive }
    }
    
    public func getSubject(byId id: UUID) -> Subject? {
        dataStore.subject(byId: id)
    }
    
    public func getSubjects(department: String) -> [Subject] {
        getAllSubjects().filter {
            $0.department.caseInsensitiveCompare(department) == .orderedSame
        }
    }
    
    // MARK: - Admin Subject CRUD Operations
    
    @discardableResult
    public func createSubject(
        name: String,
        code: String,
        description: String = "",
        department: String = "Computer Science & Engineering"
    ) throws -> Subject {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDept = department.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedCode.isEmpty, !trimmedDept.isEmpty else {
            throw SubjectServiceError.emptyFields
        }
        
        // Prevent duplicate subject code (case-insensitive)
        let codeExists = dataStore.subjects.contains {
            $0.code.caseInsensitiveCompare(trimmedCode) == .orderedSame
        }
        if codeExists {
            throw SubjectServiceError.duplicateSubjectCode
        }
        
        let subject = Subject(
            name: trimmedName,
            code: trimmedCode,
            description: trimmedDesc,
            department: trimmedDept,
            isActive: true
        )
        dataStore.subjects.append(subject)
        return subject
    }
    
    @discardableResult
    public func updateSubject(
        id: UUID,
        name: String,
        code: String,
        description: String,
        department: String,
        isActive: Bool
    ) throws -> Subject {
        guard let index = dataStore.subjects.firstIndex(where: { $0.id == id }) else {
            throw SubjectServiceError.subjectNotFound
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDept = department.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedCode.isEmpty, !trimmedDept.isEmpty else {
            throw SubjectServiceError.emptyFields
        }
        
        // Check duplicate code excluding self
        let duplicateCode = dataStore.subjects.contains {
            $0.id != id && $0.code.caseInsensitiveCompare(trimmedCode) == .orderedSame
        }
        if duplicateCode {
            throw SubjectServiceError.duplicateSubjectCode
        }
        
        var updated = dataStore.subjects[index]
        updated.name = trimmedName
        updated.code = trimmedCode
        updated.description = trimmedDesc
        updated.department = trimmedDept
        updated.isActive = isActive
        
        dataStore.subjects[index] = updated
        return updated
    }
    
    public func toggleSubjectActive(id: UUID) throws {
        guard let index = dataStore.subjects.firstIndex(where: { $0.id == id }) else {
            throw SubjectServiceError.subjectNotFound
        }
        dataStore.subjects[index].isActive.toggle()
    }
    
    public func deleteSubject(id: UUID) throws {
        guard let index = dataStore.subjects.firstIndex(where: { $0.id == id }) else {
            throw SubjectServiceError.subjectNotFound
        }
        
        // Prevent deletion if linked to experiments or student assignments
        let hasExperiments = dataStore.experiments.contains { $0.subjectId == id }
        let hasAssignments = dataStore.assignments.contains { $0.subjectId == id }
        let hasStudentAllocations = dataStore.studentSubjectAssignments.contains { $0.subjectId == id }
        
        if hasExperiments || hasAssignments || hasStudentAllocations {
            throw SubjectServiceError.cannotDeleteSubjectWithExperiments
        }
        
        // Remove mentor allocations for this subject
        dataStore.mentorSubjectAssignments.removeAll { $0.subjectId == id }
        dataStore.subjects.remove(at: index)
    }
}
