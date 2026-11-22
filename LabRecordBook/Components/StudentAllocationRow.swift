import SwiftUI

/// Component row displaying a student in an allocation management screen with assigned mentor and action button.
public struct StudentAllocationRow: View {
    public let student: User
    public let allocatedMentor: User?
    public var onAssignOrChange: () -> Void
    public var onRemove: (() -> Void)? = nil
    
    public init(
        student: User,
        allocatedMentor: User?,
        onAssignOrChange: @escaping () -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.student = student
        self.allocatedMentor = allocatedMentor
        self.onAssignOrChange = onAssignOrChange
        self.onRemove = onRemove
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "graduationcap.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(student.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("@\(student.username) • \(student.department)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let mentor = allocatedMentor {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.caption2)
                        Text("Mentor: \(mentor.name)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Not Allocated")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Button(action: onAssignOrChange) {
                    Text(allocatedMentor == nil ? "Allocate" : "Reassign")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(allocatedMentor == nil ? Color.blue : Color(.tertiarySystemFill))
                        .foregroundStyle(allocatedMentor == nil ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                if allocatedMentor != nil, let removeAction = onRemove {
                    Button(action: removeAction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let s = User(name: "John Doe", username: "john.doe", password: "123", role: .student, department: "Computer Science")
    let m = User(name: "Dr. Robert Smith", username: "dr.smith", password: "123", role: .mentor, department: "Computer Science")
    return StudentAllocationRow(student: s, allocatedMentor: m, onAssignOrChange: {}, onRemove: {})
        .padding()
}
