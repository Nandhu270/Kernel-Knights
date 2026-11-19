import Foundation
import Observation

/// Errors that can occur during authentication.
public enum AuthError: LocalizedError {
    case emptyFields
    case invalidCredentials
    case accountDeactivated
    
    public var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please enter both username and password."
        case .invalidCredentials:
            return "Invalid username or password. Please verify your credentials and try again."
        case .accountDeactivated:
            return "This account has been deactivated by the administrator. Access is disabled."
        }
    }
}

/// Manages authentication session and permission validation.
@Observable
public final class AuthService {
    public let dataStore: AppDataStore
    public var currentUser: User?
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    /// Authenticates a user with username and password.
    /// Validates empty fields, correct credentials, and active account status.
    @discardableResult
    public func login(username: String, password: String) throws -> User {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUser.isEmpty && !trimmedPass.isEmpty else {
            throw AuthError.emptyFields
        }
        
        guard let matchingUser = dataStore.users.first(where: {
            $0.username.caseInsensitiveCompare(trimmedUser) == .orderedSame &&
            $0.password == trimmedPass
        }) else {
            throw AuthError.invalidCredentials
        }
        
        guard matchingUser.isActive else {
            throw AuthError.accountDeactivated
        }
        
        self.currentUser = matchingUser
        return matchingUser
    }
    
    /// Logs out the currently authenticated user.
    public func logout() {
        self.currentUser = nil
    }
}
