import SwiftUI

/// Role-aware experiment list view used by Admin and Mentor to inspect authorized experiments.
public struct ExperimentListView: View {
    @Environment(AppDataStore.self) private var dataStore
    
    public let user: User
    public let title: String
    @State private var viewModel: ExperimentListViewModel
    
    public init(user: User, title: String = "Experiments") {
        self.user = user
        self.title = title
        self._viewModel = State(initialValue: ExperimentListViewModel(
            user: user,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Filters
            ExperimentFilterView(
                searchText: $viewModel.searchText,
                selectedSubjectId: $viewModel.selectedSubjectId,
                selectedStatus: $viewModel.selectedStatus,
                availableSubjects: viewModel.availableSubjects,
                selectedDepartment: $viewModel.selectedDepartment,
                availableDepartments: viewModel.availableDepartments,
                selectedStudentId: $viewModel.selectedStudentId,
                availableStudents: viewModel.availableStudents
            )
            
            // MARK: - Experiments List
            if viewModel.filteredExperiments.isEmpty {
                EmptyStateView(
                    iconName: "doc.text.magnifyingglass",
                    title: "No Experiments Found",
                    message: "No experiments match your search query or selected filters."
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredExperiments) { exp in
                            NavigationLink(destination: ExperimentDetailView(experimentId: exp.id, currentUser: user)) {
                                ExperimentCard(
                                    experiment: exp,
                                    subject: viewModel.subject(for: exp),
                                    student: viewModel.student(for: exp),
                                    showStudentInfo: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = ExperimentListViewModel(user: user, dataStore: dataStore)
        }
    }
}

#Preview {
    let store = AppDataStore()
    let admin = store.users.first { $0.role == .admin }!
    return NavigationStack {
        ExperimentListView(user: admin, title: "All Experiments")
            .environment(store)
    }
}
