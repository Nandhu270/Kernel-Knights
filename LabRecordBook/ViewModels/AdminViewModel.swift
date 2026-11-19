import Foundation
import Observation

/// ViewModel managing state and metrics for the Admin Dashboard and User Management.
@Observable
public final class AdminViewModel {
    public let dataStore: AppDataStore
    public let userService: UserService
    public let experimentService: ExperimentService
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
        self.userService = UserService(dataStore: dataStore)
        self.experimentService = ExperimentService(dataStore: dataStore)
    }
    
    // MARK: - Dashboard Metrics
    
    public var totalUsersCount: Int {
        dataStore.users.count
    }
    
    public var totalDepartmentsCount: Int {
        dataStore.departments.count
    }
    
    public var totalStudentsCount: Int {
        dataStore.users.filter { $0.role == .student }.count
    }
    
    public var totalMentorsCount: Int {
        dataStore.users.filter { $0.role == .mentor }.count
    }
    
    public var activeAccountsCount: Int {
        dataStore.users.filter { $0.isActive }.count
    }
    
    public var totalExperimentsCount: Int {
        dataStore.experiments.count
    }
    
    public var verifiedExperimentsCount: Int {
        dataStore.experiments.filter { $0.status == .verified }.count
    }
    
    public var pendingReviewsCount: Int {
        dataStore.experiments.filter { $0.status == .submitted }.count
    }
}
