import SwiftUI

/// Main dashboard for the Mentor role.
public struct MentorDashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var showingLogoutConfirmation = false
    @State private var showingCreateExperimentSheet = false
    
    public init() {}
    
    private var mentor: User? {
        authService.currentUser
    }
    
    private var viewModel: MentorViewModel? {
        guard let mentor = mentor else { return nil }
        return MentorViewModel(mentor: mentor, dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Mentor Profile Header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "person.crop.rectangle.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mentor?.name ?? "Mentor")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 8) {
                                RoleBadge(role: .mentor)
                                
                                Text(mentor?.department ?? "Computer Science")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // MARK: - Mentorship Metrics (Phase 4 Dynamic)
                    if let vm = viewModel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mentorship Overview")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(
                                    title: "Assigned Students",
                                    value: "\(vm.assignedStudentsCount)",
                                    iconName: "person.2.fill",
                                    color: .indigo
                                )
                                
                                StatCard(
                                    title: "Assigned Experiments",
                                    value: "\(vm.totalAssignmentsCount)",
                                    iconName: "tray.full.fill",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "Pending Review",
                                    value: "\(vm.pendingReviewsCount)",
                                    iconName: "hourglass.badge.eye",
                                    color: .orange
                                )
                                
                                StatCard(
                                    title: "Verified",
                                    value: "\(vm.verifiedCount)",
                                    iconName: "checkmark.seal.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Needs Revision",
                                    value: "\(vm.rejectedCount)",
                                    iconName: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                                
                                StatCard(
                                    title: "Created Templates",
                                    value: "\(vm.totalMentorCreatedExperimentsCount)",
                                    iconName: "lightbulb.fill",
                                    color: .teal
                                )
                            }
                        }
                    }
                    
                    // MARK: - Mentorship Navigation Actions
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Mentorship Actions")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            if let m = mentor {
                                // 1. Review Submissions
                                NavigationLink(destination: MentorReviewQueueView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "Review Submissions",
                                        subtitle: "\(viewModel?.pendingReviewsCount ?? 0) submissions waiting for verification",
                                        icon: "checkmark.seal.text.page.fill",
                                        color: .orange,
                                        badgeCount: viewModel?.pendingReviewsCount
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 2. My Students
                                NavigationLink(destination: MentorStudentsView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "My Students",
                                        subtitle: "\(viewModel?.assignedStudentsCount ?? 0) students under your supervision",
                                        icon: "person.2.fill",
                                        color: .indigo
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 2. Create Experiment
                                Button(action: {
                                    showingCreateExperimentSheet = true
                                }) {
                                    mentorNavRowContent(
                                        title: "Create Experiment",
                                        subtitle: "Draft a new lab experiment template for assignment",
                                        icon: "plus.circle.fill",
                                        color: .teal
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 3. Assigned Experiments
                                NavigationLink(destination: AssignedExperimentsView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "Assigned Experiments",
                                        subtitle: "\(viewModel?.totalAssignmentsCount ?? 0) total student assignments tracked",
                                        icon: "arrow.down.doc.fill",
                                        color: .blue
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 4. Assignment History
                                NavigationLink(destination: AssignedExperimentsView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "Assignment History",
                                        subtitle: "Audit log of all assignments and completion dates",
                                        icon: "clock.arrow.circlepath",
                                        color: .purple
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 5. Supervised Student Experiments
                                NavigationLink(destination: ExperimentListView(user: m, title: "Supervised Experiments")) {
                                    mentorNavRowContent(
                                        title: "Supervised Experiments",
                                        subtitle: "\(viewModel?.mentorExperiments.count ?? 0) experiments from assigned students",
                                        icon: "doc.text.magnifyingglass",
                                        color: .orange
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Mentor Dashboard")
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
            .sheet(isPresented: $showingCreateExperimentSheet) {
                if let m = mentor {
                    CreateMentorExperimentView(mentor: m)
                }
            }
        }
    }
    
    @ViewBuilder
    private func mentorNavRowContent(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        badgeCount: Int? = nil
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
            
            if let count = badgeCount, count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color)
                    .clipShape(Capsule())
            }
            
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
    try? authService.login(username: "dr.smith", password: "mentor123")
    return MentorDashboardView()
        .environment(store)
        .environment(authService)
}
