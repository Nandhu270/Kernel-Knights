import SwiftUI

/// Form sheet allowing a student to create a new experiment entry.
public struct CreateExperimentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var dataStore
    
    public let student: User
    @State private var viewModel: CreateExperimentViewModel
    
    public init(student: User) {
        self.student = student
        self._viewModel = State(initialValue: CreateExperimentViewModel(student: student, dataStore: AppDataStore(populateSampleData: false)))
    }
    
    private var experimentService: ExperimentService {
        ExperimentService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Identification & Subject
                Section(header: Text("Experiment Info")) {
                    CustomTextField(
                        title: "Experiment Number",
                        placeholder: "e.g., EXP-01",
                        iconName: "number.circle.fill",
                        text: $viewModel.experimentNumber
                    )
                    
                    CustomTextField(
                        title: "Experiment Title",
                        placeholder: "e.g., Stack Implementation Using Arrays",
                        iconName: "doc.text.fill",
                        text: $viewModel.title
                    )
                    
                    Picker("Subject", selection: $viewModel.selectedSubjectId) {
                        ForEach(viewModel.availableSubjects) { subject in
                            Text("\(subject.code): \(subject.name)").tag(Optional(subject.id))
                        }
                    }
                    
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                }
                
                // MARK: - Aim
                Section(header: Text("Aim of the Experiment")) {
                    TextEditor(text: $viewModel.aim)
                        .frame(minHeight: 70)
                }
                
                // MARK: - Procedure / Algorithm
                Section(header: Text("Algorithm / Procedure")) {
                    TextEditor(text: $viewModel.procedure)
                        .frame(minHeight: 110)
                }
                
                // MARK: - Result / Observation
                Section(header: Text("Result / Observation (Optional)"), footer: Text("You can record your preliminary output or test observations now and update later.")) {
                    TextEditor(text: $viewModel.result)
                        .frame(minHeight: 70)
                }
            }
            .navigationTitle("New Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.createExperiment(experimentService: experimentService) {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel = CreateExperimentViewModel(student: student, dataStore: dataStore)
            }
            .alert("Validation Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Please review form fields.")
            }
        }
    }
}

#Preview {
    let store = AppDataStore()
    let student = store.users.first { $0.role == .student }!
    return CreateExperimentView(student: student)
        .environment(store)
}
