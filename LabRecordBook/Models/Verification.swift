import Foundation

/// Represents a review and verification event by a mentor.
/// Stored in a historical log to maintain full audit history rather than overwriting previous reviews.
public struct Verification: Identifiable, Codable, Equatable {
    public let id: UUID
    public let experimentId: UUID
    public let mentorId: UUID
    public let mentorName: String
    public let status: ExperimentStatus // .verified or .rejected
    public let comments: String
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        experimentId: UUID,
        mentorId: UUID,
        mentorName: String,
        status: ExperimentStatus,
        comments: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.experimentId = experimentId
        self.mentorId = mentorId
        self.mentorName = mentorName
        self.status = status
        self.comments = comments
        self.timestamp = timestamp
    }
}
