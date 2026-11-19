import SwiftUI

/// Main dashboard for the Student role.
public struct StudentDashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var showingLogoutConfirmation = false
    @State private var showingCreateExperimentSheet = false
    
    public init() {}
    
    private var student: User? {
        authService.currentUser
    }
    
    private var viewModel: StudentViewModel? {
        guard let student = student else { return nil }
        return StudentViewModel(student: student, dataStore: dataStore)
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
                    
                    // MARK: - Progress Metrics
                    if let vm = viewModel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Lab Progress")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(
                                    title: "Assigned",
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
                    
                    // MARK: - Lab Sections (Phase 3 Connected)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Lab Sections")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            if let s = student {
                                NavigationLink(destination: StudentExperimentListView(student: s)) {
                                    navRowContent(
                                        title: "My Experiments",
                                        subtitle: "View, create, edit, search and filter your lab work",
                                        icon: "doc.text.fill",
                                        color: .blue
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
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
                            
                            if let s = student {
                                NavigationLink(destination: StudentAssignedExperimentsView(student: s)) {
                                    navRowContent(
                                        title: "Assigned by Mentor",
                                        subtitle: "\(viewModel?.assignedFromMentorCount ?? 0) assignments received",
                                        icon: "arrow.down.doc.fill",
                                        color: .indigo
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: StudentVerificationHistoryView(student: s)) {
                                    navRowContent(
                                        title: "Verification History",
                                        subtitle: "Review feedback and audit trail from your mentor",
                                        icon: "clock.arrow.circlepath",
                                        color: .purple
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
