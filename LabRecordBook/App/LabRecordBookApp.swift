import SwiftUI

@main
struct LabRecordBookApp: App {
    @State private var dataStore: AppDataStore
    @State private var authService: AuthService
    
    init() {
        let store = AppDataStore()
        self._dataStore = State(initialValue: store)
        self._authService = State(initialValue: AuthService(dataStore: store))
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environment(dataStore)
                .environment(authService)
        }
    }
}
