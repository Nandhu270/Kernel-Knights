import SwiftUI

/// Queue of submitted student experiments waiting for mentor verification.
public struct MentorReviewQueueView: View {
    public let mentor: User
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: MentorReviewQueueViewModel?
    
    public init(mentor: User) {
        self.mentor = mentor
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search submissions by student, title, or EXP#...", text: Bindable(vm).searchText)
                            .textFieldStyle(.plain)
                        if !vm.searchText.isEmpty {
                            Button(action: { vm.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Filters Row (Department, Student, Reset)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Department Filter Menu
                            Menu {
                                ForEach(vm.availableDepartments, id: \.self) { dept in
                                    Button(dept == "All" ? "All Departments" : dept) {
                                        vm.selectedDepartment = dept
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.2.fill")
                                        .font(.caption2)
                                    Text(vm.selectedDepartment == "All" ? "All Departments" : vm.selectedDepartment)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(vm.selectedDepartment == "All" ? Color(.secondarySystemBackground) : Color.indigo.opacity(0.15))
                                .foregroundStyle(vm.selectedDepartment == "All" ? Color.primary : Color.indigo)
                                .clipShape(Capsule())
                            }
                            
                            // Student Filter Menu
                            if !vm.studentsWithSubmissions.isEmpty {
                                Menu {
                                    Button("All Students") {
                                        vm.selectedStudentId = nil
                                    }
                                    Divider()
                                    ForEach(vm.studentsWithSubmissions) { student in
                                        Button(student.name) {
                                            vm.selectedStudentId = student.id
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.fill")
                                            .font(.caption2)
                                        let studentName = vm.selectedStudentId.flatMap { sid in vm.dataStore.user(byId: sid)?.name } ?? "All Students"
                                        Text(studentName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(vm.selectedStudentId == nil ? Color(.secondarySystemBackground) : Color.blue.opacity(0.15))
                                    .foregroundStyle(vm.selectedStudentId == nil ? Color.primary : Color.blue)
                                    .clipShape(Capsule())
                                }
                            }
                            
                            if vm.selectedDepartment != "All" || vm.selectedStudentId != nil || vm.selectedSubjectId != nil || !vm.searchText.isEmpty {
                                Button(action: { vm.clearFilters() }) {
                                    Text("Reset")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Subject Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: { vm.selectedSubjectId = nil }) {
                                Text("All Subjects")
                                    .font(.caption)
                                    .fontWeight(vm.selectedSubjectId == nil ? .bold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(vm.selectedSubjectId == nil ? Color.orange : Color(.secondarySystemBackground))
                                    .foregroundStyle(vm.selectedSubjectId == nil ? Color.white : Color.primary)
                                    .clipShape(Capsule())
                            }
                            
                            ForEach(vm.availableSubjects) { subj in
                                Button(action: { vm.selectedSubjectId = subj.id }) {
                                    Text(subj.code)
                                        .font(.caption)
                                        .fontWeight(vm.selectedSubjectId == subj.id ? .bold : .regular)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(vm.selectedSubjectId == subj.id ? Color.orange : Color(.secondarySystemBackground))
                                        .foregroundStyle(vm.selectedSubjectId == subj.id ? Color.white : Color.primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    
                    if vm.pendingSubmissions.isEmpty {
                        EmptyStateView(
                            iconName: "checkmark.seal.text.page",
                            title: "All Caught Up!",
                            message: "There are currently no experiment submissions waiting for your verification."
                        )
                    } else if vm.filteredSubmissions.isEmpty {
                        EmptyStateView(
                            iconName: "magnifyingglass",
                            title: "No Matching Submissions",
                            message: vm.searchText.isEmpty ? "No submissions match the selected department, student, or subject filter." : "No submitted experiments matched your search query."
                        )
                    } else {
                        List {
                            ForEach(vm.filteredSubmissions) { exp in
                                NavigationLink(destination: ExperimentReviewView(experimentId: exp.id, mentor: mentor)) {
                                    submissionRow(for: exp, vm: vm)
                                }
                                .listRowSeparator(.visible)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Review Submissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = MentorReviewQueueViewModel(mentor: mentor, dataStore: dataStore)
            }
        }
    }
    
    @ViewBuilder
    private func submissionRow(for exp: Experiment, vm: MentorReviewQueueViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exp.experimentNumber)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.tint)
                
                Spacer()
                
                StatusBadge(status: exp.status)
            }
            
            Text(exp.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                if let subj = vm.subject(for: exp) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(subj.code)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let student = vm.student(for: exp) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        Text(student.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(DateFormatter.localizedString(from: exp.lastUpdated, dateStyle: .short, timeStyle: .short))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        MentorReviewQueueView(mentor: mentor)
            .environment(store)
    }
}
