import SwiftUI

/// Reusable filter header bar providing live search, department dropdown, subject dropdown, student dropdown, and status dropdown.
public struct ExperimentFilterView: View {
    @Binding public var searchText: String
    @Binding public var selectedSubjectId: UUID?
    @Binding public var selectedStatus: ExperimentStatus?
    @Binding public var selectedDepartment: String
    @Binding public var selectedStudentId: UUID?
    
    public let availableSubjects: [Subject]
    public let availableDepartments: [Department]
    public let availableStudents: [User]
    
    public init(
        searchText: Binding<String>,
        selectedSubjectId: Binding<UUID?>,
        selectedStatus: Binding<ExperimentStatus?>,
        availableSubjects: [Subject],
        selectedDepartment: Binding<String> = .constant("All"),
        availableDepartments: [Department] = [],
        selectedStudentId: Binding<UUID?> = .constant(nil),
        availableStudents: [User] = []
    ) {
        self._searchText = searchText
        self._selectedSubjectId = selectedSubjectId
        self._selectedStatus = selectedStatus
        self.availableSubjects = availableSubjects
        self._selectedDepartment = selectedDepartment
        self.availableDepartments = availableDepartments
        self._selectedStudentId = selectedStudentId
        self.availableStudents = availableStudents
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search by title, number, or student", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Filter Selectors (Department, Subject, Status, Student)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Department Filter Menu (if available)
                    if !availableDepartments.isEmpty {
                        Menu {
                            Button("All Departments") {
                                selectedDepartment = "All"
                            }
                            Divider()
                            ForEach(availableDepartments) { dept in
                                Button(dept.code.isEmpty ? dept.name : "\(dept.name) (\(dept.code))") {
                                    selectedDepartment = dept.name
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.caption2)
                                Text(selectedDepartment == "All" ? "All Departments" : selectedDepartment)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(selectedDepartment == "All" ? Color(.secondarySystemBackground) : Color.indigo.opacity(0.15))
                            .foregroundStyle(selectedDepartment == "All" ? Color.primary : Color.indigo)
                            .clipShape(Capsule())
                        }
                    }
                    
                    // Subject Filter Menu
                    Menu {
                        Button("All Subjects") {
                            selectedSubjectId = nil
                        }
                        Divider()
                        ForEach(availableSubjects) { subject in
                            Button("\(subject.code): \(subject.name)") {
                                selectedSubjectId = subject.id
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed.fill")
                                .font(.caption2)
                            Text(selectedSubjectTitle)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(selectedSubjectId == nil ? Color(.secondarySystemBackground) : Color.blue.opacity(0.12))
                        .foregroundStyle(selectedSubjectId == nil ? Color.primary : Color.blue)
                        .clipShape(Capsule())
                    }
                    
                    // Status Filter Menu
                    Menu {
                        Button("All Statuses") {
                            selectedStatus = nil
                        }
                        Divider()
                        ForEach(ExperimentStatus.allCases) { status in
                            Button(status.displayName) {
                                selectedStatus = status
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.caption2)
                            Text(selectedStatus?.displayName ?? "All Statuses")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(selectedStatus == nil ? Color(.secondarySystemBackground) : selectedStatus!.badgeColor.opacity(0.15))
                        .foregroundStyle(selectedStatus == nil ? Color.primary : selectedStatus!.badgeColor)
                        .clipShape(Capsule())
                    }
                    
                    // Student Filter Menu (if available)
                    if !availableStudents.isEmpty {
                        Menu {
                            Button("All Students") {
                                selectedStudentId = nil
                            }
                            Divider()
                            ForEach(availableStudents) { student in
                                Button(student.name) {
                                    selectedStudentId = student.id
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                let currentName = selectedStudentId.flatMap { sid in availableStudents.first { $0.id == sid }?.name } ?? "All Students"
                                Text(currentName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(selectedStudentId == nil ? Color(.secondarySystemBackground) : Color.purple.opacity(0.15))
                            .foregroundStyle(selectedStudentId == nil ? Color.primary : Color.purple)
                            .clipShape(Capsule())
                        }
                    }
                    
                    // Reset Filters Button
                    if selectedSubjectId != nil || selectedStatus != nil || selectedDepartment != "All" || selectedStudentId != nil || !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            selectedSubjectId = nil
                            selectedStatus = nil
                            selectedDepartment = "All"
                            selectedStudentId = nil
                        }) {
                            Text("Reset")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    private var selectedSubjectTitle: String {
        guard let id = selectedSubjectId,
              let subject = availableSubjects.first(where: { $0.id == id }) else {
            return "All Subjects"
        }
        return subject.code
    }
}

#Preview {
    struct Wrapper: View {
        @State private var query = ""
        @State private var subId: UUID? = nil
        @State private var status: ExperimentStatus? = nil
        let subjects = SampleData.subjects
        
        var body: some View {
            ExperimentFilterView(
                searchText: $query,
                selectedSubjectId: $subId,
                selectedStatus: $status,
                availableSubjects: subjects
            )
        }
    }
    return Wrapper()
}
