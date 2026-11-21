import Foundation
import Observation

/// ViewModel managing mentor supervisory statistics, supervised student progress, and attention alerts.
@Observable
public final class MentorAnalyticsViewModel {
    public let mentor: User
    public let dataStore: AppDataStore
    public let analyticsService: AnalyticsService
    
    public var searchText: String = ""
    public var selectedDepartment: String = "All"
    
    public init(
        mentor: User,
        dataStore: AppDataStore,
        analyticsService: AnalyticsService? = nil
    ) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.analyticsService = analyticsService ?? AnalyticsService(dataStore: dataStore)
    }
    
    public var assignedStudents: [User] {
        analyticsService.getAssignedStudents(for: mentor.id)
    }
    
    public var assignedStudentsCount: Int {
        assignedStudents.count
    }
    
    public var totalAssignedExperimentsCount: Int {
        dataStore.assignments.filter { $0.mentorId == mentor.id }.count
    }
    
    public var supervisedExperiments: [Experiment] {
        let studentIds = Set(assignedStudents.map { $0.id })
        return dataStore.experiments.filter { exp in
            guard let sid = exp.studentId else { return false }
            return studentIds.contains(sid)
        }
    }
    
    public var pendingReviewsCount: Int {
        supervisedExperiments.filter { $0.status == .submitted }.count
    }
    
    public var verifiedCount: Int {
        supervisedExperiments.filter { $0.status == .verified }.count
    }
    
    public var rejectedCount: Int {
        supervisedExperiments.filter { $0.status == .rejected }.count
    }
    
    public var studentsRequiringAttention: [User] {
        analyticsService.getStudentsRequiringAttention(for: mentor.id)
    }
    
    public var studentSummaries: [StudentProgressSummary] {
        analyticsService.getMentorStudentProgress(for: mentor.id)
    }
    
    public var availableDepartments: [String] {
        let depts = Set(assignedStudents.map { $0.department })
        return ["All"] + Array(depts).sorted()
    }
    
    public var filteredStudentSummaries: [StudentProgressSummary] {
        studentSummaries.filter { summary in
            if selectedDepartment != "All" {
                if summary.student.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                    return false
                }
            }
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                return summary.student.name.lowercased().contains(query) ||
                       summary.student.username.lowercased().contains(query)
            }
            
            return true
        }
    }
    
    public func clearFilters() {
        searchText = ""
        selectedDepartment = "All"
    }
}
