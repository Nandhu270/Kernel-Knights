import SwiftUI

/// Main dashboard for the Student role with progress tracking and academic analytics.
public struct StudentDashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var showingLogoutConfirmation = false
    @State private var showingCreateExperimentSheet = false
    @State private var showingReportSheet = false
    
    public init() {}
    
    private var student: User? {
        authService.currentUser
    }
    
    private var viewModel: StudentViewModel? {
        guard let student = student else { return nil }
        return StudentViewModel(student: student, dataStore: dataStore)
    }
    
    private var analyticsService: AnalyticsService {
        AnalyticsService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Student Profile Header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "graduationcap.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(student?.name ?? "Student")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 8) {
                                RoleBadge(role: .student)
                                
                                Text(student?.department ?? "Computer Science")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let mentor = viewModel?.assignedMentor {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.rectangle.badge.plus")
                                        .font(.caption2)
                                    Text("Mentor: \(mentor.name)")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.indigo)
                                .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // MARK: - Progress Tracking & Completion Percentage (Phase 6)
                    if let s = student {
                        let completionPct = analyticsService.getStudentCompletionPercentage(for: s.id)
                        let exps = analyticsService.getStudentExperiments(for: s.id)
                        let verified = exps.filter { $0.status == .verified }.count
                        let pending = exps.filter { $0.status != .verified && $0.status != .rejected }.count
                        let rejected = exps.filter { $0.status == .rejected }.count
                        
                        ProgressSummaryCard(
                            title: "My Lab Completion",
                            percentage: completionPct,
                            totalCount: exps.count,
                            verifiedCount: verified,
                            pendingCount: pending,
                            rejectedCount: rejected,
                            tintColor: .blue
                        )
                    }
                    
                    // MARK: - Subject-Wise Progress Summary (Phase 6)
                    if let s = student {
                        let subjectProgressList = analyticsService.getSubjectProgress(for: s.id)
                        if !subjectProgressList.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Subject-Wise Progress")
                                        .font(.headline)
                                    Spacer()
                                    NavigationLink(destination: StudentProgressView(student: s)) {
                                        Text("See Details")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.tint)
                                    }
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(subjectProgressList.prefix(2)) { sp in
                                        SubjectProgressRow(progress: sp)
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Progress Metrics Grid
                    if let vm = viewModel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Experiment Lifecycle")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(
                                    title: "Assigned Work",
                                    value: "\(vm.assignedCount)",
                                    iconName: "arrow.down.doc.fill",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "In Progress",
                                    value: "\(vm.inProgressCount)",
                                    iconName: "hourglass.circle.fill",
                                    color: .indigo
                                )
                                
                                StatCard(
                                    title: "Under Review",
                                    value: "\(vm.submittedCount)",
                                    iconName: "paperplane.fill",
                                    color: .purple
                                )
                                
                                StatCard(
                                    title: "Needs Revision",
                                    value: "\(vm.rejectedCount)",
                                    iconName: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                                
                                StatCard(
                                    title: "Verified",
                                    value: "\(vm.verifiedCount)",
                                    iconName: "checkmark.seal.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Total Records",
                                    value: "\(vm.totalExperimentsCount)",
                                    iconName: "doc.plaintext.fill",
                                    color: .teal
                                )
                            }
                        }
                    }
                    
                    // MARK: - Lab Sections & Reports
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Lab Sections & Reports")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            if let s = student {
                                // 1. My Experiments
                                NavigationLink(destination: StudentExperimentListView(student: s)) {
                                    navRowContent(
                                        title: "My Experiments",
                                        subtitle: "View, create, edit, search and filter your lab work",
                                        icon: "doc.text.fill",
                                        color: .blue
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 2. My Lab Analytics (Phase 6)
                                NavigationLink(destination: StudentProgressView(student: s)) {
                                    navRowContent(
                                        title: "My Lab Analytics",
                                        subtitle: "Detailed subject completion breakdown & charts",
                                        icon: "chart.pie.fill",
                                        color: .indigo
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 3. Export Lab Record PDF (Phase 6)
                                Button(action: {
                                    showingReportSheet = true
                                }) {
                                    navRowContent(
                                        title: "Export Lab Record PDF",
                                        subtitle: "Compile academic record book with verification sign-off",
                                        icon: "doc.text.magnifyingglass",
                                        color: .purple
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 4. Create New Experiment
                                Button(action: {
                                    showingCreateExperimentSheet = true
                                }) {
                                    navRowContent(
                                        title: "Create New Experiment",
                                        subtitle: "Draft a new lab record entry",
                                        icon: "plus.circle.fill",
                                        color: .teal
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 5. Assigned by Mentor
                                NavigationLink(destination: StudentAssignedExperimentsView(student: s)) {
                                    navRowContent(
                                        title: "Assigned by Mentor",
                                        subtitle: "\(viewModel?.assignedFromMentorCount ?? 0) assignments received",
                                        icon: "arrow.down.doc.fill",
                                        color: .blue
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // 6. Verification History
                                NavigationLink(destination: StudentVerificationHistoryView(student: s)) {
                                    navRowContent(
                                        title: "Verification History",
                                        subtitle: "Review feedback and audit trail from your mentor",
                                        icon: "clock.arrow.circlepath",
                                        color: .green
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Student Dashboard")
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
            .sheet(isPresented: $showingCreateExperimentSheet) {
                if let s = student {
                    CreateExperimentView(student: s)
                }
            }
            .sheet(isPresented: $showingReportSheet) {
                if let s = student {
                    ReportGenerationView(reportType: .student(s), requestingUser: s)
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
        }
    }
    
    private func navRowContent(
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
    try? authService.login(username: "john.doe", password: "student123")
    return StudentDashboardView()
        .environment(store)
        .environment(authService)
}
