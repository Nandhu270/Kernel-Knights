import SwiftUI

/// Form view allowing Admin to edit a user's information, password, department, mentor, and active status.
public struct EditUserView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var viewModel: EditUserViewModel
    @State private var showingDeactivateConfirmation = false
    
    public init(user: User) {
        self._viewModel = State(initialValue: EditUserViewModel(user: user))
    }
    
    private var userService: UserService {
        UserService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Role & Account Summary
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(viewModel.originalUser.role.badgeColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: viewModel.originalUser.role.iconName)
                                    .font(.title3)
                                    .foregroundStyle(viewModel.originalUser.role.badgeColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.name.isEmpty ? viewModel.originalUser.name : viewModel.name)
                                .font(.headline)
                            
                            HStack(spacing: 6) {
                                RoleBadge(role: viewModel.originalUser.role)
                                
                                Text(viewModel.isActive ? "Active" : "Deactivated")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(viewModel.isActive ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Personal Information
                Section(header: Text("User Details")) {
                    CustomTextField(
                        title: "Full Name",
                        placeholder: "Full Name",
                        iconName: "person.fill",
                        text: $viewModel.name
                    )
                    
                    CustomTextField(
                        title: "Username",
                        placeholder: "Username",
                        iconName: "at",
                        text: $viewModel.username
                    )
                    
                    CustomTextField(
                        title: "Password",
                        placeholder: "Password",
                        iconName: "lock.fill",
                        text: $viewModel.password,
                        isSecure: true
                    )
                    
                    // Department Dropdown
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
                }
                
                // MARK: - Account Activation Status
                Section(
                    header: Text("Account Access"),
                    footer: Text(viewModel.isActive ? "Account is active. User can log in." : "Account is deactivated. User will be blocked from logging in.")
                ) {
                    Toggle("Account Active", isOn: Binding(
                        get: { viewModel.isActive },
                        set: { newValue in
                            if !newValue && viewModel.originalUser.isActive {
                                // Request confirmation before deactivating
                                showingDeactivateConfirmation = true
                            } else {
                                viewModel.isActive = newValue
                            }
                        }
                    ))
                    .tint(.green)
                }
                
                // MARK: - Mentor Assignment (Student Only)
                if viewModel.originalUser.role == .student {
                    Section(
                        header: Text("Assigned Mentor"),
                        footer: Text("First choose the mentor's department, then select the supervising mentor.")
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
                        
                        // Step 2: Mentor selection filtered by department
                        let mentors = viewModel.availableMentors(from: dataStore)
                        Picker(selection: $viewModel.selectedMentorId) {
                            Text("None (Unassigned)").tag(UUID?.none)
                            
                            ForEach(mentors) { mentor in
                                Text(mentor.name).tag(Optional(mentor.id))
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.rectangle.badge.plus")
                                    .foregroundStyle(.purple)
                                Text("Mentor")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if mentors.isEmpty {
                            Text("No active mentors found in \(viewModel.mentorDepartment).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveChanges(userService: userService) {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // If student has an assigned mentor, pre-select that mentor's department
                if let mentorId = viewModel.selectedMentorId,
                   let mentor = dataStore.user(byId: mentorId) {
                    viewModel.mentorDepartment = mentor.department
                } else if viewModel.mentorDepartment.isEmpty {
                    viewModel.mentorDepartment = viewModel.department
                }
            }
            .confirmationDialog(
                "Deactivate Account?",
                isPresented: $showingDeactivateConfirmation,
                titleVisibility: .visible
            ) {
                Button("Deactivate", role: .destructive) {
                    viewModel.isActive = false
                }
                Button("Cancel", role: .cancel) {
                    viewModel.isActive = true
                }
            } message: {
                Text("Deactivating will immediately prevent \(viewModel.originalUser.name) from logging into the system.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred while saving changes.")
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    return EditUserView(user: SampleData.users[1])
        .environment(store)
}
