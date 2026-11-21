import SwiftUI

/// Component displaying subject-wise progress with code, name, verified count, and progress bar.
public struct SubjectProgressRow: View {
    public let progress: SubjectProgress
    
    public init(progress: SubjectProgress) {
        self.progress = progress
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.subject.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(progress.subject.code)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(progress.verifiedExperiments)/\(progress.totalExperiments) Verified")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(progress.verifiedExperiments == progress.totalExperiments && progress.totalExperiments > 0 ? .green : .secondary)
                    
                    Text(String(format: "%.0f%%", progress.completionPercentage))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.tint)
                }
            }
            
            ProgressBarView(
                value: progress.completionPercentage,
                tintColor: progress.completionPercentage >= 100.0 ? .green : .blue,
                height: 6
            )
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let subject = Subject(name: "Data Structures & Algorithms", code: "CS201")
    let progress = SubjectProgress(
        subject: subject,
        totalExperiments: 4,
        verifiedExperiments: 3,
        pendingExperiments: 1
    )
    return SubjectProgressRow(progress: progress)
        .padding()
}
