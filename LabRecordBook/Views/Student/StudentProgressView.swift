import SwiftUI

/// Detailed analytics and progress tracking view for Students.
public struct StudentProgressView: View {
    public let student: User
    
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: StudentAnalyticsViewModel?
    @State private var showingReportSheet: Bool = false
    
    public init(student: User) {
        self.student = student
    }
    
    public var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: 20) {
                    // Overall Progress Ring Card
                    ProgressSummaryCard(
                        title: "Overall Lab Progress",
                        percentage: vm.completionPercentage,
                        totalCount: vm.totalAssignedCount,
                        verifiedCount: vm.verifiedCount,
                        pendingCount: vm.inProgressCount + vm.submittedCount,
                        rejectedCount: vm.rejectedCount,
                        tintColor: .blue
                    )
                    
                    // Quick Action: Export Lab Record PDF
                    Button(action: {
                        showingReportSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Generate Lab Record PDF")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Export academic record with mentor verification")
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
                    
                    // Detailed Status Grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Experiment Lifecycle Counts")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Total Assigned",
                                value: "\(vm.totalAssignedCount)",
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
                                title: "Submitted",
                                value: "\(vm.submittedCount)",
                                iconName: "paperplane.fill",
                                color: .purple
                            )
                            
                            StatCard(
                                title: "Verified",
                                value: "\(vm.verifiedCount)",
                                iconName: "checkmark.seal.fill",
                                color: .green
                            )
                        }
                    }
                    
                    // Subject-Wise Progress Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject-Wise Progress")
                            .font(.headline)
                        
                        if vm.subjectProgress.isEmpty {
                            EmptyStateView(
                                iconName: "book.closed",
                                title: "No Experiments Yet",
                                message: "When you create or receive assigned experiments, subject progress will be charted here."
                            )
                        } else {
                            VStack(spacing: 10) {
                                ForEach(vm.subjectProgress) { sp in
                                    SubjectProgressRow(progress: sp)
                                }
                            }
                        }
                    }
                }
                .padding()
            } else {
                ProgressView()
                    .padding()
            }
        }
        .navigationTitle("My Lab Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingReportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportGenerationView(reportType: .student(student), requestingUser: student)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StudentAnalyticsViewModel(student: student, dataStore: dataStore)
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let student = store.users.first { $0.role == .student }!
    return NavigationStack {
        StudentProgressView(student: student)
            .environment(store)
    }
}
