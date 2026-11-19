import Foundation

/// Represents a lab experiment entry created by or assigned to a student,
/// or a master template experiment created by a mentor.
public struct Experiment: Identifiable, Codable, Equatable {
    public let id: UUID
    public var experimentNumber: String
    public var title: String
    public var subjectId: UUID
    public var studentId: UUID?
    public var mentorId: UUID?
    public var date: Date
    public var aim: String
    public var procedure: String
    public var result: String
    public var status: ExperimentStatus
    public var isAssignedByMentor: Bool
    public var assignmentId: UUID?
    public var lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        experimentNumber: String,
        title: String,
        subjectId: UUID,
        studentId: UUID? = nil,
        mentorId: UUID? = nil,
        date: Date = Date(),
        aim: String,
        procedure: String,
        result: String = "",
        status: ExperimentStatus = .pending,
        isAssignedByMentor: Bool = false,
        assignmentId: UUID? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.experimentNumber = experimentNumber
        self.title = title
        self.subjectId = subjectId
        self.studentId = studentId
        self.mentorId = mentorId
        self.date = date
        self.aim = aim
        self.procedure = procedure
        self.result = result
        self.status = status
        self.isAssignedByMentor = isAssignedByMentor
        self.assignmentId = assignmentId
        self.lastUpdated = lastUpdated
    }
}
