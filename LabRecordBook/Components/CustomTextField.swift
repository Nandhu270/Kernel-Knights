import SwiftUI

/// Styled input field with leading icon, title, and clear error presentation.
public struct CustomTextField: View {
    public let title: String
    public let placeholder: String
    public let iconName: String
    @Binding public var text: String
    public var isSecure: Bool = false
    @State private var isShowingPassword: Bool = false
    
    public init(
        title: String,
        placeholder: String,
        iconName: String,
        text: Binding<String>,
        isSecure: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self.iconName = iconName
        self._text = text
        self.isSecure = isSecure
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundStyle(.tint)
                    .frame(width: 22)
                
                if isSecure && !isShowingPassword {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if isSecure {
                    Button(action: {
                        isShowingPassword.toggle()
                    }) {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                } else if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "john.doe"
        @State private var pass = "student123"
        
        var body: some View {
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Username",
                    placeholder: "Enter username",
                    iconName: "person.fill",
                    text: $text
                )
                
                CustomTextField(
                    title: "Password",
                    placeholder: "Enter password",
                    iconName: "lock.fill",
                    text: $pass,
                    isSecure: true
                )
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
