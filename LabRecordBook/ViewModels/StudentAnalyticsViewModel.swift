import Foundation
import Observation

/// ViewModel providing progress analytics, subject distributions, and status counts for the Student portal.
@Observable
public final class StudentAnalyticsViewModel {
    public let student: User
    public let dataStore: AppDataStore
    public let analyticsService: AnalyticsService
    
    public init(
        student: User,
        dataStore: AppDataStore,
        analyticsService: AnalyticsService? = nil
    ) {
        self.student = student
        self.dataStore = dataStore
        self.analyticsService = analyticsService ?? AnalyticsService(dataStore: dataStore)
    }
    
    public var studentExperiments: [Experiment] {
        analyticsService.getStudentExperiments(for: student.id)
    }
    
    public var totalAssignedCount: Int {
        studentExperiments.count
    }
    
    public var inProgressCount: Int {
        studentExperiments.filter { $0.status == .inProgress || $0.status == .pending || $0.status == .assigned }.count
    }
    
    public var submittedCount: Int {
        studentExperiments.filter { $0.status == .submitted }.count
    }
    
    public var rejectedCount: Int {
        studentExperiments.filter { $0.status == .rejected }.count
    }
    
    public var verifiedCount: Int {
        studentExperiments.filter { $0.status == .verified }.count
    }
    
    public var completionPercentage: Double {
        analyticsService.getStudentCompletionPercentage(for: student.id)
    }
    
    public var subjectProgress: [SubjectProgress] {
        analyticsService.getSubjectProgress(for: student.id)
    }
    
    public var assignedMentor: User? {
        guard let mentorId = student.assignedMentorId else { return nil }
        return dataStore.user(byId: mentorId)
    }
}
