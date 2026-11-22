import SwiftUI

/// Student view showing all enrolled subjects with supervising mentor details, completion percentage, and experiment navigation.
public struct StudentSubjectsView: View {
    @Environment(AppDataStore.self) private var dataStore
    public let student: User
    @State private var viewModel: StudentSubjectsViewModel
    
    public init(student: User) {
        self.student = student
        self._viewModel = State(initialValue: StudentSubjectsViewModel(
            student: student,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.enrolledSubjects.isEmpty {
                    EmptyStateView(
                        iconName: "book.closed.fill",
                        title: "No Enrolled Subjects",
                        message: "You are not currently enrolled in any course subjects. Please contact your administrator for course allocation."
                    )
                } else {
                    ForEach(viewModel.enrolledSubjects) { subject in
                        let progress = viewModel.progress(for: subject)
                        let mentor = viewModel.supervisingMentor(for: subject.id)
                        
                        NavigationLink(destination: StudentExperimentListView(student: student, title: "\(subject.code) Experiments", initialSubjectId: subject.id)) {
                            VStack(alignment: .leading, spacing: 10) {
                                SubjectCardView(
                                    subject: subject,
                                    completionPercentage: progress.completionPercentage,
                                    verifiedCount: progress.verifiedExperiments,
                                    totalCount: progress.totalExperiments
                                )
                                
                                if let m = mentor {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.crop.rectangle.badge.plus")
                                            .font(.caption)
                                            .foregroundStyle(.indigo)
                                        Text("Supervising Mentor: \(m.name)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.indigo)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
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
            viewModel = StudentSubjectsViewModel(student: student, dataStore: dataStore)
        }
    }
}

#Preview {
    let store = AppDataStore()
    let student = store.users.first { $0.role == .student }!
    return NavigationStack {
        StudentSubjectsView(student: student)
            .environment(store)
    }
}
