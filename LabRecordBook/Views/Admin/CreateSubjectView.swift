import SwiftUI

/// Modal sheet for creating a new academic course subject.
public struct CreateSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var dataStore
    
    @State private var code: String = ""
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var department: String = "Computer Science & Engineering"
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    
    public init() {}
    
    private var subjectService: SubjectService {
        SubjectService(dataStore: dataStore)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Course Identification")) {
                    CustomTextField(
                        title: "Subject Code",
                        placeholder: "e.g., CS401",
                        iconName: "number.circle.fill",
                        text: $code
                    )
                    
                    CustomTextField(
                        title: "Subject Name",
                        placeholder: "e.g., Cloud Computing & DevOps",
                        iconName: "book.fill",
                        text: $name
                    )
                    
                    Picker("Department", selection: $department) {
                        ForEach(dataStore.departments) { dept in
                            Text(dept.name).tag(dept.name)
                        }
                    }
                }
                
                Section(header: Text("Syllabus & Lab Description (Optional)")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 90)
                }
            }
            .navigationTitle("New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubject()
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
    
    private func saveSubject() {
        do {
            try subjectService.createSubject(
                name: name,
                code: code,
                description: description,
                department: department
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
    return CreateSubjectView()
        .environment(store)
}
