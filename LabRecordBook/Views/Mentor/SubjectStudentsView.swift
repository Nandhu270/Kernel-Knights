import SwiftUI

/// Mentor view showing all students allocated to this mentor within a specific subject.
/// Includes search, department filter, status filter, and 7 sorting modes.
public struct SubjectStudentsView: View {
    @Environment(AppDataStore.self) private var dataStore
    public let subject: Subject
    public let mentor: User
    @State private var viewModel: SubjectStudentsViewModel
    
    public init(subject: Subject, mentor: User) {
        self.subject = subject
        self.mentor = mentor
        self._viewModel = State(initialValue: SubjectStudentsViewModel(
            subject: subject,
            mentor: mentor,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Subject Summary Header
            VStack(alignment: .leading, spacing: 4) {
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
                    
                    Text("\(viewModel.allocatedStudents.count) Student\(viewModel.allocatedStudents.count == 1 ? "" : "s")")
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
            
            // MARK: - Search & Filters Row
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search students by name or roll number", text: $viewModel.searchText)
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
                
                HStack(spacing: 8) {
                    // Department Menu
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
                            Text(viewModel.selectedDepartment == "All" ? "Dept" : viewModel.selectedDepartment)
                                .font(.caption)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(viewModel.selectedDepartment == "All" ? Color(.secondarySystemBackground) : Color.blue.opacity(0.12))
                        .foregroundStyle(viewModel.selectedDepartment == "All" ? Color.primary : Color.blue)
                        .clipShape(Capsule())
                    }
                    
                    // Sort Menu with 7 Options
                    Menu {
                        ForEach(SubjectStudentsViewModel.SortOption.allCases) { option in
                            Button(option.rawValue) {
                                viewModel.sortOption = option
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption2)
                            Text(viewModel.sortOption.rawValue)
                                .font(.caption)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            
            // MARK: - Status Filter
            Picker("Status", selection: $viewModel.statusFilter) {
                ForEach(SubjectStudentsViewModel.StatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // MARK: - Student List
            if viewModel.filteredAndSortedStudents.isEmpty {
                EmptyStateView(
                    iconName: "person.2.slash.fill",
                    title: "No Students Found",
                    message: "No students match the current filter or search criteria."
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filteredAndSortedStudents) { student in
                        let summary = viewModel.progressSummary(for: student)
                        
                        NavigationLink(destination: StudentExperimentListView(student: student, title: "\(student.name) - \(subject.code)", initialSubjectId: subject.id)) {
                            SubjectStudentRowView(
                                student: student,
                                summary: summary,
                                mentorName: mentor.name
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(subject.code)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = SubjectStudentsViewModel(subject: subject, mentor: mentor, dataStore: dataStore)
        }
    }
}

#Preview {
    let store = AppDataStore()
    let sub = store.subjects.first!
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        SubjectStudentsView(subject: sub, mentor: mentor)
            .environment(store)
    }
}
