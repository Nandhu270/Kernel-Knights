import Foundation

/// Model representing an academic department within the institution (e.g. Computer Science, Information Technology).
public struct Department: Identifiable, Codable, Hashable, Equatable {
    public let id: UUID
    public var name: String
    public var code: String
    
    public init(id: UUID = UUID(), name: String, code: String = "") {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
