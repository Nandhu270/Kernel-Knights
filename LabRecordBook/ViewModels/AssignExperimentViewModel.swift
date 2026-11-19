import Foundation
import Observation

/// ViewModel for selecting students and assigning an experiment template to them, with department and search filtering.
@Observable
public final class AssignExperimentViewModel {
    public let experiment: Experiment
    public let mentor: User
    public let dataStore: AppDataStore
    public let assignmentService: AssignmentService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    public var selectedStudentIds: Set<UUID> = []
    public var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    
    public var showConfirmation: Bool = false
    public var showSuccess: Bool = false
    public var showError: Bool = false
    public var errorMessage: String?
    public var successMessage: String?
    
    public init(experiment: Experiment, mentor: User, dataStore: AppDataStore) {
        self.experiment = experiment
        self.mentor = mentor
        self.dataStore = dataStore
        self.assignmentService = AssignmentService(dataStore: dataStore)
    }
    
    /// Students supervised by this mentor
    public var availableStudents: [User] {
        assignmentService.getAssignedStudents(forMentor: mentor)
    }
    
    public var availableDepartments: [String] {
        let depts = Set(availableStudents.map { $0.department })
        return ["All"] + Array(depts).sorted()
    }
    
    /// Filtered list of students based on search and department
    public var filteredStudents: [User] {
        availableStudents.filter { student in
            if selectedDepartment != "All" {
                if student.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                    return false
                }
            }
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                let nameMatch = student.name.lowercased().contains(query)
                let userMatch = student.username.lowercased().contains(query)
                let deptMatch = student.department.lowercased().contains(query)
                return nameMatch || userMatch || deptMatch
            }
            
            return true
        }
    }
    
    /// Selected Student objects
    public var selectedStudents: [User] {
        availableStudents.filter { selectedStudentIds.contains($0.id) }
    }
    
    /// Checks whether this student already has an active assignment for this experiment
    public func isAlreadyAssigned(studentId: UUID) -> Bool {
        dataStore.assignments.contains {
            $0.experimentId == experiment.id &&
            $0.studentId == studentId &&
            !$0.isCompleted
        }
    }
    
    public func toggleSelection(for studentId: UUID) {
        if selectedStudentIds.contains(studentId) {
            selectedStudentIds.remove(studentId)
        } else {
            selectedStudentIds.insert(studentId)
        }
    }
    
    public func removeStudent(id: UUID) {
        selectedStudentIds.remove(id)
    }
    
    public func selectAllFiltered() {
        let assignableIds = filteredStudents
            .filter { !isAlreadyAssigned(studentId: $0.id) }
            .map { $0.id }
        for id in assignableIds {
            selectedStudentIds.insert(id)
        }
    }
    
    public func selectAll() {
        let assignableIds = availableStudents
            .filter { !isAlreadyAssigned(studentId: $0.id) }
            .map { $0.id }
        selectedStudentIds = Set(assignableIds)
    }
    
    public func clearSelection() {
        selectedStudentIds.removeAll()
    }
    
    public var canAssign: Bool {
        !selectedStudentIds.isEmpty
    }
    
    public func requestAssignmentConfirmation() -> Bool {
        guard canAssign else {
            errorMessage = "Please select at least one student to assign."
            showError = true
            return false
        }
        showConfirmation = true
        return true
    }
    
    public func executeAssignment() -> Bool {
        do {
            let assignedList = try assignmentService.assignExperiment(
                templateId: experiment.id,
                toStudentIds: Array(selectedStudentIds),
                byMentor: mentor,
                dueDate: dueDate
            )
            
            let count = assignedList.count
            self.successMessage = "Experiment successfully assigned to \(count) student\(count == 1 ? "" : "s")."
            self.showSuccess = true
            self.selectedStudentIds.removeAll()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
}
