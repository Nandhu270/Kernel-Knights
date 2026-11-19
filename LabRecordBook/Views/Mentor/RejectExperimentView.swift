import SwiftUI

/// Sheet view requiring mentor to enter rejection feedback before returning experiment to student.
public struct RejectExperimentView: View {
    @Bindable public var viewModel: ExperimentReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: ExperimentReviewViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Rejection Feedback"),
                    footer: Text("Constructive feedback is required so the student knows what needs revision before resubmission.")
                ) {
                    TextField(
                        "Explain what needs correction (e.g. incorrect time complexity, missing test cases, incomplete normalization)...",
                        text: $viewModel.rejectionComments,
                        axis: .vertical
                    )
                    .lineLimit(5...10)
                }
                
                Section {
                    Button(role: .destructive, action: {
                        if viewModel.reject() {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Label("Confirm Rejection & Return to Student", systemImage: "xmark.seal.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.rejectionComments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Reject Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
        }
    }
}
