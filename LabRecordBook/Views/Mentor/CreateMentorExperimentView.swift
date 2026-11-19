import SwiftUI

/// Form view allowing a mentor to create a master experiment template for student assignment.
public struct CreateMentorExperimentView: View {
    public let mentor: User
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: CreateMentorExperimentViewModel?
    @State private var showingAssignSheet = false
    
    public init(mentor: User) {
        self.mentor = mentor
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    Form {
                        // Section 1: Identification & Subject
                        Section(header: Text("Basic Information")) {
                            TextField("Experiment Number (e.g. EXP-05)", text: Bindable(vm).experimentNumber)
                            
                            TextField("Experiment Title", text: Bindable(vm).title)
                            
                            Picker("Subject", selection: Bindable(vm).selectedSubjectId) {
                                Text("Select a subject").tag(nil as UUID?)
                                ForEach(vm.availableSubjects) { subject in
                                    Text("\(subject.code) - \(subject.name)")
                                        .tag(subject.id as UUID?)
                                }
                            }
                            
                            DatePicker("Date", selection: Bindable(vm).date, displayedComponents: .date)
                        }
                        
                        // Section 2: Experiment Aim
                        Section(header: Text("Aim / Objective")) {
                            TextField("State the objective of this experiment...", text: Bindable(vm).aim, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        // Section 3: Procedure / Algorithm
                        Section(header: Text("Algorithm & Procedure")) {
                            TextField("Step-by-step instructions or algorithm...", text: Bindable(vm).procedure, axis: .vertical)
                                .lineLimit(5...10)
                        }
                        
                        // Section 4: Expected Result
                        Section(header: Text("Expected Result / Observations (Optional)")) {
                            TextField("Expected output, test cases, or result template...", text: Bindable(vm).result, axis: .vertical)
                                .lineLimit(2...5)
                        }
                        
                        // Section 5: Actions
                        Section {
                            Button(action: saveAndAssign) {
                                HStack {
                                    Spacer()
                                    Label("Save & Assign to Students", systemImage: "person.crop.rectangle.badge.plus")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                            .disabled(!vm.isFormValid)
                            
                            Button(action: saveOnly) {
                                HStack {
                                    Spacer()
                                    Text("Save as Template Only")
                                    Spacer()
                                }
                            }
                            .disabled(!vm.isFormValid)
                        }
                    }
                    .alert("Error Creating Experiment", isPresented: Bindable(vm).showError) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(vm.errorMessage ?? "An error occurred.")
                    }
                    .sheet(isPresented: $showingAssignSheet, onDismiss: {
                        dismiss()
                    }) {
                        if let created = vm.createdExperiment {
                            NavigationStack {
                                AssignExperimentView(experiment: created, mentor: mentor)
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Create Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = CreateMentorExperimentViewModel(mentor: mentor, dataStore: dataStore)
                }
            }
        }
    }
    
    private func saveOnly() {
        guard let vm = viewModel else { return }
        if vm.createExperiment() {
            dismiss()
        }
    }
    
    private func saveAndAssign() {
        guard let vm = viewModel else { return }
        if vm.createExperiment() {
            showingAssignSheet = true
        }
    }
}

#Preview {
    let store = AppDataStore()
    let mentor = store.users.first { $0.role == .mentor }!
    return CreateMentorExperimentView(mentor: mentor)
        .environment(store)
}
