import SwiftUI

/// Interface allowing Administrator to view, search, and add academic departments.
public struct DepartmentManagementView: View {
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: DepartmentManagementViewModel
    @State private var departmentToDelete: Department? = nil
    @State private var showingDeleteAlert: Bool = false
    
    public init() {
        self._viewModel = State(initialValue: DepartmentManagementViewModel(dataStore: AppDataStore(populateSampleData: false)))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search departments by name or code", text: $viewModel.searchText)
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
            .padding(.vertical, 8)
            
            // Department List
            if viewModel.filteredDepartments.isEmpty {
                EmptyStateView(
                    iconName: "building.2.crop.circle",
                    title: "No Departments Found",
                    message: viewModel.searchText.isEmpty ? "No academic departments configured. Add one below." : "No departments match '\(viewModel.searchText)'."
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filteredDepartments) { dept in
                        departmentRow(dept)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    departmentToDelete = dept
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Departments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.newDepartmentName = ""
                    viewModel.newDepartmentCode = ""
                    viewModel.showingAddSheet = true
                }) {
                    Label("Add Department", systemImage: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            addDepartmentSheet
        }
        .alert("Delete Department", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let dept = departmentToDelete {
                    viewModel.deleteDepartment(dept)
                }
                departmentToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                departmentToDelete = nil
            }
        } message: {
            if let dept = departmentToDelete {
                Text("Are you sure you want to delete '\(dept.name)'?")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
        .onAppear {
            viewModel = DepartmentManagementViewModel(dataStore: dataStore)
        }
    }
    
    private func departmentRow(_ dept: Department) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.teal.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(.teal)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(dept.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !dept.code.isEmpty {
                        Text(dept.code)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.teal.opacity(0.12))
                            .foregroundStyle(.teal)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    let sCount = viewModel.studentCount(for: dept)
                    let mCount = viewModel.mentorCount(for: dept)
                    
                    Label("\(sCount) Students", systemImage: "graduationcap.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label("\(mCount) Mentors", systemImage: "person.crop.rectangle.badge.plus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var addDepartmentSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Department Details"), footer: Text("Enter the official academic department name and optional short code (e.g. CSE, IT, EEE).")) {
                    CustomTextField(
                        title: "Department Name",
                        placeholder: "e.g. Artificial Intelligence & Data Science",
                        iconName: "building.2.fill",
                        text: $viewModel.newDepartmentName
                    )
                    
                    CustomTextField(
                        title: "Department Code",
                        placeholder: "e.g. AI&DS (Optional)",
                        iconName: "tag.fill",
                        text: $viewModel.newDepartmentCode
                    )
                }
            }
            .navigationTitle("Add Department")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingAddSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = viewModel.addDepartment()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.newDepartmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    return NavigationStack {
        DepartmentManagementView()
            .environment(store)
    }
}
