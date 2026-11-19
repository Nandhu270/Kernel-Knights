import Foundation

/// Represents a user account in the application.
/// Note: Password is stored in plain text strictly for this local single-device academic demonstration
/// in accordance with project requirements. Production systems would use secure hashing and keychain storage.
public struct User: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var username: String
    public var password: String
    public var role: UserRole
    public var department: String
    public var isActive: Bool
    
    /// For students: The ID of their assigned mentor (optional until assigned)
    public var assignedMentorId: UUID?
    
    /// For mentors: The IDs of students assigned to this mentor
    public var assignedStudentIds: [UUID]
    
    public init(
        id: UUID = UUID(),
        name: String,
        username: String,
        password: String,
        role: UserRole,
        department: String = "Computer Science",
        isActive: Bool = true,
        assignedMentorId: UUID? = nil,
        assignedStudentIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.role = role
        self.department = department
        self.isActive = isActive
        self.assignedMentorId = assignedMentorId
        self.assignedStudentIds = assignedStudentIds
    }
}
