import SwiftUI

/// Admin interface to view, search, filter, create, edit, activate/deactivate, and allocate subjects.
public struct SubjectManagementView: View {
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: SubjectManagementViewModel
    
    public init() {
        self._viewModel = State(initialValue: SubjectManagementViewModel(dataStore: AppDataStore(populateSampleData: false)))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Filters
            VStack(spacing: 8) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search by code, title, or department", text: $viewModel.searchText)
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
                
                // Department & Active Filter Row
                HStack(spacing: 8) {
                    Menu {
                        ForEach(viewModel.availableDepartments, id: \.self) { dept in
                            Button(dept) {
                                viewModel.selectedDepartment = dept
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
                    
                    Toggle(isOn: $viewModel.showActiveOnly) {
                        Text("Active Only")
                            .font(.caption)
                    }
                    .toggleStyle(.button)
                    .tint(.blue)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)
            
            // MARK: - Subjects List
            if viewModel.filteredSubjects.isEmpty {
                EmptyStateView(
                    iconName: "book.closed.fill",
                    title: "No Course Subjects Found",
                    message: "No subjects match the selected filters."
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filteredSubjects) { subject in
                        VStack(alignment: .leading, spacing: 10) {
                            SubjectCardView(
                                subject: subject,
                                studentCount: viewModel.studentCount(for: subject.id),
                                mentorCount: viewModel.mentorCount(for: subject.id)
                            )
                            
                            // Allocation Shortcut Buttons
                            HStack(spacing: 8) {
                                NavigationLink(destination: MentorSubjectAllocationView(subject: subject)) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.crop.rectangle.badge.plus")
                                        Text("Mentors (\(viewModel.mentorCount(for: subject.id)))")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.indigo.opacity(0.12))
                                    .foregroundStyle(.indigo)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: StudentSubjectAllocationView(subject: subject)) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "graduationcap.fill")
                                        Text("Students (\(viewModel.studentCount(for: subject.id)))")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.subjectToEdit = subject
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 4)
                        }
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.toggleActive(for: subject)
                            } label: {
                                Label(subject.isActive ? "Deactivate" : "Activate", systemImage: subject.isActive ? "pause.circle.fill" : "play.circle.fill")
                            }
                            .tint(subject.isActive ? .orange : .green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.subjectToDelete = subject
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Subject Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.showCreateSheet = true
                }) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            viewModel = SubjectManagementViewModel(dataStore: dataStore)
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateSubjectView()
        }
        .sheet(item: $viewModel.subjectToEdit) { subject in
            EditSubjectView(subject: subject)
        }
        .confirmationDialog(
            "Delete Subject?",
            isPresented: Binding(
                get: { viewModel.subjectToDelete != nil },
                set: { if !$0 { viewModel.subjectToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let sub = viewModel.subjectToDelete {
                Button("Delete Subject", role: .destructive) {
                    viewModel.deleteSubject(sub)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let sub = viewModel.subjectToDelete {
                Text("Are you sure you want to delete '\(sub.name)' (\(sub.code))? If experiments exist, you should deactivate it instead.")
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
        SubjectManagementView()
            .environment(store)
    }
}
