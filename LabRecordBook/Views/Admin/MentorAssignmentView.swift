import SwiftUI

/// Dedicated interface allowing Admin to manage and assign supervising mentors to students.
public struct MentorAssignmentView: View {
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: MentorAssignmentViewModel
    
    public init() {
        // Will initialize in onAppear / body with dataStore
        self._viewModel = State(initialValue: MentorAssignmentViewModel(dataStore: AppDataStore(populateSampleData: false)))
    }
    
    private var actualViewModel: MentorAssignmentViewModel {
        viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Summary Metric Cards
            HStack(spacing: 12) {
                let totalStudents = dataStore.users.filter { $0.role == .student }.count
                let assignedCount = dataStore.users.filter { $0.role == .student && $0.assignedMentorId != nil }.count
                let unassignedCount = totalStudents - assignedCount
                
                StatCard(
                    title: "Total Students",
                    value: "\(totalStudents)",
                    iconName: "graduationcap.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Assigned",
                    value: "\(assignedCount)",
                    iconName: "person.crop.rectangle.badge.plus",
                    color: .green
                )
                
                StatCard(
                    title: "Unassigned",
                    value: "\(unassignedCount)",
                    iconName: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // MARK: - Filter Picker
            Picker("Filter", selection: $viewModel.filter) {
                ForEach(MentorAssignmentViewModel.AssignmentFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 6)
            
            // MARK: - Department Filter Row
            HStack(spacing: 8) {
                Menu {
                    Button("All Departments") {
                        viewModel.selectedDepartment = "All"
                    }
                    Divider()
                    ForEach(dataStore.departments) { dept in
                        Button(dept.code.isEmpty ? dept.name : "\(dept.name) (\(dept.code))") {
                            viewModel.selectedDepartment = dept.name
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.caption2)
                        Text(viewModel.selectedDepartment == "All" ? "All Departments" : viewModel.selectedDepartment)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewModel.selectedDepartment == "All" ? Color(.secondarySystemBackground) : Color.blue.opacity(0.12))
                    .foregroundStyle(viewModel.selectedDepartment == "All" ? Color.primary : Color.blue)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                if viewModel.selectedDepartment != "All" || viewModel.filter != .all || !viewModel.searchText.isEmpty {
                    Button("Reset") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            
            // MARK: - Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search students by name or username", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // MARK: - Student List
            if viewModel.students.isEmpty {
                EmptyStateView(
                    iconName: "person.2.slash.fill",
                    title: "No Students Found",
                    message: "No students match the current filter or search criteria."
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.students) { student in
                        let mentor = viewModel.mentor(for: student)
                        
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Image(systemName: "graduationcap.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                )
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(student.name)
                                    .font(.headline)
                                
                                Text("@\(student.username) • \(student.department)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if let mentor = mentor {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.crop.rectangle.badge.plus")
                                            .font(.caption2)
                                        Text("Mentor: \(mentor.name)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.12))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                                    .padding(.top, 2)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption2)
                                        Text("No Mentor Assigned")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                                    .padding(.top, 2)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.selectStudentForAssignment(student)
                            }) {
                                Text(mentor == nil ? "Assign" : "Change")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(mentor == nil ? Color.blue : Color(.tertiarySystemFill))
                                    .foregroundStyle(mentor == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Mentor Assignments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = MentorAssignmentViewModel(dataStore: dataStore)
        }
        .sheet(item: $viewModel.studentToAssign) { student in
            assignmentSelectionSheet(for: student)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
    
    private func assignmentSelectionSheet(for student: User) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Student Details")) {
                    Text(student.name)
                        .font(.headline)
                    Text("@\(student.username) • \(student.department)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // STEP 1: Mentor's Department
                Section(
                    header: Text("Step 1 — Choose Mentor Department"),
                    footer: Text("Filter mentors by department before selecting a supervisor.")
                ) {
                    Picker(selection: Binding(
                        get: { viewModel.selectedMentorDepartment },
                        set: { viewModel.onDepartmentChanged(to: $0) }
                    )) {
                        ForEach(dataStore.departments) { dept in
                            Text(dept.code.isEmpty ? dept.name : "\(dept.name) (\(dept.code))")
                                .tag(dept.name)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.blue)
                            Text("Department")
                                .foregroundStyle(.primary)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // STEP 2: Mentor Selection in Department
                Section(
                    header: Text("Step 2 — Select Mentor in \(viewModel.selectedMentorDepartment)"),
                    footer: Text("Assigning a mentor establishes a 1:1 supervision relationship. Any previously assigned mentor will be updated automatically.")
                ) {
                    let mentors = viewModel.filteredMentors
                    Picker(selection: $viewModel.selectedMentorId) {
                        Text("None (Unassigned)").tag(UUID?.none)
                        
                        ForEach(mentors) { mentor in
                            Text(mentor.name)
                                .tag(Optional(mentor.id))
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.rectangle.badge.plus")
                                .foregroundStyle(.indigo)
                            Text("Supervising Mentor")
                                .foregroundStyle(.primary)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if mentors.isEmpty {
                        Text("No active mentors available in \(viewModel.selectedMentorDepartment). Please select another department above.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Assign Mentor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.studentToAssign = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.saveAssignment()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    let store = AppDataStore()
    return NavigationStack {
        MentorAssignmentView()
            .environment(store)
    }
}
