import SwiftUI

/// Reusable card component displaying an experiment summary with number, title, subject, date, and status.
public struct ExperimentCard: View {
    public let experiment: Experiment
    public let subject: Subject?
    public let student: User?
    public var showStudentInfo: Bool = false
    
    public init(
        experiment: Experiment,
        subject: Subject?,
        student: User? = nil,
        showStudentInfo: Bool = false
    ) {
        self.experiment = experiment
        self.subject = subject
        self.student = student
        self.showStudentInfo = showStudentInfo
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: experiment.date)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Exp Number & Status Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number.circle.fill")
                        .foregroundStyle(.tint)
                    Text(experiment.experimentNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                StatusBadge(status: experiment.status)
            }
            
            // Title
            Text(experiment.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            // Subject Information
            if let subj = subject {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(subj.code): \(subj.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Student Information (when visible for Admin / Mentor)
            if showStudentInfo, let student = student {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("Student: \(student.name)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            
            // Mentor Assignment Indicator (Phase 4 requirement: distinguish assigned experiments)
            if experiment.isAssignedByMentor {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.caption2)
                    Text("Assigned by Mentor")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.indigo)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.indigo.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Footer: Date & Assignee indicator
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(formattedDate)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                
                Spacer()
                
                if experiment.isAssignedByMentor {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.caption2)
                        Text("Mentor Assigned")
                            .font(.caption2)
                    }
                    .foregroundStyle(.indigo)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.8)
        )
    }
}

#Preview {
    let store = AppDataStore()
    let exp = store.experiments.first!
    let subj = store.subject(byId: exp.subjectId)
    return ExperimentCard(
        experiment: exp,
        subject: subj,
        student: exp.studentId.flatMap { store.user(byId: $0) },
        showStudentInfo: true
    )
    .padding()
}
