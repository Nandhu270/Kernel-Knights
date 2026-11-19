import Foundation
import Observation

/// ViewModel managing state, validation, and submission for creating new Student or Mentor accounts.
@Observable
public final class CreateUserViewModel {
    public var name: String = ""
    public var username: String = ""
    public var password: String = ""
    public var role: UserRole = .student
    public var department: String = "Computer Science & Engineering"
    
    // Mentor filtering by department when creating a student
    public var mentorDepartment: String = "Computer Science & Engineering"
    public var selectedMentorId: UUID? = nil
    
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var isSaved: Bool = false
    
    public init() {}
    
    /// Returns active mentors filtered by the selected mentor department.
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
            return "Please enter the user's full name."
        }
        if trimmedUsername.isEmpty {
            return "Please enter a unique username."
        }
        if trimmedUsername.count < 3 {
            return "Username must be at least 3 characters."
        }
        if trimmedPassword.isEmpty {
            return "Please provide an initial password."
        }
        if trimmedPassword.count < 4 {
            return "Password must be at least 4 characters."
        }
        if trimmedDept.isEmpty {
            return "Please select a department."
        }
        return nil
    }
    
    public func createAccount(userService: UserService) -> Bool {
        if let validationError = validate() {
            self.errorMessage = validationError
            self.showError = true
            return false
        }
        
        do {
            try userService.createUser(
                name: name,
                username: username,
                password: password,
                role: role,
                department: department,
                assignedMentorId: role == .student ? selectedMentorId : nil
            )
            self.isSaved = true
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
            return false
        }
    }
}
