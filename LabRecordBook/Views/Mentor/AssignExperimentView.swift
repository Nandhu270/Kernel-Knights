import SwiftUI

/// View allowing a mentor to assign an experiment to one or multiple supervised students.
public struct AssignExperimentView: View {
    public let experiment: Experiment
    public let mentor: User
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: AssignExperimentViewModel?
    
    public init(experiment: Experiment, mentor: User) {
        self.experiment = experiment
        self.mentor = mentor
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel {
                Form {
                    // Experiment Summary Header
                    Section(header: Text("Experiment to Assign")) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(experiment.experimentNumber)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.tint)
                                Spacer()
                                if let subject = dataStore.subject(byId: experiment.subjectId) {
                                    Text("\(subject.code) - \(subject.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text(experiment.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    // Assignment Settings (Due Date)
                    Section(header: Text("Assignment Settings")) {
                        DatePicker(
                            "Submission Due Date",
                            selection: Bindable(vm).dueDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                    
                    // Selected Students summary chip row (removable)
                    if !vm.selectedStudents.isEmpty {
                        Section(header: Text("Selected Students (\(vm.selectedStudents.count))")) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(vm.selectedStudents) { student in
                                        HStack(spacing: 4) {
                                            Text(student.name)
                                                .font(.subheadline)
                                            Button(action: {
                                                vm.removeStudent(id: student.id)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // Student Selection Section
                    Section(
                        header: HStack {
                            Text("Select Recipients")
                            Spacer()
                            Button("Select Filtered") {
                                vm.selectAllFiltered()
                            }
                            .font(.caption)
                            .textCase(nil)
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Button("Clear") {
                                vm.clearSelection()
                            }
                            .font(.caption)
                            .textCase(nil)
                        }
                    ) {
                        // Department Filter Dropdown
                        Picker(selection: Bindable(vm).selectedDepartment) {
                            ForEach(vm.availableDepartments, id: \.self) { dept in
                                Text(dept == "All" ? "All Departments" : dept)
                                    .tag(dept)
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
                        
                        // Search textfield
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search students by name...", text: Bindable(vm).searchText)
                                .textFieldStyle(.plain)
                            if !vm.searchText.isEmpty {
                                Button(action: { vm.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                        
                        if vm.availableStudents.isEmpty {
                            Text("No students are currently assigned to your mentorship.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else if vm.filteredStudents.isEmpty {
                            Text("No students match the current filter or search criteria.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach(vm.filteredStudents) { student in
                                StudentSelectionRow(
                                    student: student,
                                    isSelected: vm.selectedStudentIds.contains(student.id),
                                    isAlreadyAssigned: vm.isAlreadyAssigned(studentId: student.id),
                                    onToggle: {
                                        vm.toggleSelection(for: student.id)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Assign Button
                    Section {
                        Button(action: {
                            _ = vm.requestAssignmentConfirmation()
                        }) {
                            HStack {
                                Spacer()
                                Label(
                                    "Assign to \(vm.selectedStudentIds.count) Student\(vm.selectedStudentIds.count == 1 ? "" : "s")",
                                    systemImage: "paperplane.fill"
                                )
                                .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(!vm.canAssign)
                    }
                }
                .confirmationDialog(
                    "Confirm Experiment Assignment",
                    isPresented: Bindable(vm).showConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Assign Experiment to \(vm.selectedStudentIds.count) Students") {
                        _ = vm.executeAssignment()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to assign '\(experiment.title)' to \(vm.selectedStudentIds.count) selected student(s)? Each student will receive an independent experiment record.")
                }
                .alert("Assignment Successful", isPresented: Bindable(vm).showSuccess) {
                    Button("Done") {
                        dismiss()
                    }
                } message: {
                    Text(vm.successMessage ?? "Experiment assigned successfully.")
                }
                .alert("Assignment Error", isPresented: Bindable(vm).showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(vm.errorMessage ?? "An error occurred.")
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Assign Experiment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AssignExperimentViewModel(experiment: experiment, mentor: mentor, dataStore: dataStore)
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    let exp = store.experiments.first!
    return NavigationStack {
        AssignExperimentView(experiment: exp, mentor: mentor)
            .environment(store)
    }
}
