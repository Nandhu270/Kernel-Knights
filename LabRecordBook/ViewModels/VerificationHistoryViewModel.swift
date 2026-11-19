import Foundation
import Observation

/// ViewModel for viewing historical audit verification and review records with search, status, and department filtering.
@Observable
public final class VerificationHistoryViewModel {
    public enum VerificationStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case verified = "Verified"
        case rejected = "Rejected"
        
        public var id: String { rawValue }
    }
    
    public let experimentId: UUID?
    public let currentUser: User
    public let dataStore: AppDataStore
    public let verificationService: VerificationService
    
    public var searchText: String = ""
    public var statusFilter: VerificationStatusFilter = .all
    public var selectedDepartment: String = "All"
    
    public init(experimentId: UUID? = nil, currentUser: User, dataStore: AppDataStore) {
        self.experimentId = experimentId
        self.currentUser = currentUser
        self.dataStore = dataStore
        self.verificationService = VerificationService(dataStore: dataStore)
    }
    
    public var verifications: [Verification] {
        if let expId = experimentId {
            return verificationService.getVerificationHistory(forExperimentId: expId, requestingUser: currentUser)
        } else {
            return verificationService.getAllVerifications(requestingUser: currentUser)
        }
    }
    
    public var availableDepartments: [String] {
        let depts = Set(verifications.compactMap { record -> String? in
            guard let std = student(for: record) else { return nil }
            return std.department
        })
        return ["All"] + Array(depts).sorted()
    }
    
    /// Filtered audit verification records matching search, status, and department
    public var filteredVerifications: [Verification] {
        verifications.filter { record in
            // Status filter
            switch statusFilter {
            case .all:
                break
            case .verified:
                if record.status != .verified { return false }
            case .rejected:
                if record.status != .rejected { return false }
            }
            
            // Department filter
            if selectedDepartment != "All" {
                guard let std = student(for: record),
                      std.department.caseInsensitiveCompare(selectedDepartment) == .orderedSame else {
                    return false
                }
            }
            
            // Search text
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                let exp = experiment(for: record)
                let numMatch = exp?.experimentNumber.lowercased().contains(query) ?? false
                let titleMatch = exp?.title.lowercased().contains(query) ?? false
                let mentorMatch = record.mentorName.lowercased().contains(query)
                let commentMatch = record.comments.lowercased().contains(query)
                let studentMatch = student(for: record)?.name.lowercased().contains(query) ?? false
                
                return numMatch || titleMatch || mentorMatch || commentMatch || studentMatch
            }
            
            return true
        }
    }
    
    public func experiment(for record: Verification) -> Experiment? {
        dataStore.experiment(byId: record.experimentId)
    }
    
    public func student(for record: Verification) -> User? {
        guard let exp = experiment(for: record), let sid = exp.studentId else { return nil }
        return dataStore.user(byId: sid)
    }
    
    public func clearFilters() {
        searchText = ""
        statusFilter = .all
        selectedDepartment = "All"
    }
}
