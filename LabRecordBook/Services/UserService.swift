import Foundation
import Observation

public enum UserServiceError: LocalizedError {
    case userNotFound
    case usernameAlreadyExists
    case emptyFields
    case unauthorized
    case cannotDeactivateAdmin
    case studentAlreadyHasMentor
    
    public var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User account could not be found."
        case .usernameAlreadyExists:
            return "A user with this username already exists. Please choose a different username."
        case .emptyFields:
            return "Required fields cannot be empty."
        case .unauthorized:
            return "You do not have permission to perform this action."
        case .cannotDeactivateAdmin:
            return "The primary Administrator account cannot be deactivated."
        case .studentAlreadyHasMentor:
            return "This student already has an assigned mentor."
        }
    }
}

/// Service providing user management operations for Admin and user lookups.
@Observable
public final class UserService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Queries
    
    public func getAllUsers() -> [User] {
        dataStore.users
    }
    
    public func getStudents() -> [User] {
        dataStore.users.filter { $0.role == .student }
    }
    
    public func getMentors() -> [User] {
        dataStore.users.filter { $0.role == .mentor }
    }
    
    public func getAssignedStudents(forMentorId mentorId: UUID) -> [User] {
        dataStore.users.filter { $0.role == .student && $0.assignedMentorId == mentorId }
    }
    
    public func getUser(byId id: UUID) -> User? {
        dataStore.user(byId: id)
    }
    
    public func getMentor(forStudentId studentId: UUID) -> User? {
        guard let student = dataStore.user(byId: studentId),
              let mentorId = student.assignedMentorId else {
            return nil
        }
        return dataStore.user(byId: mentorId)
    }
    
    // MARK: - Admin Mutations
    
    /// Creates a new Student or Mentor account with validation.
    @discardableResult
    public func createUser(
        name: String,
        username: String,
        password: String,
        role: UserRole,
        department: String,
        assignedMentorId: UUID? = nil
    ) throws -> User {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedUsername.isEmpty, !trimmedPass.isEmpty else {
            throw UserServiceError.emptyFields
        }
        
        if dataStore.users.contains(where: { $0.username.caseInsensitiveCompare(trimmedUsername) == .orderedSame }) {
            throw UserServiceError.usernameAlreadyExists
        }
        
        let newUser = User(
            name: trimmedName,
            username: trimmedUsername,
            password: trimmedPass,
            role: role,
            department: department.isEmpty ? "Computer Science" : department,
            isActive: true,
            assignedMentorId: role == .student ? assignedMentorId : nil
        )
        
        dataStore.users.append(newUser)
        
        // If assigned to a mentor, update mentor's assigned student list
        if role == .student,
           let mentorId = assignedMentorId,
           let mentorIndex = dataStore.users.firstIndex(where: { $0.id == mentorId }) {
            if !dataStore.users[mentorIndex].assignedStudentIds.contains(newUser.id) {
                dataStore.users[mentorIndex].assignedStudentIds.append(newUser.id)
            }
        }
        
        return newUser
    }
    
    /// Updates user profile details, ensuring unique username and non-empty values.
    public func updateUser(_ updatedUser: User) throws {
        guard let index = dataStore.users.firstIndex(where: { $0.id == updatedUser.id }) else {
            throw UserServiceError.userNotFound
        }
        
        let trimmedName = updatedUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = updatedUser.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = updatedUser.password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedUsername.isEmpty, !trimmedPass.isEmpty else {
            throw UserServiceError.emptyFields
        }
        
        // Prevent duplicate username with other users
        let duplicate = dataStore.users.contains {
            $0.id != updatedUser.id && $0.username.caseInsensitiveCompare(trimmedUsername) == .orderedSame
        }
        if duplicate {
            throw UserServiceError.usernameAlreadyExists
        }
        
        var userToSave = updatedUser
        userToSave.name = trimmedName
        userToSave.username = trimmedUsername
        userToSave.password = trimmedPass
        
        dataStore.users[index] = userToSave
    }
    
    /// Activates or deactivates a user account.
    /// Admin account is protected from deactivation.
    public func toggleUserActiveStatus(userId: UUID) throws {
        guard let index = dataStore.users.firstIndex(where: { $0.id == userId }) else {
            throw UserServiceError.userNotFound
        }
        
        let user = dataStore.users[index]
        if user.role == .admin && user.isActive {
            throw UserServiceError.cannotDeactivateAdmin
        }
        
        dataStore.users[index].isActive.toggle()
    }
    
    /// Explicitly sets the activation status of a user account.
    public func setUserActiveStatus(userId: UUID, isActive: Bool) throws {
        guard let index = dataStore.users.firstIndex(where: { $0.id == userId }) else {
            throw UserServiceError.userNotFound
        }
        
        let user = dataStore.users[index]
        if user.role == .admin && !isActive {
            throw UserServiceError.cannotDeactivateAdmin
        }
        
        dataStore.users[index].isActive = isActive
    }
    
    /// Assigns or reassigns a mentor to a student.
    /// Enforces the requirement that a student has only one currently assigned mentor.
    /// Reciprocally updates the student's assignedMentorId and both mentors' assignedStudentIds.
    public func assignMentor(mentorId: UUID?, toStudentId studentId: UUID) throws {
        guard let studentIndex = dataStore.users.firstIndex(where: { $0.id == studentId }) else {
            throw UserServiceError.userNotFound
        }
        
        // 1. Remove student from previous mentor's assigned list if previously assigned
        if let previousMentorId = dataStore.users[studentIndex].assignedMentorId,
           let previousMentorIndex = dataStore.users.firstIndex(where: { $0.id == previousMentorId }) {
            dataStore.users[previousMentorIndex].assignedStudentIds.removeAll { $0 == studentId }
        }
        
        // 2. Set student's single assigned mentor
        dataStore.users[studentIndex].assignedMentorId = mentorId
        
        // 3. Add student to new mentor's assigned list
        if let newMentorId = mentorId,
           let newMentorIndex = dataStore.users.firstIndex(where: { $0.id == newMentorId }) {
            if !dataStore.users[newMentorIndex].assignedStudentIds.contains(studentId) {
                dataStore.users[newMentorIndex].assignedStudentIds.append(studentId)
            }
        }
    }
    
    /// Removes the assigned mentor from a student.
    public func unassignMentor(fromStudentId studentId: UUID) throws {
        try assignMentor(mentorId: nil, toStudentId: studentId)
    }
}
