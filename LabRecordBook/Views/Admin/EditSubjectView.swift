import SwiftUI

/// Modal sheet for editing an existing course subject.
public struct EditSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var dataStore
    
    public let subject: Subject
    
    @State private var code: String
    @State private var name: String
    @State private var description: String
    @State private var department: String
    @State private var isActive: Bool
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    
    public init(subject: Subject) {
        self.subject = subject
        self._code = State(initialValue: subject.code)
        self._name = State(initialValue: subject.name)
        self._description = State(initialValue: subject.description)
        self._department = State(initialValue: subject.department)
        self._isActive = State(initialValue: subject.isActive)
    }
    
    private var subjectService: SubjectService {
        SubjectService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Course Identification")) {
                    CustomTextField(
                        title: "Subject Code",
                        placeholder: "e.g., CS201",
                        iconName: "number.circle.fill",
                        text: $code
                    )
                    
                    CustomTextField(
                        title: "Subject Name",
                        placeholder: "e.g., Data Structures",
                        iconName: "book.fill",
                        text: $name
                    )
                    
                    Picker("Department", selection: $department) {
                        ForEach(dataStore.departments) { dept in
                            Text(dept.name).tag(dept.name)
                        }
                    }
                    
                    Toggle("Active Status", isOn: $isActive)
                }
                
                Section(header: Text("Syllabus & Lab Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 90)
                }
            }
            .navigationTitle("Edit Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateSubject()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please review fields.")
            }
        }
    }
    
    private func updateSubject() {
        do {
            try subjectService.updateSubject(
                id: subject.id,
                name: name,
                code: code,
                description: description,
                department: department,
                isActive: isActive
            )
            dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
}

#Preview {
    let store = AppDataStore()
    let sub = store.subjects.first!
    return EditSubjectView(subject: sub)
        .environment(store)
}
