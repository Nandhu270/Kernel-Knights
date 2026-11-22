import SwiftUI

/// Institution-wide analytics and performance tracking hub for Administrators.
public struct AdminAnalyticsView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(AuthService.self) private var authService
    @State private var viewModel: AdminAnalyticsViewModel?
    @State private var showingReportSheet: Bool = false
    @State private var selectedTab: AnalyticsTab = .overview
    
    public enum AnalyticsTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case students = "Students"
        case mentors = "Mentors"
        case subjects = "Subjects"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: 20) {
                    // System-Wide Completion Ring
                    ProgressSummaryCard(
                        title: "Institutional Completion",
                        percentage: vm.systemCompletionPercentage,
                        totalCount: vm.totalExperimentsCount,
                        verifiedCount: vm.totalVerifiedCount,
                        pendingCount: vm.totalPendingReviewCount,
                        rejectedCount: vm.totalRejectedCount,
                        tintColor: .purple
                    )
                    
                    // Quick Action: Export System Audit Report
                    if let admin = authService.currentUser {
                        Button(action: {
                            showingReportSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generate Institutional Audit PDF")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Complete system-wide metrics and workload report")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Tab Picker
                    Picker("Section", selection: $selectedTab) {
                        ForEach(AnalyticsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Tab Content
                    switch selectedTab {
                    case .overview:
                        overviewSection(vm: vm)
                    case .students:
                        studentsSection(vm: vm)
                    case .mentors:
                        mentorsSection(vm: vm)
                    case .subjects:
                        subjectsSection(vm: vm)
                    }
                }
                .padding()
            } else {
                ProgressView()
                    .padding()
            }
        }
        .navigationTitle("Institutional Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingReportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let admin = authService.currentUser {
                ReportGenerationView(reportType: .admin(admin), requestingUser: admin)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AdminAnalyticsViewModel(dataStore: dataStore)
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func overviewSection(vm: AdminAnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("System Key Metrics")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Active Students",
                    value: "\(vm.activeStudentsCount)",
                    iconName: "graduationcap.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Mentors",
                    value: "\(vm.activeMentorsCount)",
                    iconName: "person.crop.rectangle.badge.plus",
                    color: .indigo
                )
                
                StatCard(
                    title: "Total Experiments",
                    value: "\(vm.totalExperimentsCount)",
                    iconName: "doc.text.fill",
                    color: .teal
                )
                
                StatCard(
                    title: "Verified",
                    value: "\(vm.totalVerifiedCount)",
                    iconName: "checkmark.seal.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Under Review",
                    value: "\(vm.totalPendingReviewCount)",
                    iconName: "paperplane.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Needs Revision",
                    value: "\(vm.totalRejectedCount)",
                    iconName: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }
    
    @ViewBuilder
    private func studentsSection(vm: AdminAnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Student Progress Overview")
                    .font(.headline)
                Spacer()
                Text("\(vm.filteredStudentSummaries.count) students")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Search filter
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search student...", text: Bindable(vm).studentSearchText)
                    .textFieldStyle(.plain)
                if !vm.studentSearchText.isEmpty {
                    Button(action: { vm.studentSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(spacing: 10) {
                ForEach(vm.filteredStudentSummaries) { summary in
                    StudentProgressRow(summary: summary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func mentorsSection(vm: AdminAnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mentor Workload & Supervision")
                .font(.headline)
            
            VStack(spacing: 10) {
                ForEach(vm.mentorWorkloads) { mw in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mw.mentor.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(mw.mentor.department)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(mw.assignedStudentsCount) students")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.indigo.opacity(0.12))
                                .foregroundStyle(.indigo)
                                .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 12) {
                            workloadMetric(title: "Assigned Work", count: mw.assignedExperimentsCount, icon: "tray.fill", color: .blue)
                            workloadMetric(title: "Pending Review", count: mw.pendingReviewsCount, icon: "hourglass", color: .orange)
                            workloadMetric(title: "Verified", count: mw.verifiedCount, icon: "checkmark.seal", color: .green)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func workloadMetric(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text("\(count) \(title)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func subjectsSection(vm: AdminAnalyticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subject-Wise Experiment Statistics")
                .font(.headline)
            
            VStack(spacing: 10) {
                ForEach(vm.subjectStatistics) { sp in
                    SubjectProgressRow(progress: sp)
                }
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let authService = AuthService(dataStore: store)
    _ = try? authService.login(username: "admin", password: "admin123")
    return NavigationStack {
        AdminAnalyticsView()
            .environment(store)
            .environment(authService)
    }
}
