import SwiftUI

/// Screen allowing a supervising mentor to thoroughly review a submitted experiment and verify or reject it.
public struct ExperimentReviewView: View {
    public let experimentId: UUID
    public let mentor: User
    
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExperimentReviewViewModel?
    
    public init(experimentId: UUID, mentor: User) {
        self.experimentId = experimentId
        self.mentor = mentor
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel, let exp = vm.experiment {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card: Title, Status, and Student Info
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(exp.experimentNumber)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.tint)
                                Spacer()
                                StatusBadge(status: exp.status)
                            }
                            
                            Text(exp.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let subj = vm.subject {
                                HStack(spacing: 6) {
                                    Image(systemName: "book.closed.fill")
                                        .foregroundStyle(.secondary)
                                    Text("\(subj.code) - \(subj.name)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // Student Author Info
                            if let s = vm.student {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.purple.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "graduationcap.fill")
                                                .foregroundStyle(.purple)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.name)
                                            .font(.headline)
                                        Text("\(s.department) • @\(s.username)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Submitted on \(DateFormatter.localizedString(from: exp.lastUpdated, dateStyle: .medium, timeStyle: .short))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Aim Card
                        contentCard(
                            title: "Aim / Objective",
                            icon: "target",
                            content: exp.aim,
                            accentColor: .blue
                        )
                        
                        // Procedure Card
                        contentCard(
                            title: "Algorithm & Procedure",
                            icon: "list.number",
                            content: exp.procedure,
                            accentColor: .indigo
                        )
                        
                        // Result Card
                        contentCard(
                            title: "Observations & Results",
                            icon: "chart.bar.doc.horizontal.fill",
                            content: exp.result.isEmpty ? "No results recorded." : exp.result,
                            accentColor: .teal
                        )
                        
                        // Verification History Audit Trail
                        if !vm.verificationHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Previous Review History")
                                    .font(.headline)
                                
                                ForEach(vm.verificationHistory) { review in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            StatusBadge(status: review.status)
                                            Spacer()
                                            Text(DateFormatter.localizedString(from: review.timestamp, dateStyle: .short, timeStyle: .short))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Text(review.comments)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Reviewed by \(review.mentorName)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Review Actions (Only active if currently .submitted)
                        if exp.status == .submitted {
                            VStack(spacing: 12) {
                                Button(action: {
                                    vm.showVerificationConfirmation = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Label("Verify & Approve Experiment", systemImage: "checkmark.seal.fill")
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                
                                Button(action: {
                                    vm.showRejectSheet = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Label("Reject with Feedback", systemImage: "exclamationmark.triangle.fill")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.red.opacity(0.12))
                                    .foregroundStyle(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            .padding(.top, 10)
                        } else {
                            Text("This experiment is already \(exp.status.displayName.lowercased()) and cannot be reviewed further.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
                .confirmationDialog(
                    "Confirm Verification",
                    isPresented: Bindable(vm).showVerificationConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Approve and Verify Experiment") {
                        if vm.verify() {
                            dismiss()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to approve and mark this experiment as Verified? This will finalize the student's submission.")
                }
                .sheet(isPresented: Bindable(vm).showRejectSheet, onDismiss: {
                    if vm.isProcessedSuccessfully {
                        dismiss()
                    }
                }) {
                    RejectExperimentView(viewModel: vm)
                }
                .alert("Error", isPresented: Bindable(vm).showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(vm.errorMessage ?? "An error occurred.")
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Review Experiment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = ExperimentReviewViewModel(experimentId: experimentId, mentor: mentor, dataStore: dataStore)
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
            
            Text(content)
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
    let mentor = store.users.first { $0.role == .mentor }!
    let exp = store.experiments.first { $0.status == .submitted }!
    return NavigationStack {
        ExperimentReviewView(experimentId: exp.id, mentor: mentor)
            .environment(store)
    }
}
