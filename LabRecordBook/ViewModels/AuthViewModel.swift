import Foundation
import Observation

/// ViewModel managing state, validation, and actions for user login.
@Observable
public final class AuthViewModel {
    public var username: String = ""
    public var password: String = ""
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var isLoading: Bool = false
    
    public init() {}
    
    /// Pre-fills demo credentials for rapid testing of each role during demonstration.
    public func fillDemoCredentials(username: String, password: String) {
        self.username = username
        self.password = password
        self.errorMessage = nil
        self.showError = false
    }
    
    /// Executes login through AuthService.
    public func login(authService: AuthService) -> Bool {
        errorMessage = nil
        showError = false
        
        do {
            try authService.login(username: username, password: password)
            return true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            showError = true
            return false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
    
    public func clearForm() {
        username = ""
        password = ""
        errorMessage = nil
        showError = false
    }
}
