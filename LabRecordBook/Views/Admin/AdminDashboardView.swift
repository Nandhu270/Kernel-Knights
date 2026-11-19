import SwiftUI

/// Main dashboard for the Administrator role.
public struct AdminDashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var showingLogoutConfirmation = false
    @State private var showingCreateUserSheet = false
    @State private var showingResetConfirmation = false
    
    public init() {}
    
    private var admin: User? {
        authService.currentUser
    }
    
    private var viewModel: AdminViewModel {
        AdminViewModel(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Admin Profile Header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "person.badge.key.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(admin?.name ?? "Administrator")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 8) {
                                RoleBadge(role: .admin)
                                
                                Text(admin?.department ?? "Academic Office")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // MARK: - System Overview Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Overview")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Total Users",
                                value: "\(viewModel.totalUsersCount)",
                                iconName: "person.3.fill",
                                color: .purple
                            )
                            
                            StatCard(
                                title: "Students",
                                value: "\(viewModel.totalStudentsCount)",
                                iconName: "graduationcap.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Mentors",
                                value: "\(viewModel.totalMentorsCount)",
                                iconName: "person.crop.rectangle.badge.plus",
                                color: .indigo
                            )
                            
                            StatCard(
                                title: "Experiments",
                                value: "\(viewModel.totalExperimentsCount)",
                                iconName: "doc.text.fill",
                                color: .teal
                            )
                        }
                    }
                    
                    // MARK: - Administrative Controls (Phase 2 Features)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Administrative Controls")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            NavigationLink(destination: UserManagementView()) {
                                navCardContent(
                                    title: "User Management",
                                    subtitle: "\(viewModel.totalUsersCount - 1) students & mentors registered",
                                    icon: "person.2.badge.gearshape.fill",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: MentorAssignmentView()) {
                                navCardContent(
                                    title: "Mentor Assignments",
                                    subtitle: "Supervise student-to-mentor pairings",
                                    icon: "person.2.wave.2.fill",
                                    color: .indigo
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: DepartmentManagementView()) {
                                navCardContent(
                                    title: "Department Management",
                                    subtitle: "\(viewModel.totalDepartmentsCount) academic departments configured",
                                    icon: "building.2.crop.circle.fill",
                                    color: .cyan
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if let a = admin {
                                NavigationLink(destination: ExperimentListView(user: a, title: "All Experiments")) {
                                    navCardContent(
                                        title: "All Experiments",
                                        subtitle: "\(viewModel.totalExperimentsCount) experiments across all subjects",
                                        icon: "doc.text.magnifyingglass",
                                        color: .teal
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: StudentVerificationHistoryView(student: a)) {
                                    navCardContent(
                                        title: "Verification Audit History",
                                        subtitle: "System-wide review and approval log",
                                        icon: "clock.arrow.circlepath",
                                        color: .green
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Button(action: {
                                showingCreateUserSheet = true
                            }) {
                                navCardContent(
                                    title: "Create New User",
                                    subtitle: "Add a new student or mentor account",
                                    icon: "person.badge.plus.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                showingResetConfirmation = true
                            }) {
                                navCardContent(
                                    title: "Reset In-Memory Data",
                                    subtitle: "Restore default sample users & experiments",
                                    icon: "arrow.counterclockwise.circle.fill",
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $showingCreateUserSheet) {
                CreateUserView()
            }
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    authService.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset to Defaults", role: .destructive) {
                    dataStore.resetToSampleData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore the sample dataset. Any newly created users or changes will be discarded.")
            }
        }
    }
    
    private func navCardContent(
        title: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let store = AppDataStore()
    let authService = AuthService(dataStore: store)
    try? authService.login(username: "admin", password: "admin123")
    return AdminDashboardView()
        .environment(store)
        .environment(authService)
}
