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

/// Structured report data for a student's lab record book
public struct StudentReportData: Equatable {
    public let student: User
    public let mentor: User?
    public let totalExperiments: Int
    public let inProgressCount: Int
    public let submittedCount: Int
    public let verifiedCount: Int
    public let rejectedCount: Int
    public let completionPercentage: Double
    public let subjectProgress: [SubjectProgress]
    public let experiments: [Experiment]
    public let generatedDate: Date
    
    public init(
        student: User,
        mentor: User?,
        totalExperiments: Int,
        inProgressCount: Int,
        submittedCount: Int,
        verifiedCount: Int,
        rejectedCount: Int,
        completionPercentage: Double,
        subjectProgress: [SubjectProgress],
        experiments: [Experiment],
        generatedDate: Date = Date()
    ) {
        self.student = student
        self.mentor = mentor
        self.totalExperiments = totalExperiments
        self.inProgressCount = inProgressCount
        self.submittedCount = submittedCount
        self.verifiedCount = verifiedCount
        self.rejectedCount = rejectedCount
        self.completionPercentage = completionPercentage
        self.subjectProgress = subjectProgress
        self.experiments = experiments
        self.generatedDate = generatedDate
    }
}

/// Structured report data for a mentor's supervised cohort
public struct MentorReportData: Equatable {
    public let mentor: User
    public let assignedStudents: [User]
    public let totalAssignedExperimentsCount: Int
    public let pendingReviewsCount: Int
    public let verifiedCount: Int
    public let rejectedCount: Int
    public let studentSummaries: [StudentProgressSummary]
    public let generatedDate: Date
    
    public init(
        mentor: User,
        assignedStudents: [User],
        totalAssignedExperimentsCount: Int,
        pendingReviewsCount: Int,
        verifiedCount: Int,
        rejectedCount: Int,
        studentSummaries: [StudentProgressSummary],
        generatedDate: Date = Date()
    ) {
        self.mentor = mentor
        self.assignedStudents = assignedStudents
        self.totalAssignedExperimentsCount = totalAssignedExperimentsCount
        self.pendingReviewsCount = pendingReviewsCount
        self.verifiedCount = verifiedCount
        self.rejectedCount = rejectedCount
        self.studentSummaries = studentSummaries
        self.generatedDate = generatedDate
    }
}

/// Structured report data for administrator institutional audit
public struct AdminReportData: Equatable {
    public let activeStudentsCount: Int
    public let activeMentorsCount: Int
    public let totalExperimentsCount: Int
    public let verifiedCount: Int
    public let pendingReviewCount: Int
    public let rejectedCount: Int
    public let overallCompletionPercentage: Double
    public let studentSummaries: [StudentProgressSummary]
    public let mentorWorkloads: [MentorWorkloadSummary]
    public let subjectStatistics: [SubjectProgress]
    public let generatedDate: Date
    
    public init(
        activeStudentsCount: Int,
        activeMentorsCount: Int,
        totalExperimentsCount: Int,
        verifiedCount: Int,
        pendingReviewCount: Int,
        rejectedCount: Int,
        overallCompletionPercentage: Double,
        studentSummaries: [StudentProgressSummary],
        mentorWorkloads: [MentorWorkloadSummary],
        subjectStatistics: [SubjectProgress],
        generatedDate: Date = Date()
    ) {
        self.activeStudentsCount = activeStudentsCount
        self.activeMentorsCount = activeMentorsCount
        self.totalExperimentsCount = totalExperimentsCount
        self.verifiedCount = verifiedCount
        self.pendingReviewCount = pendingReviewCount
        self.rejectedCount = rejectedCount
        self.overallCompletionPercentage = overallCompletionPercentage
        self.studentSummaries = studentSummaries
        self.mentorWorkloads = mentorWorkloads
        self.subjectStatistics = subjectStatistics
        self.generatedDate = generatedDate
    }
}

public enum AnalyticsServiceError: LocalizedError {
    case unauthorized(String)
    case studentNotFound
    case mentorNotFound
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized(let reason):
            return "Unauthorized access: \(reason)"
        case .studentNotFound:
            return "Student account could not be found."
        case .mentorNotFound:
            return "Mentor account could not be found."
        }
    }
}

/// Service calculating dynamic analytics, progress tracking, and statistical aggregations with permission enforcement.
@Observable
public final class AnalyticsService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Student Analytics
    
    /// Returns all experiments belonging to a student (strictly excluding mentor master templates where studentId is nil)
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
    
    /// Calculates subject-wise progress breakdown for a student.
    /// Includes all subjects the student is actively allocated to, plus any subjects with historical experiments.
    public func getSubjectProgress(for studentId: UUID) -> [SubjectProgress] {
        let studentExps = getStudentExperiments(for: studentId)
        let activeSubjectIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.studentId == studentId && $0.isActive }
            .map { $0.subjectId })
        let experimentSubjectIds = Set(studentExps.map { $0.subjectId })
        let relevantSubjectIds = activeSubjectIds.union(experimentSubjectIds)
        
        return dataStore.subjects.compactMap { subject in
            guard relevantSubjectIds.contains(subject.id) else { return nil }
            let expsForSubj = studentExps.filter { $0.subjectId == subject.id }
            
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
    
    /// Returns all active subjects a student is enrolled in under an active mentor.
    public func getEnrolledSubjects(for studentId: UUID) -> [Subject] {
        let activeSubjectIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.studentId == studentId && $0.isActive }
            .map { $0.subjectId })
        return dataStore.subjects.filter { activeSubjectIds.contains($0.id) && $0.isActive }
    }
    
    // MARK: - Mentor Analytics
    
    /// Students supervised by the mentor (both subject-allocated and legacy active students)
    public func getAssignedStudents(for mentorId: UUID) -> [User] {
        let subjectAllocatedIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.mentorId == mentorId && $0.isActive }
            .map { $0.studentId })
        let legacyIds = Set(dataStore.users
            .filter { $0.role == .student && $0.assignedMentorId == mentorId && $0.isActive }
            .map { $0.id })
        let allIds = subjectAllocatedIds.union(legacyIds)
        return dataStore.users.filter { allIds.contains($0.id) && $0.isActive }
    }
    
    /// Returns all active subjects taught by this mentor
    public func getMentoredSubjects(for mentorId: UUID) -> [Subject] {
        let subjectIds = Set(dataStore.mentorSubjectAssignments
            .filter { $0.mentorId == mentorId && $0.isActive }
            .map { $0.subjectId })
        return dataStore.subjects.filter { subjectIds.contains($0.id) && $0.isActive }
    }
    
    /// Student progress summaries for all students allocated to this mentor in a specific subject
    public func getSubjectStudentProgress(forMentorId mentorId: UUID, subjectId: UUID) -> [StudentProgressSummary] {
        let allocatedStudentIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.mentorId == mentorId && $0.subjectId == subjectId && $0.isActive }
            .map { $0.studentId })
        let students = dataStore.users.filter { allocatedStudentIds.contains($0.id) && $0.isActive }
        
        return students.map { student in
            let exps = getStudentExperiments(for: student.id).filter { $0.subjectId == subjectId }
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
    
    /// Completion percentage for a given subject across all student experiments
    public func getSubjectCompletionPercentage(subjectId: UUID) -> Double {
        let exps = totalStudentExperiments.filter { $0.subjectId == subjectId }
        guard !exps.isEmpty else { return 0.0 }
        let verified = exps.filter { $0.status == .verified }.count
        return (Double(verified) / Double(exps.count)) * 100.0
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
    
    /// Returns supervised students requiring mentor attention (e.g. have rejected work needing correction or pending submissions)
    public func getStudentsRequiringAttention(for mentorId: UUID) -> [User] {
        let progressList = getMentorStudentProgress(for: mentorId)
        let attentionStudentIds = Set(progressList.filter { $0.requiresAttention }.map { $0.student.id })
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
    
    /// Total student experiments (strictly excluding mentor master templates where studentId is nil)
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
    
    /// System-wide student progress summaries (for active students)
    public func getAllStudentProgressSummaries() -> [StudentProgressSummary] {
        let students = dataStore.users.filter { $0.role == .student && $0.isActive }
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
    
    // MARK: - Permission-Enforced Report Queries
    
    /// Generates structured student report data after enforcing permission boundaries:
    /// - Student: Can access only their own report data
    /// - Mentor: Can access report only if the student is actively assigned to them
    /// - Admin: Full authorized access
    public func getStudentReportData(studentId: UUID, requestingUser: User) throws -> StudentReportData {
        guard let student = dataStore.user(byId: studentId), student.role == .student else {
            throw AnalyticsServiceError.studentNotFound
        }
        
        // Permission check
        switch requestingUser.role {
        case .student:
            guard requestingUser.id == studentId else {
                throw AnalyticsServiceError.unauthorized("Students may only access their own lab report records.")
            }
        case .mentor:
            guard student.assignedMentorId == requestingUser.id else {
                throw AnalyticsServiceError.unauthorized("Mentors may only access reports for students assigned to them.")
            }
        case .admin:
            break
        }
        
        let exps = getStudentExperiments(for: studentId).sorted {
            $0.experimentNumber.localizedStandardCompare($1.experimentNumber) == .orderedAscending
        }
        let verifiedCount = exps.filter { $0.status == .verified }.count
        let rejectedCount = exps.filter { $0.status == .rejected }.count
        let submittedCount = exps.filter { $0.status == .submitted }.count
        let inProgressCount = exps.filter { $0.status == .inProgress || $0.status == .pending || $0.status == .assigned }.count
        let completionPercentage = getStudentCompletionPercentage(for: studentId)
        let subjectProgress = getSubjectProgress(for: studentId)
        let mentor = student.assignedMentorId.flatMap { dataStore.user(byId: $0) }
        
        return StudentReportData(
            student: student,
            mentor: mentor,
            totalExperiments: exps.count,
            inProgressCount: inProgressCount,
            submittedCount: submittedCount,
            verifiedCount: verifiedCount,
            rejectedCount: rejectedCount,
            completionPercentage: completionPercentage,
            subjectProgress: subjectProgress,
            experiments: exps,
            generatedDate: Date()
        )
    }
    
    /// Generates structured mentor report data after enforcing permission boundaries:
    /// - Mentor: Can access only their own mentor report
    /// - Admin: Full authorized access
    /// - Student: Strictly unauthorized
    public func getMentorReportData(mentorId: UUID, requestingUser: User) throws -> MentorReportData {
        guard let mentor = dataStore.user(byId: mentorId), mentor.role == .mentor else {
            throw AnalyticsServiceError.mentorNotFound
        }
        
        // Permission check
        switch requestingUser.role {
        case .student:
            throw AnalyticsServiceError.unauthorized("Students do not have permission to view mentor reports.")
        case .mentor:
            guard requestingUser.id == mentorId else {
                throw AnalyticsServiceError.unauthorized("Mentors may only access their own supervisory report.")
            }
        case .admin:
            break
        }
        
        let assignedStudents = getAssignedStudents(for: mentorId)
        let studentSummaries = getMentorStudentProgress(for: mentorId)
        let totalAssigned = dataStore.assignments.filter { $0.mentorId == mentorId }.count
        
        let supervisedExps = dataStore.experiments.filter { exp in
            guard let sid = exp.studentId else { return false }
            return assignedStudents.contains { $0.id == sid }
        }
        let pendingReviews = supervisedExps.filter { $0.status == .submitted }.count
        let verifiedCount = supervisedExps.filter { $0.status == .verified }.count
        let rejectedCount = supervisedExps.filter { $0.status == .rejected }.count
        
        return MentorReportData(
            mentor: mentor,
            assignedStudents: assignedStudents,
            totalAssignedExperimentsCount: totalAssigned,
            pendingReviewsCount: pendingReviews,
            verifiedCount: verifiedCount,
            rejectedCount: rejectedCount,
            studentSummaries: studentSummaries,
            generatedDate: Date()
        )
    }
    
    /// Generates structured admin system report data:
    /// - Admin: Only administrators can access
    /// - Student/Mentor: Strictly unauthorized
    public func getAdminReportData(requestingUser: User) throws -> AdminReportData {
        guard requestingUser.role == .admin else {
            throw AnalyticsServiceError.unauthorized("Only administrators are permitted to generate system-wide audit reports.")
        }
        
        return AdminReportData(
            activeStudentsCount: activeStudentsCount,
            activeMentorsCount: activeMentorsCount,
            totalExperimentsCount: totalStudentExperiments.count,
            verifiedCount: totalVerifiedCount,
            pendingReviewCount: totalPendingReviewCount,
            rejectedCount: totalRejectedCount,
            overallCompletionPercentage: systemCompletionPercentage,
            studentSummaries: getAllStudentProgressSummaries(),
            mentorWorkloads: getMentorWorkloadSummaries(),
            subjectStatistics: getSystemSubjectStatistics(),
            generatedDate: Date()
        )
    }
}
