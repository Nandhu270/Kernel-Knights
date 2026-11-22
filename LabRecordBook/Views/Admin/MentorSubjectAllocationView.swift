import SwiftUI

/// Admin interface to manage mentors assigned to teach a course subject.
public struct MentorSubjectAllocationView: View {
    @Environment(AppDataStore.self) private var dataStore
    public let subject: Subject
    @State private var viewModel: MentorSubjectAllocationViewModel
    
    public init(subject: Subject) {
        self.subject = subject
        self._viewModel = State(initialValue: MentorSubjectAllocationViewModel(
            subject: subject,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Subject Header Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(subject.code)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("\(viewModel.assignedMentors.count) Mentor\(viewModel.assignedMentors.count == 1 ? "" : "s") Assigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(subject.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(subject.department)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // MARK: - Assigned Mentors List
            if viewModel.assignedMentors.isEmpty {
                EmptyStateView(
                    iconName: "person.crop.rectangle.badge.plus",
                    title: "No Mentors Assigned",
                    message: "No faculty mentors are currently assigned to teach \(subject.code). Tap 'Assign Mentor' to add one."
                )
                Spacer()
            } else {
                List {
                    Section(header: Text("Faculty Supervising this Subject")) {
                        ForEach(viewModel.assignedMentors) { mentor in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.indigo.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.crop.rectangle.badge.plus")
                                            .font(.caption)
                                            .foregroundStyle(.indigo)
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mentor.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("@\(mentor.username) • \(mentor.department)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    
                                    let count = viewModel.allocatedStudentCount(for: mentor.id)
                                    Text("\(count) student\(count == 1 ? "" : "s") allocated")
                                        .font(.caption2)
                                        .foregroundStyle(.indigo)
                                }
                                
                                Spacer()
                                
                                Button(role: .destructive) {
                                    viewModel.removeMentor(mentor)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Subject Mentors")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Assign Mentor") {
                    viewModel.showAssignSheet = true
                }
                .font(.subheadline)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            viewModel = MentorSubjectAllocationViewModel(subject: subject, dataStore: dataStore)
        }
        .sheet(isPresented: $viewModel.showAssignSheet) {
            assignMentorSheet
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
    
    private var assignMentorSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search & Department Filter
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search faculty by name or department", text: $viewModel.searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
                
                if viewModel.filteredAvailableMentors.isEmpty {
                    EmptyStateView(
                        iconName: "person.2.slash.fill",
                        title: "No Available Mentors",
                        message: "All faculty are already assigned or no mentors match your search."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredAvailableMentors) { mentor in
                            MentorSelectionRow(
                                mentor: mentor,
                                isSelected: viewModel.selectedMentorId == mentor.id,
                                onSelect: {
                                    viewModel.selectedMentorId = mentor.id
                                }
                            )
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Assign Mentor to \(subject.code)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showAssignSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        _ = viewModel.assignSelectedMentor()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.selectedMentorId == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    let store = AppDataStore()
    let sub = store.subjects.first!
    return NavigationStack {
        MentorSubjectAllocationView(subject: sub)
            .environment(store)
    }
}
