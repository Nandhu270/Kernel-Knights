import SwiftUI

/// Main User Management interface for Administrator:
/// View all registered students and mentors, search/filter, edit details, and toggle active status.
public struct UserManagementView: View {
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: UserManagementViewModel
    
    public init() {
        self._viewModel = State(initialValue: UserManagementViewModel(dataStore: AppDataStore(populateSampleData: false)))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Filter Controls
            VStack(spacing: 10) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search by name, username, or department", text: $viewModel.searchText)
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
                
                // Role Filter (All / Students / Mentors)
                Picker("Role Filter", selection: $viewModel.roleFilter) {
                    ForEach(UserManagementViewModel.RoleFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                
                // Department & Status Filter Row
                HStack(spacing: 8) {
                    // Department Dropdown Filter
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
                    
                    // Status Filter (All / Active / Inactive)
                    Picker("Status", selection: $viewModel.statusFilter) {
                        ForEach(UserManagementViewModel.StatusFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    
                    if viewModel.selectedDepartment != "All" || viewModel.roleFilter != .all || viewModel.statusFilter != .all || !viewModel.searchText.isEmpty {
                        Button("Reset") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            // MARK: - Success Toast
            if let toast = viewModel.successToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(toast)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: { viewModel.successToast = nil }) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
            
            // MARK: - User List
            if viewModel.filteredUsers.isEmpty {
                EmptyStateView(
                    iconName: "person.2.slash.fill",
                    title: "No Users Found",
                    message: "No registered students or mentors match your search query or filters.",
                    actionTitle: "Add New User"
                ) {
                    viewModel.isShowingCreateSheet = true
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filteredUsers) { user in
                        Button(action: {
                            viewModel.userToEdit = user
                        }) {
                            UserRowView(
                                user: user,
                                mentorName: viewModel.mentorName(for: user),
                                onToggleActive: {
                                    viewModel.requestToggleActive(for: user)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.isShowingCreateSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            viewModel = UserManagementViewModel(dataStore: dataStore)
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            CreateUserView()
        }
        .sheet(item: $viewModel.userToEdit) { user in
            EditUserView(user: user)
        }
        .confirmationDialog(
            "Deactivate Account?",
            isPresented: Binding(
                get: { viewModel.userToConfirmDeactivate != nil },
                set: { if !$0 { viewModel.userToConfirmDeactivate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Deactivate Account", role: .destructive) {
                viewModel.confirmDeactivate()
            }
            Button("Cancel", role: .cancel) {
                viewModel.userToConfirmDeactivate = nil
            }
        } message: {
            if let user = viewModel.userToConfirmDeactivate {
                Text("Are you sure you want to deactivate \(user.name)'s account? The user will immediately be blocked from logging in on this device.")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
}

#Preview {
    let store = AppDataStore()
    return NavigationStack {
        UserManagementView()
            .environment(store)
    }
}
