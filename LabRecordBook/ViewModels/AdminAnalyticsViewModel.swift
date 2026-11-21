import Foundation
import Observation

/// ViewModel managing system-wide institution analytics, mentor workloads, and student summaries for Admin.
@Observable
public final class AdminAnalyticsViewModel {
    public let dataStore: AppDataStore
    public let analyticsService: AnalyticsService
    
    public var studentSearchText: String = ""
    public var selectedDepartment: String = "All"
    
    public init(
        dataStore: AppDataStore,
        analyticsService: AnalyticsService? = nil
    ) {
        self.dataStore = dataStore
        self.analyticsService = analyticsService ?? AnalyticsService(dataStore: dataStore)
    }
    
    public var activeStudentsCount: Int {
        analyticsService.activeStudentsCount
    }
    
    public var activeMentorsCount: Int {
        analyticsService.activeMentorsCount
    }
    
    public var totalExperimentsCount: Int {
        analyticsService.totalStudentExperiments.count
    }
    
    public var totalVerifiedCount: Int {
        analyticsService.totalVerifiedCount
    }
    
    public var totalPendingReviewCount: Int {
        analyticsService.totalPendingReviewCount
    }
    
    public var totalRejectedCount: Int {
        analyticsService.totalRejectedCount
    }
    
    public var systemCompletionPercentage: Double {
        analyticsService.systemCompletionPercentage
    }
    
    public var studentSummaries: [StudentProgressSummary] {
        analyticsService.getAllStudentProgressSummaries()
    }
    
    public var mentorWorkloads: [MentorWorkloadSummary] {
        analyticsService.getMentorWorkloadSummaries()
    }
    
    public var subjectStatistics: [SubjectProgress] {
        analyticsService.getSystemSubjectStatistics()
    }
    
    public var availableDepartments: [String] {
        let depts = Set(dataStore.departments.map { $0.name })
        return ["All"] + Array(depts).sorted()
    }
    
    public var filteredStudentSummaries: [StudentProgressSummary] {
        studentSummaries.filter { summary in
            if selectedDepartment != "All" {
                if summary.student.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                    return false
                }
            }
            
            let query = studentSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                return summary.student.name.lowercased().contains(query) ||
                       summary.student.username.lowercased().contains(query)
            }
            
            return true
        }
    }
    
    public func clearFilters() {
        studentSearchText = ""
        selectedDepartment = "All"
    }
}
