import SwiftUI

/// Mentor view displaying all assigned course subjects with cohort size, progress, and quick access.
public struct MentorSubjectsView: View {
    @Environment(AppDataStore.self) private var dataStore
    public let mentor: User
    @State private var viewModel: MentorSubjectsViewModel
    
    public init(mentor: User) {
        self.mentor = mentor
        self._viewModel = State(initialValue: MentorSubjectsViewModel(
            mentor: mentor,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.subjects.isEmpty {
                    EmptyStateView(
                        iconName: "book.closed.fill",
                        title: "No Subjects Assigned",
                        message: "You have not been assigned to teach any course subjects yet. Please contact the administrator."
                    )
                } else {
                    ForEach(viewModel.subjects) { subject in
                        NavigationLink(destination: SubjectStudentsView(subject: subject, mentor: mentor)) {
                            SubjectCardView(
                                subject: subject,
                                studentCount: viewModel.studentCount(for: subject.id),
                                completionPercentage: viewModel.completionPercentage(for: subject.id),
                                verifiedCount: viewModel.verifiedCount(for: subject.id),
                                totalCount: viewModel.totalExperimentsCount(for: subject.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("My Subjects")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = MentorSubjectsViewModel(mentor: mentor, dataStore: dataStore)
        }
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        MentorSubjectsView(mentor: mentor)
            .environment(store)
    }
}
