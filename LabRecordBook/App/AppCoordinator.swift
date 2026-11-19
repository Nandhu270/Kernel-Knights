// xcode: set sdk=iOS

import SwiftUI

/// Root coordinator managing top-level application navigation and role routing.
/// Switches dynamically based on current authentication state and active user role.
public struct AppCoordinator: View {
    @Environment(AuthService.self) private var authService
    
    public init() {}
    
    public var body: some View {
        Group {
            if let user = authService.currentUser {
                switch user.role {
                case .admin:
                    AdminDashboardView()
                case .student:
                    StudentDashboardView()
                case .mentor:
                    MentorDashboardView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.currentUser?.id)
    }
}

#Preview("Coordinator - Login") {
    let store = AppDataStore()
    let auth = AuthService(dataStore: store)
    return AppCoordinator()
        .environment(store)
        .environment(auth)
}

#Preview("Coordinator - Admin Dashboard") {
    let store = AppDataStore()
    let auth = AuthService(dataStore: store)
    try? auth.login(username: "admin", password: "admin123")
    return AppCoordinator()
        .environment(store)
        .environment(auth)
}

#Preview("Coordinator - Student Dashboard") {
    let store = AppDataStore()
    let auth = AuthService(dataStore: store)
    try? auth.login(username: "john.doe", password: "student123")
    return AppCoordinator()
        .environment(store)
        .environment(auth)
}

#Preview("Coordinator - Mentor Dashboard") {
    let store = AppDataStore()
    let auth = AuthService(dataStore: store)
    try? auth.login(username: "dr.smith", password: "mentor123")
    return AppCoordinator()
        .environment(store)
        .environment(auth)
}
