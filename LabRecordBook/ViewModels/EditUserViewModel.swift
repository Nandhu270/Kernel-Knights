import Foundation
import Observation

/// ViewModel managing editing user information and activation status.
@Observable
public final class EditUserViewModel {
    public let originalUser: User
    public var name: String
    public var username: String
    public var password: String
    public var department: String
    public var isActive: Bool
    
    // Mentor assignment filtering
    public var mentorDepartment: String
    public var selectedMentorId: UUID?
    
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var isSaved: Bool = false
    
    public init(user: User) {
        self.originalUser = user
        self.name = user.name
        self.username = user.username
        self.password = user.password
        self.department = user.department
        self.isActive = user.isActive
        self.selectedMentorId = user.assignedMentorId
        self.mentorDepartment = user.department
    }
    
    public func availableMentors(from dataStore: AppDataStore) -> [User] {
        dataStore.users.filter {
            $0.role == .mentor &&
            $0.isActive &&
            $0.department.caseInsensitiveCompare(mentorDepartment) == .orderedSame
        }
    }
    
    public func validate() -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDept = department.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "Full Name cannot be empty."
        }
        if trimmedUsername.isEmpty {
            return "Username cannot be empty."
        }
        if trimmedPassword.isEmpty {
            return "Password cannot be empty."
        }
        if trimmedDept.isEmpty {
            return "Department cannot be empty."
        }
        return nil
    }
    
    public func saveChanges(userService: UserService) -> Bool {
        if let validationError = validate() {
            self.errorMessage = validationError
            self.showError = true
            return false
        }
        
        do {
            var updated = originalUser
            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.password = password.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.department = department.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.isActive = isActive
            
            try userService.updateUser(updated)
            
            // If student, update mentor assignment
            if originalUser.role == .student && selectedMentorId != originalUser.assignedMentorId {
                try userService.assignMentor(mentorId: selectedMentorId, toStudentId: originalUser.id)
            }
            
            self.isSaved = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
}
