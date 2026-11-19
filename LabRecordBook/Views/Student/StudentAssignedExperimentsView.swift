import SwiftUI

/// Screen displaying all experiments assigned to the logged-in student by their mentor.
public struct StudentAssignedExperimentsView: View {
    public let student: User
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: StudentAssignedExperimentsViewModel?
    
    public init(student: User) {
        self.student = student
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search assigned experiments...", text: Bindable(vm).searchText)
                            .textFieldStyle(.plain)
                        if !vm.searchText.isEmpty {
                            Button(action: { vm.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Status Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(title: "All", isSelected: vm.selectedStatus == nil) {
                                vm.selectedStatus = nil
                            }
                            
                            ForEach(AssignmentStatus.allCases, id: \.self) { status in
                                filterChip(title: status.displayName, isSelected: vm.selectedStatus == status) {
                                    vm.selectedStatus = status
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    if vm.studentAssignments.isEmpty {
                        EmptyStateView(
                            iconName: "tray",
                            title: "No Mentor Assignments",
                            message: "You do not have any assignments from your mentor at this time."
                        )
                    } else if vm.filteredAssignments.isEmpty {
                        EmptyStateView(
                            iconName: "magnifyingglass",
                            title: "No Matching Assignments",
                            message: "No assigned experiments matched '\(vm.searchText)'."
                        )
                    } else {
                        List {
                            ForEach(vm.filteredAssignments, id: \.id) { assignment in
                                assignmentRow(for: assignment, vm: vm)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Assigned by Mentor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = StudentAssignedExperimentsViewModel(student: student, dataStore: dataStore)
            }
        }
    }
    
    @ViewBuilder
    private func assignmentRow(for assignment: Assignment, vm: StudentAssignedExperimentsViewModel) -> some View {
        if let exp = vm.studentExperiment(for: assignment) {
            NavigationLink(destination: ExperimentDetailView(experimentId: exp.id, currentUser: student)) {
                AssignmentCard(
                    assignment: assignment,
                    subject: vm.subject(for: assignment),
                    student: student,
                    mentor: vm.mentor(for: assignment),
                    showStudent: false
                )
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        } else {
            NavigationLink(destination: AssignmentDetailView(assignmentId: assignment.id, currentUser: student)) {
                AssignmentCard(
                    assignment: assignment,
                    subject: vm.subject(for: assignment),
                    student: student,
                    mentor: vm.mentor(for: assignment),
                    showStudent: false
                )
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
    }
    
    @ViewBuilder
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.indigo : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let store = AppDataStore()
    let student = store.users.first { $0.role == .student }!
    return NavigationStack {
        StudentAssignedExperimentsView(student: student)
            .environment(store)
    }
}
