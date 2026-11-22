import Foundation
import Observation

/// In-memory local data store acting as the single source of truth for the application.
/// In accordance with project instructions:
/// - Stored in memory and resets when application terminates.
/// - No Cloud, Firebase, Core Data, or SwiftData.
@Observable
public final class AppDataStore {
    public var departments: [Department] = []
    public var users: [User] = []
    public var subjects: [Subject] = []
    public var experiments: [Experiment] = []
    public var assignments: [Assignment] = []
    public var verifications: [Verification] = []
    public var mentorSubjectAssignments: [MentorSubjectAssignment] = []
    public var studentSubjectAssignments: [StudentSubjectAssignment] = []
    
    public init(populateSampleData: Bool = true) {
        if populateSampleData {
            resetToSampleData()
        }
    }
    
    /// Populates or resets all collections to predefined sample data.
    public func resetToSampleData() {
        self.departments = SampleData.departments
        self.users = SampleData.users
        self.subjects = SampleData.subjects
        self.experiments = SampleData.experiments
        self.assignments = SampleData.assignments
        self.verifications = SampleData.verifications
        self.mentorSubjectAssignments = SampleData.mentorSubjectAssignments
        self.studentSubjectAssignments = SampleData.studentSubjectAssignments
    }
    
    // MARK: - Query Helpers
    
    public func department(byId id: UUID) -> Department? {
        departments.first { $0.id == id }
    }
    
    public func department(byName name: String) -> Department? {
        departments.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
    
    public func user(byId id: UUID) -> User? {
        users.first { $0.id == id }
    }
    
    public func subject(byId id: UUID) -> Subject? {
        subjects.first { $0.id == id }
    }
    
    public func experiment(byId id: UUID) -> Experiment? {
        experiments.first { $0.id == id }
    }
    
    public func verifications(forExperimentId expId: UUID) -> [Verification] {
        verifications.filter { $0.experimentId == expId }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Subject Allocation Queries
    
    public func activeMentorSubjectAssignments(forSubjectId subjectId: UUID) -> [MentorSubjectAssignment] {
        mentorSubjectAssignments.filter { $0.subjectId == subjectId && $0.isActive }
    }
    
    public func activeMentorSubjectAssignments(forMentorId mentorId: UUID) -> [MentorSubjectAssignment] {
        mentorSubjectAssignments.filter { $0.mentorId == mentorId && $0.isActive }
    }
    
    public func activeStudentSubjectAssignment(studentId: UUID, subjectId: UUID) -> StudentSubjectAssignment? {
        studentSubjectAssignments.first { $0.studentId == studentId && $0.subjectId == subjectId && $0.isActive }
    }
    
    public func activeStudentSubjectAssignments(forStudentId studentId: UUID) -> [StudentSubjectAssignment] {
        studentSubjectAssignments.filter { $0.studentId == studentId && $0.isActive }
    }
    
    public func activeStudentSubjectAssignments(forMentorId mentorId: UUID) -> [StudentSubjectAssignment] {
        studentSubjectAssignments.filter { $0.mentorId == mentorId && $0.isActive }
    }
    
    public func activeStudentSubjectAssignments(forMentorId mentorId: UUID, subjectId: UUID) -> [StudentSubjectAssignment] {
        studentSubjectAssignments.filter { $0.mentorId == mentorId && $0.subjectId == subjectId && $0.isActive }
    }
}
