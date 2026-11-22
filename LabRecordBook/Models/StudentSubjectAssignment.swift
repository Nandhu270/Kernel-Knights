import Foundation

/// Represents an academic allocation of a student to a specific course subject under a supervising mentor.
/// Enforces subject-wise mentorship where a student can have different mentors across different subjects.
public struct StudentSubjectAssignment: Identifiable, Codable, Equatable {
    public let id: UUID
    public var studentId: UUID
    public var subjectId: UUID
    public var mentorId: UUID
    public var assignedDate: Date
    public var isActive: Bool
    
    public init(
        id: UUID = UUID(),
        studentId: UUID,
        subjectId: UUID,
        mentorId: UUID,
        assignedDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.studentId = studentId
        self.subjectId = subjectId
        self.mentorId = mentorId
        self.assignedDate = assignedDate
        self.isActive = isActive
    }
}
