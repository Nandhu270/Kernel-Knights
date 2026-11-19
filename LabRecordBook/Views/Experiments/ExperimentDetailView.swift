import SwiftUI

/// Detailed view showing experiment content, aim, procedure, results, verification history,
/// with student submission and mentor review actions.
public struct ExperimentDetailView: View {
    public let experimentId: UUID
    public let currentUser: User
    
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExperimentDetailViewModel
    
    public init(experimentId: UUID, currentUser: User) {
        self.experimentId = experimentId
        self.currentUser = currentUser
        self._viewModel = State(initialValue: ExperimentDetailViewModel(
            experimentId: experimentId,
            currentUser: currentUser,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    private var formattedDate: String {
        guard let exp = viewModel.experiment else { return "" }
        return DateFormatter.localizedString(from: exp.date, dateStyle: .medium, timeStyle: .none)
    }
    
    public var body: some View {
        ScrollView {
            if let experiment = viewModel.experiment {
                VStack(spacing: 20) {
                    // MARK: - Toast Banner
                    if let toast = viewModel.submitSuccessToast {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(toast)
                                .font(.caption)
                            Spacer()
                            Button(action: { viewModel.submitSuccessToast = nil }) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // MARK: - Header Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(experiment.experimentNumber)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            StatusBadge(status: experiment.status)
                        }
                        
                        Text(experiment.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        if let subject = viewModel.subject {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(.secondary)
                                Text("\(subject.code): \(subject.name)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // MARK: - Verification Feedback Banner (Phase 5)
                    ExperimentFeedbackView(
                        experiment: experiment,
                        verifications: viewModel.verifications,
                        onEditTapped: {
                            viewModel.isShowingEditSheet = true
                        },
                        onSubmitTapped: {
                            viewModel.showSubmitConfirmation = true
                        }
                    )
                    
                    // MARK: - Metadata Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(
                            icon: "calendar",
                            title: "Experiment Date",
                            value: formattedDate,
                            color: .blue
                        )
                        
                        if let student = viewModel.student {
                            detailRow(
                                icon: "graduationcap.fill",
                                title: "Student Author",
                                value: "\(student.name) (\(student.department))",
                                color: .purple
                            )
                        }
                        
                        if let mentor = viewModel.mentor {
                            detailRow(
                                icon: "person.crop.rectangle.badge.plus",
                                title: "Supervising Mentor",
                                value: mentor.name,
                                color: .indigo
                            )
                        }
                        
                        if experiment.isAssignedByMentor {
                            detailRow(
                                icon: "arrow.down.doc.fill",
                                title: "Origin",
                                value: "Assigned by Mentor",
                                color: .teal
                            )
                        }
                        
                        if let assignment = viewModel.assignment {
                            detailRow(
                                icon: "clock.badge.checkmark",
                                title: "Assignment Due Date",
                                value: DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .medium, timeStyle: .none),
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // MARK: - Aim
                    contentCard(
                        title: "Aim",
                        icon: "target",
                        content: experiment.aim,
                        accentColor: .blue
                    )
                    
                    // MARK: - Algorithm / Procedure
                    contentCard(
                        title: "Algorithm & Procedure",
                        icon: "list.number",
                        content: experiment.procedure,
                        accentColor: .indigo
                    )
                    
                    // MARK: - Result
                    contentCard(
                        title: "Result & Observations",
                        icon: "chart.bar.doc.horizontal.fill",
                        content: experiment.result.isEmpty ? "No results recorded yet." : experiment.result,
                        accentColor: .teal
                    )
                    
                    // MARK: - Phase 5 Primary Actions
                    // 1. Student Submission Button
                    if viewModel.canSubmit {
                        Button(action: {
                            viewModel.showSubmitConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Label(
                                    experiment.status == .rejected ? "Resubmit for Mentor Verification" : "Submit for Mentor Verification",
                                    systemImage: "paperplane.fill"
                                )
                                .font(.headline)
                                .fontWeight(.bold)
                                Spacer()
                            }
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 4)
                    }
                    
                    // 2. Mentor Review Button
                    if viewModel.canMentorReview {
                        NavigationLink(destination: ExperimentReviewView(experimentId: experiment.id, mentor: currentUser)) {
                            HStack {
                                Spacer()
                                Label("Review & Verify Submission", systemImage: "checkmark.seal.fill")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            } else {
                EmptyStateView(
                    iconName: "exclamationmark.triangle",
                    title: "Experiment Not Found",
                    message: "This experiment record may have been deleted."
                )
            }
        }
        .navigationTitle(viewModel.experiment?.experimentNumber ?? "Experiment Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    if viewModel.canEdit && viewModel.experiment != nil {
                        Button(action: {
                            viewModel.isShowingEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                        }
                    }
                    
                    if viewModel.canDelete {
                        Button(role: .destructive, action: {
                            viewModel.isShowingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel = ExperimentDetailViewModel(
                experimentId: experimentId,
                currentUser: currentUser,
                dataStore: dataStore
            )
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            if let exp = viewModel.experiment {
                EditExperimentView(experiment: exp, student: currentUser)
            }
        }
        .confirmationDialog(
            "Delete Experiment?",
            isPresented: $viewModel.isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Experiment", role: .destructive) {
                if viewModel.deleteExperiment() {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let exp = viewModel.experiment {
                Text("Are you sure you want to delete '\(exp.title)' (\(exp.experimentNumber))? This action cannot be undone.")
            }
        }
        .confirmationDialog(
            "Submit for Verification?",
            isPresented: $viewModel.showSubmitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Submit to Mentor") {
                _ = viewModel.submitExperiment()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let exp = viewModel.experiment {
                Text("Are you ready to submit '\(exp.title)' for mentor verification? Once submitted, editing will be locked until review.")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
    
    @ViewBuilder
    private func detailRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    @ViewBuilder
    private func contentCard(title: String, icon: String, content: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.headline)
            }
            
            Text(content.isEmpty ? "None provided." : content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let store = AppDataStore()
    let exp = store.experiments.first!
    let student = store.user(byId: exp.studentId ?? UUID())!
    return NavigationStack {
        ExperimentDetailView(experimentId: exp.id, currentUser: student)
            .environment(store)
    }
}
