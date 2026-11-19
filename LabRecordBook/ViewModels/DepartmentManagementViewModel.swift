import Foundation
import Observation

/// ViewModel for managing academic departments in the Administrator portal.
@Observable
public final class DepartmentManagementViewModel {
    public let dataStore: AppDataStore
    public let departmentService: DepartmentService
    
    public var searchText: String = ""
    public var showingAddSheet: Bool = false
    
    // Add department form state
    public var newDepartmentName: String = ""
    public var newDepartmentCode: String = ""
    
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var successToast: String? = nil
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
        self.departmentService = DepartmentService(dataStore: dataStore)
    }
    
    public var filteredDepartments: [Department] {
        let all = departmentService.getAllDepartments()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return all
        }
        return all.filter {
            $0.name.lowercased().contains(query) ||
            $0.code.lowercased().contains(query)
        }
    }
    
    public func studentCount(for department: Department) -> Int {
        departmentService.students(inDepartment: department.name).count
    }
    
    public func mentorCount(for department: Department) -> Int {
        departmentService.mentors(inDepartment: department.name).count
    }
    
    public func addDepartment() -> Bool {
        let trimmedName = newDepartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = newDepartmentCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter the department name."
            showError = true
            return false
        }
        
        do {
            let dept = try departmentService.addDepartment(name: trimmedName, code: trimmedCode)
            successToast = "Added department: \(dept.name)"
            newDepartmentName = ""
            newDepartmentCode = ""
            showingAddSheet = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
    
    public func deleteDepartment(_ department: Department) {
        do {
            try departmentService.deleteDepartment(id: department.id)
            successToast = "Department '\(department.name)' removed."
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
