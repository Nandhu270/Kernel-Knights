import Foundation
import Observation

/// ViewModel for Mentor viewing all assigned course subjects with cohort size and completion progress.
@Observable
public final class MentorSubjectsViewModel {
    public let mentor: User
    public let dataStore: AppDataStore
    public let allocationService: SubjectAllocationService
    public let analyticsService: AnalyticsService
    
    public init(mentor: User, dataStore: AppDataStore) {
        self.mentor = mentor
        self.dataStore = dataStore
        self.allocationService = SubjectAllocationService(dataStore: dataStore)
        self.analyticsService = AnalyticsService(dataStore: dataStore)
    }
    
    /// Course subjects assigned to this mentor
    public var subjects: [Subject] {
        allocationService.getSubjects(forMentorId: mentor.id)
    }
    
    public func studentCount(for subjectId: UUID) -> Int {
        dataStore.studentSubjectAssignments.filter {
            $0.mentorId == mentor.id && $0.subjectId == subjectId && $0.isActive
        }.count
    }
    
    public func completionPercentage(for subjectId: UUID) -> Double {
        let studentIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.mentorId == mentor.id && $0.subjectId == subjectId && $0.isActive }
            .map { $0.studentId })
        let exps = dataStore.experiments.filter {
            guard let sid = $0.studentId else { return false }
            return studentIds.contains(sid) && $0.subjectId == subjectId
        }
        guard !exps.isEmpty else { return 0.0 }
        let verified = exps.filter { $0.status == .verified }.count
        return (Double(verified) / Double(exps.count)) * 100.0
    }
    
    public func verifiedCount(for subjectId: UUID) -> Int {
        let studentIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.mentorId == mentor.id && $0.subjectId == subjectId && $0.isActive }
            .map { $0.studentId })
        return dataStore.experiments.filter {
            guard let sid = $0.studentId else { return false }
            return studentIds.contains(sid) && $0.subjectId == subjectId && $0.status == .verified
        }.count
    }
    
    public func totalExperimentsCount(for subjectId: UUID) -> Int {
        let studentIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.mentorId == mentor.id && $0.subjectId == subjectId && $0.isActive }
            .map { $0.studentId })
        return dataStore.experiments.filter {
            guard let sid = $0.studentId else { return false }
            return studentIds.contains(sid) && $0.subjectId == subjectId
        }.count
    }
}
