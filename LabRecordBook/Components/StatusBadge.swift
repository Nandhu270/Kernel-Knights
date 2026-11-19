import SwiftUI

/// Status chip displaying experiment state with color and icon.
public struct StatusBadge: View {
    public let status: ExperimentStatus
    
    public init(status: ExperimentStatus) {
        self.status = status
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.iconName)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.badgeColor.opacity(0.15))
        .foregroundStyle(status.badgeColor)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 10) {
        ForEach(ExperimentStatus.allCases) { status in
            StatusBadge(status: status)
        }
    }
    .padding()
}
