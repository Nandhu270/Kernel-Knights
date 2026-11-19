import Foundation
import Observation

/// Subject-level progress metrics
public struct SubjectProgress: Identifiable, Equatable {
    public var id: UUID { subject.id }
    public let subject: Subject
    public let totalExperiments: Int
    public let verifiedExperiments: Int
    public let pendingExperiments: Int
    public let rejectedExperiments: Int
    
    public var completionPercentage: Double {
        guard totalExperiments > 0 else { return 0.0 }
        return (Double(verifiedExperiments) / Double(totalExperiments)) * 100.0
    }
    
    public init(
        subject: Subject,
        totalExperiments: Int,
        verifiedExperiments: Int,
        pendingExperiments: Int,
        rejectedExperiments: Int = 0
    ) {
        self.subject = subject
        self.totalExperiments = totalExperiments
        self.verifiedExperiments = verifiedExperiments
        self.pendingExperiments = pendingExperiments
        self.rejectedExperiments = rejectedExperiments
    }
}

/// Student progress summary for mentor and admin analytics
public struct StudentProgressSummary: Identifiable, Equatable {
    public var id: UUID { student.id }
    public let student: User
    public let totalAssigned: Int
    public let verifiedCount: Int
    public let pendingCount: Int
    public let rejectedCount: Int
    
    public var completionPercentage: Double {
        guard totalAssigned > 0 else { return 0.0 }
        return (Double(verifiedCount) / Double(totalAssigned)) * 100.0
    }
    
    public var requiresAttention: Bool {
        rejectedCount > 0
    }
    
    public init(
        student: User,
        totalAssigned: Int,
        verifiedCount: Int,
        pendingCount: Int,
        rejectedCount: Int = 0
    ) {
        self.student = student
        self.totalAssigned = totalAssigned
        self.verifiedCount = verifiedCount
        self.pendingCount = pendingCount
        self.rejectedCount = rejectedCount
    }
}

/// Mentor workload and supervisory summary for admin analytics
public struct MentorWorkloadSummary: Identifiable, Equatable {
    public var id: UUID { mentor.id }
    public let mentor: User
    public let assignedStudentsCount: Int
    public let assignedExperimentsCount: Int
    public let pendingReviewsCount: Int
    public let verifiedCount: Int
    
    public init(
        mentor: User,
        assignedStudentsCount: Int,
        assignedExperimentsCount: Int,
        pendingReviewsCount: Int,
        verifiedCount: Int
    ) {
        self.mentor = mentor
        self.assignedStudentsCount = assignedStudentsCount
        self.assignedExperimentsCount = assignedExperimentsCount
        self.pendingReviewsCount = pendingReviewsCount
        self.verifiedCount = verifiedCount
    }
}

/// Service calculating dynamic analytics, progress tracking, and statistical aggregations.
@Observable
public final class AnalyticsService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Student Analytics
    
    /// Returns all experiments belonging to a student (excluding mentor master templates)
    public func getStudentExperiments(for studentId: UUID) -> [Experiment] {
        dataStore.experiments.filter { $0.studentId == studentId }
    }
    
    /// Calculates completion percentage for a student: (Verified / Total Assigned) * 100
    /// Handles zero total experiments gracefully by returning 0.0.
    public func getStudentCompletionPercentage(for studentId: UUID) -> Double {
        let experiments = getStudentExperiments(for: studentId)
        guard !experiments.isEmpty else { return 0.0 }
        
        let verifiedCount = experiments.filter { $0.status == .verified }.count
        return (Double(verifiedCount) / Double(experiments.count)) * 100.0
    }
    
    /// Calculates subject-wise progress breakdown for a student
    public func getSubjectProgress(for studentId: UUID) -> [SubjectProgress] {
        let studentExps = getStudentExperiments(for: studentId)
        
        return dataStore.subjects.compactMap { subject in
            let expsForSubj = studentExps.filter { $0.subjectId == subject.id }
            guard !expsForSubj.isEmpty else { return nil }
            
            let verified = expsForSubj.filter { $0.status == .verified }.count
            let rejected = expsForSubj.filter { $0.status == .rejected }.count
            let pending = expsForSubj.filter { $0.status != .verified && $0.status != .rejected }.count
            
            return SubjectProgress(
                subject: subject,
                totalExperiments: expsForSubj.count,
                verifiedExperiments: verified,
                pendingExperiments: pending,
                rejectedExperiments: rejected
            )
        }
    }
    
    // MARK: - Mentor Analytics
    
    /// Students supervised by the mentor (only active students)
    public func getAssignedStudents(for mentorId: UUID) -> [User] {
        dataStore.users.filter { $0.role == .student && $0.assignedMentorId == mentorId && $0.isActive }
    }
    
    /// Student progress summaries for all students assigned to a mentor
    public func getMentorStudentProgress(for mentorId: UUID) -> [StudentProgressSummary] {
        let students = getAssignedStudents(for: mentorId)
        
        return students.map { student in
            let exps = getStudentExperiments(for: student.id)
            let verified = exps.filter { $0.status == .verified }.count
            let rejected = exps.filter { $0.status == .rejected }.count
            let pending = exps.filter { $0.status != .verified && $0.status != .rejected }.count
            
            return StudentProgressSummary(
                student: student,
                totalAssigned: exps.count,
                verifiedCount: verified,
                pendingCount: pending,
                rejectedCount: rejected
            )
        }
    }
    
    /// Returns supervised students requiring mentor attention (e.g. have rejected work needing review or pending submissions)
    public func getStudentsRequiringAttention(for mentorId: UUID) -> [User] {
        let progressList = getMentorStudentProgress(for: mentorId)
        let attentionStudentIds = Set(progressList.filter { $0.requiresAttention || $0.pendingCount > 0 }.map { $0.student.id })
        return dataStore.users.filter { attentionStudentIds.contains($0.id) }
    }
    
    // MARK: - Admin System-Wide Analytics
    
    /// Active students count (excluding deactivated)
    public var activeStudentsCount: Int {
        dataStore.users.filter { $0.role == .student && $0.isActive }.count
    }
    
    /// Active mentors count (excluding deactivated)
    public var activeMentorsCount: Int {
        dataStore.users.filter { $0.role == .mentor && $0.isActive }.count
    }
    
    /// Total student experiments (excluding master templates)
    public var totalStudentExperiments: [Experiment] {
        dataStore.experiments.filter { $0.studentId != nil }
    }
    
    public var totalVerifiedCount: Int {
        totalStudentExperiments.filter { $0.status == .verified }.count
    }
    
    public var totalPendingReviewCount: Int {
        totalStudentExperiments.filter { $0.status == .submitted }.count
    }
    
    public var totalRejectedCount: Int {
        totalStudentExperiments.filter { $0.status == .rejected }.count
    }
    
    /// System-wide completion percentage
    public var systemCompletionPercentage: Double {
        guard !totalStudentExperiments.isEmpty else { return 0.0 }
        return (Double(totalVerifiedCount) / Double(totalStudentExperiments.count)) * 100.0
    }
    
    /// System-wide mentor workload overview
    public func getMentorWorkloadSummaries() -> [MentorWorkloadSummary] {
        let mentors = dataStore.users.filter { $0.role == .mentor && $0.isActive }
        
        return mentors.map { mentor in
            let assignedStudents = dataStore.users.filter { $0.role == .student && $0.assignedMentorId == mentor.id && $0.isActive }
            let studentIds = Set(assignedStudents.map { $0.id })
            
            let supervisedExps = dataStore.experiments.filter {
                if let sid = $0.studentId { return studentIds.contains(sid) }
                return false
            }
            let pendingReviews = supervisedExps.filter { $0.status == .submitted }.count
            let verified = supervisedExps.filter { $0.status == .verified }.count
            let totalAssigned = dataStore.assignments.filter { $0.mentorId == mentor.id }.count
            
            return MentorWorkloadSummary(
                mentor: mentor,
                assignedStudentsCount: assignedStudents.count,
                assignedExperimentsCount: totalAssigned,
                pendingReviewsCount: pendingReviews,
                verifiedCount: verified
            )
        }
    }
    
    /// System-wide subject statistics
    public func getSystemSubjectStatistics() -> [SubjectProgress] {
        let allStudentExps = totalStudentExperiments
        
        return dataStore.subjects.map { subject in
            let exps = allStudentExps.filter { $0.subjectId == subject.id }
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
}
