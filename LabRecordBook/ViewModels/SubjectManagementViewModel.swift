import Foundation
import Observation

/// ViewModel managing admin subject catalogue, filtering, creation, updates, and status toggles.
@Observable
public final class SubjectManagementViewModel {
    public let dataStore: AppDataStore
    public let subjectService: SubjectService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var showActiveOnly: Bool = false
    
    public var subjectToEdit: Subject? = nil
    public var subjectToDelete: Subject? = nil
    public var showCreateSheet: Bool = false
    public var showError: Bool = false
    public var errorMessage: String? = nil
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
        self.subjectService = SubjectService(dataStore: dataStore)
    }
    
    public var availableDepartments: [String] {
        let depts = Set(dataStore.subjects.map { $0.department })
        return ["All"] + Array(depts).sorted()
    }
    
    public var filteredSubjects: [Subject] {
        dataStore.subjects.filter { subject in
            if showActiveOnly && !subject.isActive {
                return false
            }
            if selectedDepartment != "All" && subject.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                return false
            }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                let codeMatch = subject.code.lowercased().contains(query)
                let nameMatch = subject.name.lowercased().contains(query)
                let deptMatch = subject.department.lowercased().contains(query)
                return codeMatch || nameMatch || deptMatch
            }
            return true
        }
        .sorted { $0.code.localizedStandardCompare($1.code) == .orderedAscending }
    }
    
    public func toggleActive(for subject: Subject) {
        do {
            try subjectService.toggleSubjectActive(id: subject.id)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    public func deleteSubject(_ subject: Subject) {
        do {
            try subjectService.deleteSubject(id: subject.id)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    public func studentCount(for subjectId: UUID) -> Int {
        dataStore.studentSubjectAssignments.filter { $0.subjectId == subjectId && $0.isActive }.count
    }
    
    public func mentorCount(for subjectId: UUID) -> Int {
        dataStore.mentorSubjectAssignments.filter { $0.subjectId == subjectId && $0.isActive }.count
    }
}
