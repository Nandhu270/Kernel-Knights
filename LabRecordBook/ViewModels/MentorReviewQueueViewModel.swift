import Foundation
import Observation

/// ViewModel managing the mentor's review queue of submitted experiments with search, subject, student, and department filtering.
@Observable
public final class MentorReviewQueueViewModel {
    public let mentor: User
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    public let verificationService: VerificationService
    
    public var searchText: String = ""
    public var selectedSubjectId: UUID?
    public var selectedDepartment: String = "All"
    public var selectedStudentId: UUID?
    
    public init(mentor: User, dataStore: AppDataStore) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
        self.verificationService = VerificationService(dataStore: dataStore)
    }
    
    /// All submitted experiments pending mentor review from assigned students
    public var pendingSubmissions: [Experiment] {
        let assignedStudentIds = Set(dataStore.users.filter { $0.role == .student && $0.assignedMentorId == mentor.id }.map { $0.id })
        
        return dataStore.experiments
            .filter { exp in
                guard exp.status == .submitted else { return false }
                if let sid = exp.studentId {
                    return assignedStudentIds.contains(sid) || exp.mentorId == mentor.id
                }
                return false
            }
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    /// Filtered submissions by search text, subject, department, and student
    public var filteredSubmissions: [Experiment] {
        pendingSubmissions.filter { exp in
            // Search text
            let matchesQuery: Bool
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty {
                matchesQuery = true
            } else {
                let titleMatch = exp.title.lowercased().contains(trimmed)
                let numMatch = exp.experimentNumber.lowercased().contains(trimmed)
                let studentName = exp.studentId.flatMap { dataStore.user(byId: $0)?.name.lowercased() } ?? ""
                let studentMatch = studentName.contains(trimmed)
                matchesQuery = titleMatch || numMatch || studentMatch
            }
            
            // Subject filter
            let matchesSubject: Bool
            if let subjId = selectedSubjectId {
                matchesSubject = exp.subjectId == subjId
            } else {
                matchesSubject = true
            }
            
            // Department filter
            let matchesDepartment: Bool
            if selectedDepartment != "All" {
                if let sid = exp.studentId, let student = dataStore.user(byId: sid) {
                    matchesDepartment = student.department.caseInsensitiveCompare(selectedDepartment) == .orderedSame
                } else {
                    matchesDepartment = false
                }
            } else {
                matchesDepartment = true
            }
            
            // Student filter
            let matchesStudent: Bool
            if let sid = selectedStudentId {
                matchesStudent = exp.studentId == sid
            } else {
                matchesStudent = true
            }
            
            return matchesQuery && matchesSubject && matchesDepartment && matchesStudent
        }
    }
    
    public var availableSubjects: [Subject] {
        dataStore.subjects
    }
    
    public var availableDepartments: [String] {
        let depts = Set(pendingSubmissions.compactMap { exp -> String? in
            guard let sid = exp.studentId, let student = dataStore.user(byId: sid) else { return nil }
            return student.department
        })
        return ["All"] + Array(depts).sorted()
    }
    
    public var studentsWithSubmissions: [User] {
        let studentIds = Set(pendingSubmissions.compactMap { $0.studentId })
        return studentIds.compactMap { dataStore.user(byId: $0) }.sorted { $0.name < $1.name }
    }
    
    public func student(for experiment: Experiment) -> User? {
        guard let sid = experiment.studentId else { return nil }
        return dataStore.user(byId: sid)
    }
    
    public func subject(for experiment: Experiment) -> Subject? {
        dataStore.subject(byId: experiment.subjectId)
    }
    
    public func clearFilters() {
        searchText = ""
        selectedSubjectId = nil
        selectedDepartment = "All"
        selectedStudentId = nil
    }
}
