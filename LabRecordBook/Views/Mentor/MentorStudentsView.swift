import SwiftUI

/// Screen displaying students assigned to the current mentor with progress and assigned work.
public struct MentorStudentsView: View {
    public let mentor: User
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: MentorStudentsViewModel?
    
    public init(mentor: User) {
        self.mentor = mentor
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search students by name, username or department...", text: Bindable(vm).searchText)
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
                    .padding(.bottom, 6)
                    
                    // Filter Chips (Department & Status)
                    HStack(spacing: 8) {
                        // Department Filter Menu
                        Menu {
                            ForEach(vm.availableDepartments, id: \.self) { dept in
                                Button(dept == "All" ? "All Departments" : dept) {
                                    vm.selectedDepartment = dept
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.caption2)
                                Text(vm.selectedDepartment == "All" ? "All Departments" : vm.selectedDepartment)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(vm.selectedDepartment == "All" ? Color(.secondarySystemBackground) : Color.indigo.opacity(0.15))
                            .foregroundStyle(vm.selectedDepartment == "All" ? Color.primary : Color.indigo)
                            .clipShape(Capsule())
                        }
                        
                        // Status Filter Menu
                        Menu {
                            ForEach(MentorStudentsViewModel.StudentStatusFilter.allCases) { filter in
                                Button(filter.rawValue) {
                                    vm.statusFilter = filter
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.caption2)
                                Text(vm.statusFilter.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(vm.statusFilter == .all ? Color(.secondarySystemBackground) : Color.blue.opacity(0.15))
                            .foregroundStyle(vm.statusFilter == .all ? Color.primary : Color.blue)
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        if vm.selectedDepartment != "All" || vm.statusFilter != .all || !vm.searchText.isEmpty {
                            Button("Reset") {
                                vm.clearFilters()
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    if vm.assignedStudents.isEmpty {
                        EmptyStateView(
                            iconName: "person.2.slash",
                            title: "No Students Assigned",
                            message: "You currently do not have any students assigned to your mentorship."
                        )
                    } else if vm.filteredStudents.isEmpty {
                        EmptyStateView(
                            iconName: "magnifyingglass",
                            title: "No Matching Students",
                            message: vm.searchText.isEmpty ? "No students match the selected department or status filter." : "No students found matching '\(vm.searchText)'."
                        )
                    } else {
                        List {
                            ForEach(vm.filteredStudents) { student in
                                NavigationLink(destination: studentDetailDestination(for: student)) {
                                    studentRow(student: student, vm: vm)
                                }
                                .listRowSeparator(.visible)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("My Students")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = MentorStudentsViewModel(mentor: mentor, dataStore: dataStore)
            }
        }
    }
    
    @ViewBuilder
    private func studentRow(student: User, vm: MentorStudentsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "graduationcap.fill")
                            .font(.subheadline)
                            .foregroundStyle(.indigo)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 6) {
                        Text("@\(student.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(student.department)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(vm.assignmentsCount(for: student))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.indigo)
                    Text("Assigned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Completion Progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(vm.progressText(for: student))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.indigo)
                }
                
                ProgressView(value: vm.progress(for: student))
                    .tint(.indigo)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func studentDetailDestination(for student: User) -> some View {
        AssignedExperimentsView(mentor: mentor, preselectedStudentId: student.id)
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        MentorStudentsView(mentor: mentor)
            .environment(store)
    }
}
