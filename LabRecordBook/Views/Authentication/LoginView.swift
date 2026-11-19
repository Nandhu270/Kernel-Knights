// xcode: set sdk=iOS

import SwiftUI

/// Login screen for the Lab Record Book application.
/// Supports username/password authentication, error validation,
/// deactivated account prevention, and quick demo role selection.
public struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = AuthViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 88, height: 88)
                            
                            Image(systemName: "books.vertical.circle.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.top, 24)
                        
                        VStack(spacing: 6) {
                            Text("Lab Record Book")
                                .font(.system(.title, design: .rounded, weight: .bold))
                            
                            Text("Academic Lab Simulation & Tracking")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // MARK: - Error Banner
                    if viewModel.showError, let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // MARK: - Credentials Input
                    VStack(spacing: 16) {
                        CustomTextField(
                            title: "Username",
                            placeholder: "Enter username",
                            iconName: "person.fill",
                            text: $viewModel.username
                        )
                        
                        CustomTextField(
                            title: "Password",
                            placeholder: "Enter password",
                            iconName: "lock.fill",
                            text: $viewModel.password,
                            isSecure: true
                        )
                        
                        Button(action: {
                            _ = viewModel.login(authService: authService)
                        }) {
                            HStack {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // MARK: - Demo Quick Accounts
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Demo Accounts")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            Spacer()
                            
                            Text("Tap to populate")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        VStack(spacing: 8) {
                            demoAccountRow(
                                title: "Admin",
                                subtitle: "admin / admin123",
                                icon: "person.badge.key.fill",
                                color: .purple,
                                username: "admin",
                                password: "admin123"
                            )
                            
                            demoAccountRow(
                                title: "Mentor",
                                subtitle: "dr.smith / mentor123",
                                icon: "person.crop.rectangle.badge.plus",
                                color: .indigo,
                                username: "dr.smith",
                                password: "mentor123"
                            )
                            
                            demoAccountRow(
                                title: "Student",
                                subtitle: "john.doe / student123",
                                icon: "graduationcap.fill",
                                color: .blue,
                                username: "john.doe",
                                password: "student123"
                            )
                            
                            demoAccountRow(
                                title: "Inactive User (Blocked)",
                                subtitle: "inactive.user / pass123",
                                icon: "person.crop.circle.badge.xmark",
                                color: .red,
                                username: "inactive.user",
                                password: "pass123"
                            )
                        }
                    }
                    .padding(16)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func demoAccountRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        username: String,
        password: String
    ) -> some View {
        Button(action: {
            viewModel.fillDemoCredentials(username: username, password: password)
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    let store = AppDataStore()
    let authService = AuthService(dataStore: store)
    return LoginView()
        .environment(store)
        .environment(authService)
}
