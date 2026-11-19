import SwiftUI

/// Reusable card component displaying assignment details, recipient student, and due date.
public struct AssignmentCard: View {
    public let assignment: Assignment
    public let subject: Subject?
    public let student: User?
    public let mentor: User?
    public let showStudent: Bool
    
    public init(
        assignment: Assignment,
        subject: Subject?,
        student: User? = nil,
        mentor: User? = nil,
        showStudent: Bool = true
    ) {
        self.assignment = assignment
        self.subject = subject
        self.student = student
        self.mentor = mentor
        self.showStudent = showStudent
    }
    
    private var formattedAssignedDate: String {
        DateFormatter.localizedString(from: assignment.assignedDate, dateStyle: .medium, timeStyle: .none)
    }
    
    private var formattedDueDate: String {
        DateFormatter.localizedString(from: assignment.dueDate, dateStyle: .medium, timeStyle: .none)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Title & Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if !assignment.experimentNumber.isEmpty {
                        Text(assignment.experimentNumber)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.tint)
                    }
                    
                    Text(assignment.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(assignment.isCompleted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(assignment.status.displayName)
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (assignment.isCompleted ? Color.green : Color.orange).opacity(0.12)
                )
                .foregroundStyle(assignment.isCompleted ? Color.green : Color.orange)
                .clipShape(Capsule())
            }
            
            // Subject Information
            if let subj = subject {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(subj.code): \(subj.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Student or Mentor info
            if showStudent, let student = student {
                HStack(spacing: 4) {
                    Image(systemName: "graduationcap.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("Assigned to: \(student.name)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            } else if let mentor = mentor {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.rectangle.badge.plus")
                        .font(.caption2)
                        .foregroundStyle(.indigo)
                    Text("Assigned by: \(mentor.name)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Footer: Assigned Date and Due Date
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Assigned: \(formattedAssignedDate)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Due: \(formattedDueDate)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let store = AppDataStore()
    let assign = store.assignments.first!
    let subj = store.subject(byId: assign.subjectId)
    let stud = store.user(byId: assign.studentId)
    return AssignmentCard(
        assignment: assign,
        subject: subj,
        student: stud,
        showStudent: true
    )
    .padding()
}
