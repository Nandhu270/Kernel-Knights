import SwiftUI

/// Reusable empty state view when no content is present.
public struct EmptyStateView: View {
    public let iconName: String
    public let title: String
    public let message: String
    public var actionTitle: String? = nil
    public var action: (() -> Void)? = nil
    
    public init(
        iconName: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        iconName: "doc.text.magnifyingglass",
        title: "No Experiments Found",
        message: "No lab experiments match your search query or subject filters.",
        actionTitle: "Reset Filters"
    ) {}
}
