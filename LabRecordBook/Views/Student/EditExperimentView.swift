import SwiftUI

/// Form sheet allowing a student to edit an existing eligible experiment.
public struct EditExperimentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var dataStore
    
    public let experiment: Experiment
    public let student: User
    @State private var viewModel: EditExperimentViewModel
    
    public init(experiment: Experiment, student: User) {
        self.experiment = experiment
        self.student = student
        self._viewModel = State(initialValue: EditExperimentViewModel(
            experiment: experiment,
            student: student,
            dataStore: AppDataStore(populateSampleData: false)
        ))
    }
    
    private var experimentService: ExperimentService {
        ExperimentService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                if !viewModel.isEligibleForEdit {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("This experiment is locked (\(experiment.status.displayName)) and cannot be modified.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - Identification & Subject
                Section(header: Text("Experiment Info")) {
                    CustomTextField(
                        title: "Experiment Number",
                        placeholder: "e.g., EXP-01",
                        iconName: "number.circle.fill",
                        text: $viewModel.experimentNumber
                    )
                    .disabled(!viewModel.isEligibleForEdit)
                    
                    CustomTextField(
                        title: "Experiment Title",
                        placeholder: "Title",
                        iconName: "doc.text.fill",
                        text: $viewModel.title
                    )
                    .disabled(!viewModel.isEligibleForEdit)
                    
                    Picker("Subject", selection: $viewModel.selectedSubjectId) {
                        ForEach(viewModel.availableSubjects) { subject in
                            Text("\(subject.code): \(subject.name)").tag(subject.id)
                        }
                    }
                    .disabled(!viewModel.isEligibleForEdit)
                    
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                        .disabled(!viewModel.isEligibleForEdit)
                }
                
                // MARK: - Aim
                Section(header: Text("Aim of the Experiment")) {
                    TextEditor(text: $viewModel.aim)
                        .frame(minHeight: 70)
                        .disabled(!viewModel.isEligibleForEdit)
                }
                
                // MARK: - Procedure / Algorithm
                Section(header: Text("Algorithm / Procedure")) {
                    TextEditor(text: $viewModel.procedure)
                        .frame(minHeight: 110)
                        .disabled(!viewModel.isEligibleForEdit)
                }
                
                // MARK: - Result / Observation
                Section(header: Text("Result / Observation")) {
                    TextEditor(text: $viewModel.result)
                        .frame(minHeight: 80)
                        .disabled(!viewModel.isEligibleForEdit)
                }
            }
            .navigationTitle("Edit \(experiment.experimentNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveChanges(experimentService: experimentService) {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isEligibleForEdit)
                }
            }
            .onAppear {
                viewModel = EditExperimentViewModel(
                    experiment: experiment,
                    student: student,
                    dataStore: dataStore
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let exp = store.experiments.first!
    let student = store.user(byId: exp.studentId ?? UUID())!
    return EditExperimentView(experiment: exp, student: student)
        .environment(store)
}
