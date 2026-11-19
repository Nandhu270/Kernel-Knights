import Foundation

/// Status of an experiment assignment.
public enum AssignmentStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case completed = "Completed"
    
    public var displayName: String { rawValue }
}

/// Represents an experiment assigned by a mentor to a specific student.
public struct Assignment: Identifiable, Codable, Equatable {
    public let id: UUID
    public var mentorId: UUID
    public var studentId: UUID
    public var subjectId: UUID
    public var experimentId: UUID?          // Master template experiment ID
    public var studentExperimentId: UUID?   // Student's independent experiment record ID
    public var experimentNumber: String
    public var title: String
    public var aim: String
    public var procedure: String
    public var assignedDate: Date
    public var dueDate: Date
    public var status: AssignmentStatus
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        mentorId: UUID,
        studentId: UUID,
        subjectId: UUID,
        title: String,
        aim: String,
        procedure: String,
        experimentNumber: String = "",
        assignedDate: Date = Date(),
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        status: AssignmentStatus = .pending,
        isCompleted: Bool = false,
        experimentId: UUID? = nil,
        studentExperimentId: UUID? = nil
    ) {
        self.id = id
        self.mentorId = mentorId
        self.studentId = studentId
        self.subjectId = subjectId
        self.experimentId = experimentId
        self.studentExperimentId = studentExperimentId
        self.experimentNumber = experimentNumber
        self.title = title
        self.aim = aim
        self.procedure = procedure
        self.assignedDate = assignedDate
        self.dueDate = dueDate
        self.status = isCompleted ? .completed : status
        self.isCompleted = (status == .completed) || isCompleted
    }
}
