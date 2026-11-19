import Foundation
import Observation

public enum DepartmentServiceError: LocalizedError {
    case emptyName
    case alreadyExists
    case notFound
    case cannotDeleteWithAssignedUsers(count: Int)
    
    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Department name cannot be empty."
        case .alreadyExists:
            return "A department with this name or code already exists."
        case .notFound:
            return "Department could not be found."
        case .cannotDeleteWithAssignedUsers(let count):
            return "Cannot remove this department because \(count) user(s) are currently enrolled in it."
        }
    }
}

/// Service providing Department management operations for Admin and UI queries.
@Observable
public final class DepartmentService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Queries
    
    public func getAllDepartments() -> [Department] {
        dataStore.departments.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    public func getDepartment(byId id: UUID) -> Department? {
        dataStore.department(byId: id)
    }
    
    public func getDepartment(byName name: String) -> Department? {
        dataStore.department(byName: name)
    }
    
    public func mentors(inDepartment department: String) -> [User] {
        dataStore.users.filter {
            $0.role == .mentor &&
            $0.isActive &&
            $0.department.caseInsensitiveCompare(department) == .orderedSame
        }
    }
    
    public func students(inDepartment department: String) -> [User] {
        dataStore.users.filter {
            $0.role == .student &&
            $0.department.caseInsensitiveCompare(department) == .orderedSame
        }
    }
    
    public func totalUsers(inDepartment department: String) -> Int {
        dataStore.users.filter {
            $0.department.caseInsensitiveCompare(department) == .orderedSame
        }.count
    }
    
    // MARK: - Admin Mutations
    
    /// Adds a new academic department with name and unique code validation.
    @discardableResult
    public func addDepartment(name: String, code: String = "") throws -> Department {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !trimmedName.isEmpty else {
            throw DepartmentServiceError.emptyName
        }
        
        // Check for duplicate name
        let nameExists = dataStore.departments.contains {
            $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
        if nameExists {
            throw DepartmentServiceError.alreadyExists
        }
        
        // If code is supplied, check duplicate code
        if !trimmedCode.isEmpty {
            let codeExists = dataStore.departments.contains {
                $0.code.caseInsensitiveCompare(trimmedCode) == .orderedSame
            }
            if codeExists {
                throw DepartmentServiceError.alreadyExists
            }
        }
        
        let newDept = Department(name: trimmedName, code: trimmedCode)
        dataStore.departments.append(newDept)
        return newDept
    }
    
    /// Removes a department from the system.
    public func deleteDepartment(id: UUID) throws {
        guard let index = dataStore.departments.firstIndex(where: { $0.id == id }) else {
            throw DepartmentServiceError.notFound
        }
        
        let dept = dataStore.departments[index]
        let enrolledUsers = totalUsers(inDepartment: dept.name)
        if enrolledUsers > 0 {
            throw DepartmentServiceError.cannotDeleteWithAssignedUsers(count: enrolledUsers)
        }
        
        dataStore.departments.remove(at: index)
    }
}
