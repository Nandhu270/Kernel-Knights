import SwiftUI

/// Component displaying student progress overview for mentors and administrators.
public struct StudentProgressRow: View {
    public let summary: StudentProgressSummary
    public var onTap: (() -> Void)? = nil
    
    public init(summary: StudentProgressSummary, onTap: (() -> Void)? = nil) {
        self.summary = summary
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "graduationcap.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.student.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text(summary.student.department)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f%%", summary.completionPercentage))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(summary.completionPercentage >= 100 ? .green : .blue)
                        
                        Text("\(summary.verifiedCount)/\(summary.totalAssigned) verified")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ProgressBarView(
                    value: summary.completionPercentage,
                    tintColor: summary.completionPercentage >= 100 ? .green : .blue,
                    height: 5
                )
                
                if summary.requiresAttention {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text("\(summary.rejectedCount) experiment(s) require student correction")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let student = User(name: "John Doe", username: "john.doe", password: "123", role: .student, department: "Computer Science")
    let summary = StudentProgressSummary(
        student: student,
        totalAssigned: 5,
        verifiedCount: 3,
        pendingCount: 1,
        rejectedCount: 1
    )
    return StudentProgressRow(summary: summary)
        .padding()
}
