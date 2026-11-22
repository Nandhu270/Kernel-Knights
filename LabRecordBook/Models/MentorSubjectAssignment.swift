import Foundation

/// Represents the authorization of a faculty mentor to teach and supervise a course subject.
public struct MentorSubjectAssignment: Identifiable, Codable, Equatable {
    public let id: UUID
    public var mentorId: UUID
    public var subjectId: UUID
    public var assignedDate: Date
    public var isActive: Bool
    
    public init(
        id: UUID = UUID(),
        mentorId: UUID,
        subjectId: UUID,
        assignedDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.mentorId = mentorId
        self.subjectId = subjectId
        self.assignedDate = assignedDate
        self.isActive = isActive
    }
}
