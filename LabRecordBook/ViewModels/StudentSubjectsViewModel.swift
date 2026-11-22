import Foundation
import Observation

/// ViewModel for Student viewing all enrolled subjects with supervising mentors and progress.
@Observable
public final class StudentSubjectsViewModel {
    public let student: User
    public let dataStore: AppDataStore
    public let allocationService: SubjectAllocationService
    public let analyticsService: AnalyticsService
    
    public init(student: User, dataStore: AppDataStore) {
        self.student = student
        self.dataStore = dataStore
        self.allocationService = SubjectAllocationService(dataStore: dataStore)
        self.analyticsService = AnalyticsService(dataStore: dataStore)
    }
    
    /// All active subjects student is enrolled in under an allocated mentor
    public var enrolledSubjects: [Subject] {
        allocationService.getSubjects(forStudentId: student.id)
    }
    
    public func supervisingMentor(for subjectId: UUID) -> User? {
        allocationService.getAllocatedMentor(studentId: student.id, subjectId: subjectId) ?? student.assignedMentorId.flatMap { dataStore.user(byId: $0) }
    }
    
    public func progress(for subject: Subject) -> SubjectProgress {
        let exps = dataStore.experiments.filter {
            $0.studentId == student.id && $0.subjectId == subject.id
        }
        let verified = exps.filter { $0.status == .verified }.count
        let rejected = exps.filter { $0.status == .rejected }.count
        let pending = exps.filter { $0.status != .verified && $0.status != .rejected }.count
        
        return SubjectProgress(
            subject: subject,
            totalExperiments: exps.count,
            verifiedExperiments: verified,
            pendingExperiments: pending,
            rejectedExperiments: rejected
        )
    }
}
