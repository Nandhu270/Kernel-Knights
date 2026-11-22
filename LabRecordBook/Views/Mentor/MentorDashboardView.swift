import SwiftUI

/// Main dashboard for the Mentor role with supervisory analytics, student progress tracking, and report generation.
public struct MentorDashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var showingLogoutConfirmation = false
    @State private var showingCreateExperimentSheet = false
    @State private var showingReportSheet = false
    
    public init() {}
    
    private var mentor: User? {
        authService.currentUser
    }
    
    private var viewModel: MentorViewModel? {
        guard let mentor = mentor else { return nil }
        return MentorViewModel(mentor: mentor, dataStore: dataStore)
    }
    
    private var analyticsService: AnalyticsService {
        AnalyticsService(dataStore: dataStore)
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
                    
                    // MARK: - Students Requiring Attention Alert (Phase 6)
                    if let m = mentor {
                        let attentionStudents = analyticsService.getStudentsRequiringAttention(for: m.id)
                        if !attentionStudents.isEmpty {
                            NavigationLink(destination: MentorProgressView(mentor: m)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.red)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(attentionStudents.count) Student(s) Require Attention")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.red)
                                        
                                        Text("Students have rejected experiments needing guidance")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // MARK: - Mentorship Metrics (Phase 4 & 6 Dynamic)
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
                                    title: "Assigned Work",
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
                        Text("Mentorship Actions & Reports")
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
                                
                                // 2. Supervisory Analytics & Progress (Phase 6)
                                NavigationLink(destination: MentorProgressView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "Supervisory Analytics & Progress",
                                        subtitle: "Track completion rates & students requiring attention",
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .indigo
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 3. Export Supervisory Report (Phase 6)
                                Button(action: {
                                    showingReportSheet = true
                                }) {
                                    mentorNavRowContent(
                                        title: "Generate Mentor Supervisory PDF",
                                        subtitle: "Export student cohort progress & audit report",
                                        icon: "doc.text.magnifyingglass",
                                        color: .purple
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 4. My Course Subjects (Phase 7)
                                NavigationLink(destination: MentorSubjectsView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "My Course Subjects",
                                        subtitle: "\(viewModel?.mySubjects.count ?? 0) subjects taught • View subject-wise student cohorts",
                                        icon: "book.closed.fill",
                                        color: .blue
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 5. My Students
                                NavigationLink(destination: MentorStudentsView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "My Students",
                                        subtitle: "\(viewModel?.assignedStudentsCount ?? 0) students under your supervision",
                                        icon: "person.2.fill",
                                        color: .indigo
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 5. Create Experiment
                                Button(action: {
                                    showingCreateExperimentSheet = true
                                }) {
                                    mentorNavRowContent(
                                        title: "Create Experiment Template",
                                        subtitle: "Draft a new lab experiment template for assignment",
                                        icon: "plus.circle.fill",
                                        color: .teal
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 6. Assigned Experiments
                                NavigationLink(destination: AssignedExperimentsView(mentor: m)) {
                                    mentorNavRowContent(
                                        title: "Assigned Experiments",
                                        subtitle: "\(viewModel?.totalAssignmentsCount ?? 0) total student assignments tracked",
                                        icon: "arrow.down.doc.fill",
                                        color: .teal
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 7. Supervised Student Experiments
                                NavigationLink(destination: ExperimentListView(user: m, title: "Supervised Experiments")) {
                                    mentorNavRowContent(
                                        title: "Supervised Experiments",
                                        subtitle: "\(viewModel?.mentorExperiments.count ?? 0) experiments from assigned students",
                                        icon: "doc.text.fill",
                                        color: .cyan
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
            .sheet(isPresented: $showingReportSheet) {
                if let m = mentor {
                    ReportGenerationView(reportType: .mentor(m), requestingUser: m)
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
