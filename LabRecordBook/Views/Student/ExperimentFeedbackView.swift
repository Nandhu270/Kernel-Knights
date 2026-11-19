import SwiftUI

/// Component or card displaying mentor verification feedback, approval badge, or rejection comments.
public struct ExperimentFeedbackView: View {
    public let experiment: Experiment
    public let verifications: [Verification]
    public let onEditTapped: (() -> Void)?
    public let onSubmitTapped: (() -> Void)?
    
    public init(
        experiment: Experiment,
        verifications: [Verification],
        onEditTapped: (() -> Void)? = nil,
        onSubmitTapped: (() -> Void)? = nil
    ) {
        self.experiment = experiment
        self.verifications = verifications
        self.onEditTapped = onEditTapped
        self.onSubmitTapped = onSubmitTapped
    }
    
    private var latestVerification: Verification? {
        verifications.last
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Status-specific banner
            switch experiment.status {
            case .verified:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verified & Approved")
                            .font(.headline)
                            .foregroundStyle(.green)
                        
                        if let v = latestVerification {
                            Text("Reviewed by \(v.mentorName) on \(DateFormatter.localizedString(from: v.timestamp, dateStyle: .medium, timeStyle: .short))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if !v.comments.isEmpty {
                                Text("\"\(v.comments)\"")
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundStyle(.primary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
            case .rejected:
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Revision Required")
                                .font(.headline)
                                .foregroundStyle(.red)
                            
                            if let v = latestVerification {
                                Text("Feedback from \(v.mentorName) on \(DateFormatter.localizedString(from: v.timestamp, dateStyle: .medium, timeStyle: .short))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if let v = latestVerification, !v.comments.isEmpty {
                        Text(v.comments)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Action Buttons: Correct & Resubmit
                    HStack(spacing: 12) {
                        if let onEdit = onEditTapped {
                            Button(action: onEdit) {
                                Label("Correct Experiment", systemImage: "pencil")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        if let onSubmit = onSubmitTapped {
                            Button(action: onSubmit) {
                                Label("Resubmit", systemImage: "paperplane.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
            case .submitted:
                HStack(spacing: 12) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Submitted for Verification")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        Text("Your experiment is currently in the mentor's review queue. Normal editing is locked while awaiting review.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
            default:
                EmptyView()
            }
            
            // Full Verification History if multiple records exist
            if verifications.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification History (\(verifications.count) Reviews)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    ForEach(verifications.reversed()) { review in
                        HStack(alignment: .top, spacing: 10) {
                            StatusBadge(status: review.status)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(review.mentorName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(DateFormatter.localizedString(from: review.timestamp, dateStyle: .short, timeStyle: .short))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(review.comments)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}
