import Foundation
import Observation

/// ViewModel managing experiment listing, live searching, dual filtering (subject and status), and deletion.
@Observable
public final class ExperimentListViewModel {
    public let user: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    public let subjectService: SubjectService
    
    public var searchText: String = ""
    public var selectedSubjectId: UUID? = nil
    public var selectedStatus: ExperimentStatus? = nil
    public var selectedDepartment: String = "All"
    public var selectedStudentId: UUID? = nil
    
    public var experimentToDelete: Experiment? = nil
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var successToast: String? = nil
    
    public init(user: User, dataStore: AppDataStore) {
        self.user = user
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
        self.subjectService = SubjectService(dataStore: dataStore)
    }
    
    // MARK: - Query & Filtered Results
    
    public var availableSubjects: [Subject] {
        subjectService.getAllSubjects()
    }
    
    public var availableDepartments: [Department] {
        dataStore.departments
    }
    
    public var availableStudents: [User] {
        if user.role == .admin {
            return dataStore.users.filter { $0.role == .student }
        } else if user.role == .mentor {
            return dataStore.users.filter { $0.role == .student && $0.assignedMentorId == user.id }
        } else {
            return []
        }
    }
    
    /// Returns experiments matching both search query, subject filter, status filter, department, and student.
    public var filteredExperiments: [Experiment] {
        let authorized = experimentService.getAuthorizedExperiments(for: user)
        return experimentService.filter(
            experiments: authorized,
            query: searchText,
            subjectId: selectedSubjectId,
            status: selectedStatus,
            department: selectedDepartment,
            studentId: selectedStudentId
        )
    }
    
    public func subject(for experiment: Experiment) -> Subject? {
        dataStore.subject(byId: experiment.subjectId)
    }
    
    public func student(for experiment: Experiment) -> User? {
        guard let sid = experiment.studentId else { return nil }
        return dataStore.user(byId: sid)
    }
    
    public func canDelete(experiment: Experiment) -> Bool {
        guard user.role == .student else { return false }
        return experimentService.canStudentDelete(experiment: experiment, studentId: user.id)
    }
    
    public func deleteExperiment() {
        guard let exp = experimentToDelete else { return }
        do {
            try experimentService.deleteExperiment(id: exp.id, studentId: user.id)
            successToast = "\(exp.experimentNumber) deleted successfully."
            experimentToDelete = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            experimentToDelete = nil
        }
    }
    
    public func clearFilters() {
        searchText = ""
        selectedSubjectId = nil
        selectedStatus = nil
        selectedDepartment = "All"
        selectedStudentId = nil
    }
}
