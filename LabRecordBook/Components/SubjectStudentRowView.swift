import SwiftUI

/// Component displaying a student enrolled in a subject under a mentor with completion stats and attention indicator.
public struct SubjectStudentRowView: View {
    public let student: User
    public let summary: StudentProgressSummary
    public let mentorName: String?
    public var onTap: (() -> Void)? = nil
    
    public init(
        student: User,
        summary: StudentProgressSummary,
        mentorName: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.student = student
        self.summary = summary
        self.mentorName = mentorName
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
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "graduationcap.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(student.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text("@\(student.username) • \(student.department)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        if let mName = mentorName {
                            Text("Mentor: \(mName)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.indigo)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f%%", summary.completionPercentage))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(summary.completionPercentage >= 100 ? .green : .blue)
                        
                        Text("\(summary.verifiedCount)/\(summary.totalAssigned) done")
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
                        Text("\(summary.rejectedCount) rejection(s) require correction")
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
    let summary = StudentProgressSummary(student: student, totalAssigned: 4, verifiedCount: 2, pendingCount: 1, rejectedCount: 1)
    return SubjectStudentRowView(student: student, summary: summary, mentorName: "Dr. Robert Smith")
        .padding()
}
