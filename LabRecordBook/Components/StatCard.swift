import SwiftUI

/// Reusable metric summary card for dashboards.
public struct StatCard: View {
    public let title: String
    public let value: String
    public let iconName: String
    public let color: Color
    
    public init(title: String, value: String, iconName: String, color: Color) {
        self.title = title
        self.value = value
        self.iconName = iconName
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(
            title: "Total Users",
            value: "6",
            iconName: "person.3.fill",
            color: .purple
        )
        StatCard(
            title: "Verified",
            value: "12",
            iconName: "checkmark.seal.fill",
            color: .green
        )
    }
    .padding()
}
