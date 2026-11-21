import SwiftUI

/// Detailed analytics and supervised students progress tracking view for Mentors.
public struct MentorProgressView: View {
    public let mentor: User
    
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: MentorAnalyticsViewModel?
    @State private var showingReportSheet: Bool = false
    
    public init(mentor: User) {
        self.mentor = mentor
    }
    
    public var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: 20) {
                    // Supervisory Summary Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Supervisory Overview")
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
                                value: "\(vm.totalAssignedExperimentsCount)",
                                iconName: "tray.full.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Pending Reviews",
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
                        }
                    }
                    
                    // Quick Action: Export Supervisory Report
                    Button(action: {
                        showingReportSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.title3)
                                .foregroundStyle(.indigo)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Generate Mentor Supervisory Report")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Export student roster progress & workload audit")
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
                    
                    // Attention Required Section
                    if !vm.studentsRequiringAttention.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("Students Requiring Attention (\(vm.studentsRequiringAttention.count))")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }
                            
                            Text("The following students have experiments that were rejected and require guidance or resubmission.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 8) {
                                ForEach(vm.studentsRequiringAttention) { student in
                                    NavigationLink(destination: AssignedExperimentsView(mentor: mentor, preselectedStudentId: student.id)) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color.red.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .font(.caption)
                                                        .foregroundStyle(.red)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(student.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.primary)
                                                Text(student.department)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("Review")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.red)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(12)
                                        .background(Color.red.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Supervised Students Progress List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Supervised Students Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(vm.filteredStudentSummaries.count) students")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Search bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Filter students by name...", text: Bindable(vm).searchText)
                                .textFieldStyle(.plain)
                            if !vm.searchText.isEmpty {
                                Button(action: { vm.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        if vm.filteredStudentSummaries.isEmpty {
                            EmptyStateView(
                                iconName: "person.slash",
                                title: "No Students Found",
                                message: "No students match your filter."
                            )
                        } else {
                            VStack(spacing: 10) {
                                ForEach(vm.filteredStudentSummaries) { summary in
                                    NavigationLink(destination: AssignedExperimentsView(mentor: mentor, preselectedStudentId: summary.student.id)) {
                                        StudentProgressRow(summary: summary)
                                    }
                                    .buttonStyle(.plain)
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
        .navigationTitle("Supervisory Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingReportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportGenerationView(reportType: .mentor(mentor), requestingUser: mentor)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MentorAnalyticsViewModel(mentor: mentor, dataStore: dataStore)
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        MentorProgressView(mentor: mentor)
            .environment(store)
    }
}
