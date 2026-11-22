import SwiftUI

/// Main experiment list view for students:
/// Allows searching, subject/status filtering, distinguishing mentor-assigned vs self-created experiments,
/// viewing details, creating, and deleting experiments.
public struct StudentExperimentListView: View {
    @Environment(AppDataStore.self) private var dataStore
    
    public enum OriginFilter: String, CaseIterable {
        case all = "All Experiments"
        case assigned = "Assigned by Mentor"
        case selfCreated = "Self-Created"
    }
    
    public let student: User
    public let customTitle: String?
    public let initialSubjectId: UUID?
    @State private var viewModel: ExperimentListViewModel
    @State private var isShowingCreateSheet = false
    @State private var originFilter: OriginFilter = .all
    
    public init(student: User, title: String? = nil, initialSubjectId: UUID? = nil) {
        self.student = student
        self.customTitle = title
        self.initialSubjectId = initialSubjectId
        var vm = ExperimentListViewModel(
            user: student,
            dataStore: AppDataStore(populateSampleData: false)
        )
        if let subId = initialSubjectId {
            vm.selectedSubjectId = subId
        }
        self._viewModel = State(initialValue: vm)
    }
    
    private var displayedExperiments: [Experiment] {
        viewModel.filteredExperiments.filter { exp in
            switch originFilter {
            case .all:
                return true
            case .assigned:
                return exp.isAssignedByMentor
            case .selfCreated:
                return !exp.isAssignedByMentor
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Search & Filters
            ExperimentFilterView(
                searchText: $viewModel.searchText,
                selectedSubjectId: $viewModel.selectedSubjectId,
                selectedStatus: $viewModel.selectedStatus,
                availableSubjects: viewModel.availableSubjects
            )
            
            // MARK: - Origin Segmentation (Assigned vs Self-Created)
            Picker("Filter by Origin", selection: $originFilter) {
                ForEach(OriginFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 6)
            
            // MARK: - Toast Banner
            if let toast = viewModel.successToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(toast)
                        .font(.caption)
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
            
            // MARK: - Experiments List
            if displayedExperiments.isEmpty {
                EmptyStateView(
                    iconName: "doc.text.magnifyingglass",
                    title: "No Experiments Found",
                    message: "No experiments match your search query or selected filters.",
                    actionTitle: "Create New Experiment"
                ) {
                    isShowingCreateSheet = true
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedExperiments) { exp in
                            NavigationLink(destination: ExperimentDetailView(experimentId: exp.id, currentUser: student)) {
                                ExperimentCard(
                                    experiment: exp,
                                    subject: viewModel.subject(for: exp),
                                    student: student,
                                    showStudentInfo: false
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if viewModel.canDelete(experiment: exp) {
                                    Button(role: .destructive) {
                                        viewModel.experimentToDelete = exp
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(customTitle ?? "My Experiments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isShowingCreateSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            viewModel = ExperimentListViewModel(user: student, dataStore: dataStore)
            if let subId = initialSubjectId {
                viewModel.selectedSubjectId = subId
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            CreateExperimentView(student: student)
        }
        .confirmationDialog(
            "Delete Experiment?",
            isPresented: Binding(
                get: { viewModel.experimentToDelete != nil },
                set: { if !$0 { viewModel.experimentToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Experiment", role: .destructive) {
                viewModel.deleteExperiment()
            }
            Button("Cancel", role: .cancel) {
                viewModel.experimentToDelete = nil
            }
        } message: {
            if let exp = viewModel.experimentToDelete {
                Text("Are you sure you want to delete '\(exp.title)' (\(exp.experimentNumber))? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let student = store.users.first { $0.role == .student }!
    return NavigationStack {
        StudentExperimentListView(student: student)
            .environment(store)
    }
}
