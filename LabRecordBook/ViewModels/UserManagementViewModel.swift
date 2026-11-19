import Foundation
import Observation

/// ViewModel managing state, searching, filtering, and activation actions for Admin User Management.
@Observable
public final class UserManagementViewModel {
    public enum RoleFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case students = "Students"
        case mentors = "Mentors"
        
        public var id: String { rawValue }
    }
    
    public enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
        
        public var id: String { rawValue }
    }
    
    public let dataStore: AppDataStore
    public let userService: UserService
    
    public var searchText: String = ""
    public var roleFilter: RoleFilter = .all
    public var statusFilter: StatusFilter = .all
    public var selectedDepartment: String = "All"
    
    // Alerts and presentation
    public var userToConfirmDeactivate: User? = nil
    public var userToEdit: User? = nil
    public var isShowingCreateSheet: Bool = false
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var successToast: String? = nil
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
        self.userService = UserService(dataStore: dataStore)
    }
    
    public var availableDepartments: [Department] {
        dataStore.departments
    }
    
    // MARK: - Filtered Users
    
    public var filteredUsers: [User] {
        dataStore.users.filter { user in
            // Exclude Admin from standard user lists or keep them visible?
            // "Admin can view all registered students and mentors."
            // So we only display students and mentors in user management!
            guard user.role != .admin else { return false }
            
            // Department filter
            if selectedDepartment != "All" {
                if user.department.caseInsensitiveCompare(selectedDepartment) != .orderedSame {
                    return false
                }
            }
            
            // Role filter
            switch roleFilter {
            case .all:
                break
            case .students:
                if user.role != .student { return false }
            case .mentors:
                if user.role != .mentor { return false }
            }
            
            // Status filter
            switch statusFilter {
            case .all:
                break
            case .active:
                if !user.isActive { return false }
            case .inactive:
                if user.isActive { return false }
            }
            
            // Search text
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trimmedSearch.isEmpty {
                let matchesName = user.name.lowercased().contains(trimmedSearch)
                let matchesUsername = user.username.lowercased().contains(trimmedSearch)
                let matchesDept = user.department.lowercased().contains(trimmedSearch)
                return matchesName || matchesUsername || matchesDept
            }
            
            return true
        }
    }
    
    public func mentorName(for student: User) -> String? {
        guard let mentorId = student.assignedMentorId else { return nil }
        return dataStore.user(byId: mentorId)?.name
    }
    
    public func clearFilters() {
        searchText = ""
        roleFilter = .all
        statusFilter = .all
        selectedDepartment = "All"
    }
    
    // MARK: - Actions
    
    public func requestToggleActive(for user: User) {
        if user.isActive {
            // Ask for confirmation when deactivating an account
            userToConfirmDeactivate = user
        } else {
            // Immediately activate
            activateUser(user)
        }
    }
    
    public func confirmDeactivate() {
        guard let user = userToConfirmDeactivate else { return }
        do {
            try userService.setUserActiveStatus(userId: user.id, isActive: false)
            successToast = "\(user.name)'s account deactivated. Login is now disabled."
            userToConfirmDeactivate = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            userToConfirmDeactivate = nil
        }
    }
    
    private func activateUser(_ user: User) {
        do {
            try userService.setUserActiveStatus(userId: user.id, isActive: true)
            successToast = "\(user.name)'s account activated successfully."
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
