import Foundation

/// Represents an academic course subject in the lab curriculum.
public struct Subject: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var code: String
    public var description: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        code: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.description = description
    }
}
