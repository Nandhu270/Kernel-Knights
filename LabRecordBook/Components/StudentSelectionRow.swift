import SwiftUI

/// Row component for selecting a student in assignment flows.
public struct StudentSelectionRow: View {
    public let student: User
    public let isSelected: Bool
    public let isAlreadyAssigned: Bool
    public let onToggle: () -> Void
    
    public init(
        student: User,
        isSelected: Bool,
        isAlreadyAssigned: Bool = false,
        onToggle: @escaping () -> Void
    ) {
        self.student = student
        self.isSelected = isSelected
        self.isAlreadyAssigned = isAlreadyAssigned
        self.onToggle = onToggle
    }
    
    public var body: some View {
        Button(action: {
            if !isAlreadyAssigned {
                onToggle()
            }
        }) {
            HStack(spacing: 12) {
                // Checkbox or already-assigned mark
                if isAlreadyAssigned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(student.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(isAlreadyAssigned ? .secondary : .primary)
                        
                        if isAlreadyAssigned {
                            Text("Already Assigned")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text("@\(student.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Text(student.department)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAssigned)
    }
}

#Preview {
    let student = User(
        name: "Jane Smith",
        username: "jane.smith",
        password: "123",
        role: .student,
        department: "Computer Science"
    )
    return VStack {
        StudentSelectionRow(student: student, isSelected: true, onToggle: {})
        StudentSelectionRow(student: student, isSelected: false, onToggle: {})
        StudentSelectionRow(student: student, isSelected: false, isAlreadyAssigned: true, onToggle: {})
    }
    .padding()
}
