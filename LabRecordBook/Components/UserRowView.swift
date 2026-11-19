import SwiftUI

/// Reusable row component displaying a user's details, role, department, mentor, and status.
public struct UserRowView: View {
    public let user: User
    public let mentorName: String?
    public var onToggleActive: (() -> Void)? = nil
    
    public init(
        user: User,
        mentorName: String? = nil,
        onToggleActive: (() -> Void)? = nil
    ) {
        self.user = user
        self.mentorName = mentorName
        self.onToggleActive = onToggleActive
    }
    
    private var initials: String {
        let parts = user.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(user.role.badgeColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(user.role.badgeColor)
                )
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !user.isActive {
                        Text("Deactivated")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text("@\(user.username) • \(user.department)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 6) {
                    RoleBadge(role: user.role)
                    
                    if user.role == .student {
                        if let mentor = mentorName {
                            HStack(spacing: 3) {
                                Image(systemName: "person.crop.rectangle.badge.plus")
                                    .font(.caption2)
                                Text("Mentor: \(mentor)")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.12))
                            .foregroundStyle(.indigo)
                            .clipShape(Capsule())
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.caption2)
                                Text("No Mentor")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                        }
                    } else if user.role == .mentor {
                        Text("\(user.assignedStudentIds.count) students")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.12))
                            .foregroundStyle(.indigo)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Active Status Button / Indicator
            if let onToggle = onToggleActive, user.role != .admin {
                Button(action: onToggle) {
                    Image(systemName: user.isActive ? "checkmark.circle.fill" : "nosign")
                        .font(.title3)
                        .foregroundStyle(user.isActive ? .green : .red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(user.isActive ? "Deactivate Account" : "Activate Account")
            } else {
                Image(systemName: user.isActive ? "checkmark.circle.fill" : "nosign")
                    .font(.subheadline)
                    .foregroundStyle(user.isActive ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        UserRowView(
            user: User(
                name: "John Doe",
                username: "john.doe",
                password: "123",
                role: .student,
                department: "CSE",
                isActive: true
            ),
            mentorName: "Dr. Robert Smith"
        ) {}
        
        UserRowView(
            user: User(
                name: "Dr. Robert Smith",
                username: "dr.smith",
                password: "123",
                role: .mentor,
                department: "CSE",
                isActive: true,
                assignedStudentIds: [UUID(), UUID()]
            )
        ) {}
        
        UserRowView(
            user: User(
                name: "Inactive User",
                username: "inactive.user",
                password: "123",
                role: .student,
                department: "CSE",
                isActive: false
            ),
            mentorName: nil
        ) {}
    }
    .padding()
}
