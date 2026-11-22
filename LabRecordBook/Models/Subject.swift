import Foundation

/// Represents an academic course subject in the lab curriculum.
/// Supports department grouping, active status, and robust backward-compatible decoding.
public struct Subject: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var code: String
    public var description: String
    public var department: String
    public var isActive: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        code: String,
        description: String = "",
        department: String = "Computer Science & Engineering",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        self.department = department.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isActive = isActive
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, description, department, isActive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.code = try container.decode(String.self, forKey: .code)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? "Computer Science & Engineering"
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
    }
}
