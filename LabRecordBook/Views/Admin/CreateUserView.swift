import SwiftUI

/// Modal sheet allowing Admin to create a new Student or Mentor account with department dropdown selection.
public struct CreateUserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var viewModel = CreateUserViewModel()
    @State private var showingAddDepartmentSheet = false
    @State private var newDeptName = ""
    @State private var newDeptCode = ""
    @State private var addDeptError: String? = nil
    @State private var showDeptErrorAlert = false
    
    public init() {}
    
    private var userService: UserService {
        UserService(dataStore: dataStore)
    }
    
    private var departmentService: DepartmentService {
        DepartmentService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Role Selection
                Section(header: Text("Account Role")) {
                    Picker("Role", selection: $viewModel.role) {
                        Label("Student", systemImage: "graduationcap.fill").tag(UserRole.student)
                        Label("Mentor", systemImage: "person.crop.rectangle.badge.plus").tag(UserRole.mentor)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                
                // MARK: - User Information
                Section(header: Text("Personal & Login Information")) {
                    CustomTextField(
                        title: "Full Name",
                        placeholder: "e.g., Sarah Connor",
                        iconName: "person.fill",
                        text: $viewModel.name
                    )
                    
                    CustomTextField(
                        title: "Username",
                        placeholder: "e.g., sarah.connor",
                        iconName: "at",
                        text: $viewModel.username
                    )
                    
                    CustomTextField(
                        title: "Initial Password",
                        placeholder: "Enter temporary password",
                        iconName: "lock.fill",
                        text: $viewModel.password,
                        isSecure: true
                    )
                }
                
                // MARK: - Department Selection Dropdown
                Section(
                    header: Text("Department"),
                    footer: HStack {
                        Text("Select the academic department from the registered institution list.")
                        Spacer()
                        Button("+ Add Department") {
                            newDeptName = ""
                            newDeptCode = ""
                            showingAddDepartmentSheet = true
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                ) {
                    Picker(selection: $viewModel.department) {
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
                    .onChange(of: viewModel.department) { _, newDept in
                        if viewModel.role == .student {
                            viewModel.mentorDepartment = newDept
                        }
                    }
                }
                
                // MARK: - Mentor Assignment (Student Only)
                if viewModel.role == .student {
                    Section(
                        header: Text("Mentor Assignment"),
                        footer: Text("First select the mentor's department, then choose an active mentor. Students can have at most one supervising mentor.")
                    ) {
                        // Step 1: Mentor's Department
                        Picker(selection: $viewModel.mentorDepartment) {
                            ForEach(dataStore.departments) { dept in
                                Text(dept.code.isEmpty ? dept.name : "\(dept.name) (\(dept.code))")
                                    .tag(dept.name)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "building.columns.fill")
                                    .foregroundStyle(.indigo)
                                Text("Mentor Department")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.mentorDepartment) { _, _ in
                            // Reset selected mentor if not in new department
                            let available = viewModel.availableMentors(from: dataStore)
                            if let selected = viewModel.selectedMentorId, !available.contains(where: { $0.id == selected }) {
                                viewModel.selectedMentorId = nil
                            }
                        }
                        
                        // Step 2: Mentor Selection filtered by department
                        let mentors = viewModel.availableMentors(from: dataStore)
                        Picker(selection: $viewModel.selectedMentorId) {
                            Text("None (Assign Later)").tag(UUID?.none)
                            
                            ForEach(mentors) { mentor in
                                Text(mentor.name).tag(Optional(mentor.id))
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.rectangle.badge.plus")
                                    .foregroundStyle(.purple)
                                Text("Supervising Mentor")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if mentors.isEmpty {
                            Text("No active mentors available in \(viewModel.mentorDepartment).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.role == .mentor ? "Add Mentor" : "Create Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if viewModel.createAccount(userService: userService) {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let firstDept = dataStore.departments.first, viewModel.department.isEmpty {
                    viewModel.department = firstDept.name
                    viewModel.mentorDepartment = firstDept.name
                }
            }
            .sheet(isPresented: $showingAddDepartmentSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("New Department")) {
                            CustomTextField(
                                title: "Department Name",
                                placeholder: "e.g. Aeronautical Engineering",
                                iconName: "building.2.fill",
                                text: $newDeptName
                            )
                            CustomTextField(
                                title: "Code",
                                placeholder: "e.g. AERO (Optional)",
                                iconName: "tag.fill",
                                text: $newDeptCode
                            )
                        }
                    }
                    .navigationTitle("Add Department")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddDepartmentSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                do {
                                    let dept = try departmentService.addDepartment(name: newDeptName, code: newDeptCode)
                                    viewModel.department = dept.name
                                    if viewModel.role == .student {
                                        viewModel.mentorDepartment = dept.name
                                    }
                                    showingAddDepartmentSheet = false
                                } catch {
                                    addDeptError = error.localizedDescription
                                    showDeptErrorAlert = true
                                }
                            }
                            .fontWeight(.semibold)
                            .disabled(newDeptName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .alert("Error", isPresented: $showDeptErrorAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(addDeptError ?? "Unable to create department.")
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    return CreateUserView()
        .environment(store)
}
