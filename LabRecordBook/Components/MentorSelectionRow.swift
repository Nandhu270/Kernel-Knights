import SwiftUI

/// Component row for selecting a mentor from a list.
public struct MentorSelectionRow: View {
    public let mentor: User
    public let isSelected: Bool
    public var onSelect: () -> Void
    
    public init(mentor: User, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.mentor = mentor
        self.isSelected = isSelected
        self.onSelect = onSelect
    }
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mentor.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("@\(mentor.username) • \(mentor.department)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .padding(10)
            .background(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let mentor = User(name: "Dr. Robert Smith", username: "dr.smith", password: "123", role: .mentor, department: "Computer Science")
    return MentorSelectionRow(mentor: mentor, isSelected: true, onSelect: {})
        .padding()
}
