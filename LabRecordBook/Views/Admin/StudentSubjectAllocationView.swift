import SwiftUI

/// Admin interface to allocate students to a course subject under a specific supervising mentor.
/// Supports search, department filter, allocation status filter, and non-destructive mentor reassignment.
public struct StudentSubjectAllocationView: View {
    @Environment(AppDataStore.self) private var dataStore
    public let subject: Subject
    @State private var viewModel: StudentSubjectAllocationViewModel
    
    public init(subject: Subject) {
        self.subject = subject
        self._viewModel = State(initialValue: StudentSubjectAllocationViewModel(
            subject: subject,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Card
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
                    
                    Text("\(viewModel.subjectMentors.count) Mentor\(viewModel.subjectMentors.count == 1 ? "" : "s") Teaching")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(subject.name)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 6)
            
            // Warning if no mentors assigned to this subject
            if viewModel.subjectMentors.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("No faculty mentors are assigned to this subject. Please assign at least one mentor first before allocating students.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
            
            // MARK: - Filter Picker
            Picker("Allocation Status", selection: $viewModel.filter) {
                ForEach(StudentSubjectAllocationViewModel.AllocationFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 6)
            
            // MARK: - Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search students by name or department", text: $viewModel.searchText)
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
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // MARK: - Students List
            if viewModel.filteredStudents.isEmpty {
                EmptyStateView(
                    iconName: "person.2.slash.fill",
                    title: "No Students Found",
                    message: "No students match the current filter or search criteria."
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filteredStudents) { student in
                        let mentor = viewModel.allocatedMentor(for: student)
                        
                        StudentAllocationRow(
                            student: student,
                            allocatedMentor: mentor,
                            onAssignOrChange: {
                                viewModel.selectStudentForAllocation(student)
                            },
                            onRemove: mentor == nil ? nil : {
                                viewModel.removeAllocation(for: student)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Student Allocation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = StudentSubjectAllocationViewModel(subject: subject, dataStore: dataStore)
        }
        .sheet(item: $viewModel.studentToAllocate) { student in
            allocationSelectionSheet(for: student)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
    
    private func allocationSelectionSheet(for student: User) -> some View {
        NavigationStack {
            Form {
                Section(header: Text("Student Details")) {
                    Text(student.name)
                        .font(.headline)
                    Text("@\(student.username) • \(student.department)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(
                    header: Text("Select Supervising Mentor for \(subject.code)"),
                    footer: Text("The student can have only one active supervising mentor for this subject. If reassigned, historical records will be preserved.")
                ) {
                    if viewModel.subjectMentors.isEmpty {
                        Text("No mentors are currently assigned to teach \(subject.code). Please assign mentors to this subject first.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Picker("Supervising Mentor", selection: $viewModel.selectedMentorId) {
                            ForEach(viewModel.subjectMentors) { mentor in
                                Text(mentor.name).tag(Optional(mentor.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Allocate Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.studentToAllocate = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        _ = viewModel.saveAllocation()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.selectedMentorId == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let store = AppDataStore()
    let sub = store.subjects.first!
    return NavigationStack {
        StudentSubjectAllocationView(subject: sub)
            .environment(store)
    }
}
