import SwiftUI

/// View allowing a mentor to view, search, and filter all experiments they have assigned to students.
public struct AssignedExperimentsView: View {
    public let mentor: User
    public let preselectedStudentId: UUID?
    
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: AssignedExperimentsViewModel?
    
    public init(mentor: User, preselectedStudentId: UUID? = nil) {
        self.mentor = mentor
        self.preselectedStudentId = preselectedStudentId
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search assignments by title or number...", text: Bindable(vm).searchText)
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
                    
                    // Filter Chips (Department, Student & Status)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Department filter menu
                            Menu {
                                ForEach(vm.availableDepartments, id: \.self) { dept in
                                    Button(dept == "All" ? "All Departments" : dept) {
                                        vm.selectedDepartment = dept
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.2.fill")
                                    Text(vm.selectedDepartment == "All" ? "All Departments" : vm.selectedDepartment)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(vm.selectedDepartment != "All" ? Color.indigo.opacity(0.15) : Color(.secondarySystemBackground))
                                .foregroundStyle(vm.selectedDepartment != "All" ? Color.indigo : Color.primary)
                                .clipShape(Capsule())
                            }
                            
                            // Student filter menu
                            Menu {
                                Button("All Students") {
                                    vm.selectedStudentId = nil
                                }
                                Divider()
                                ForEach(vm.assignedStudents) { student in
                                    Button(student.name) {
                                        vm.selectedStudentId = student.id
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                    Text(selectedStudentName(vm: vm))
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(vm.selectedStudentId != nil ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                                .foregroundStyle(vm.selectedStudentId != nil ? Color.blue : Color.primary)
                                .clipShape(Capsule())
                            }
                            
                            // Status filter menu
                            Menu {
                                Button("All Statuses") {
                                    vm.selectedStatus = nil
                                }
                                Divider()
                                ForEach(AssignmentStatus.allCases, id: \.self) { status in
                                    Button(status.displayName) {
                                        vm.selectedStatus = status
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text(vm.selectedStatus?.displayName ?? "All Statuses")
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(vm.selectedStatus != nil ? Color.orange.opacity(0.15) : Color(.secondarySystemBackground))
                                .foregroundStyle(vm.selectedStatus != nil ? Color.orange : Color.primary)
                                .clipShape(Capsule())
                            }
                            
                            if vm.selectedDepartment != "All" || vm.selectedStudentId != nil || vm.selectedStatus != nil || !vm.searchText.isEmpty {
                                Button(action: {
                                    vm.clearFilters()
                                }) {
                                    Text("Reset")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    // Assignment List or Empty State
                    if vm.allMentorAssignments.isEmpty {
                        EmptyStateView(
                            iconName: "doc.text.magnifyingglass",
                            title: "No Assigned Experiments",
                            message: "You have not assigned any experiments to your students yet."
                        )
                    } else if vm.filteredAssignments.isEmpty {
                        EmptyStateView(
                            iconName: "line.3.horizontal.decrease.circle",
                            title: "No Matching Assignments",
                            message: "No assignments match your current search and filter criteria."
                        )
                    } else {
                        List {
                            ForEach(vm.filteredAssignments) { assignment in
                                NavigationLink(destination: AssignmentDetailView(assignmentId: assignment.id, currentUser: mentor)) {
                                    AssignmentCard(
                                        assignment: assignment,
                                        subject: vm.subject(for: assignment),
                                        student: vm.student(for: assignment),
                                        mentor: mentor,
                                        showStudent: true
                                    )
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Assigned Experiments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                let vm = AssignedExperimentsViewModel(mentor: mentor, dataStore: dataStore)
                if let preselected = preselectedStudentId {
                    vm.selectedStudentId = preselected
                }
                viewModel = vm
            }
        }
    }
    
    private func selectedStudentName(vm: AssignedExperimentsViewModel) -> String {
        guard let sid = vm.selectedStudentId, let s = vm.assignedStudents.first(where: { $0.id == sid }) else {
            return "All Students"
        }
        return s.name
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        AssignedExperimentsView(mentor: mentor)
            .environment(store)
    }
}
