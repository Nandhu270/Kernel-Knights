import SwiftUI

/// Distinctive visual badge displaying user role with color and icon.
public struct RoleBadge: View {
    public let role: UserRole
    
    public init(role: UserRole) {
        self.role = role
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: role.iconName)
                .font(.caption2)
            Text(role.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(role.badgeColor.opacity(0.15))
        .foregroundStyle(role.badgeColor)
        .clipShape(Capsule())
    }
}

#Preview {
    HStack(spacing: 12) {
        RoleBadge(role: .admin)
        RoleBadge(role: .mentor)
        RoleBadge(role: .student)
    }
    .padding()
}
