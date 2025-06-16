import SwiftUI

struct OnboardingView: View {
    @Environment(\.lastFMClient) private var lastFMClient
    @Environment(\.currentUser) private var currentUser
    
    @State private var username = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    
                    Text("Welcome to Vinylogue")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Discover your weekly music listening habits")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Username input section
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your Last.fm username")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                validateAndSubmit()
                            }
                            .accessibilityLabel("Last.fm username")
                            .accessibilityHint("Enter your Last.fm username to get started")
                        
                        if let errorMessage = errorMessage, showError {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: validateAndSubmit) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isValidating ? "Validating..." : "Get Started")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(submitButtonBackground)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(username.isEmpty || isValidating)
                    .accessibilityLabel(isValidating ? "Validating username" : "Get started with Last.fm")
                    .accessibilityHint("Validates your username and sets up the app")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Help text
                VStack(spacing: 8) {
                    Text("Don't have a Last.fm account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Link("Sign up at Last.fm", destination: URL(string: "https://www.last.fm/join")!)
                        .font(.footnote)
                        .accessibilityHint("Opens Last.fm signup page in browser")
                }
                .padding(.bottom, 32)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            // Auto-focus the text field for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Username Validation", isPresented: $showError) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var submitButtonBackground: Color {
        if username.isEmpty || isValidating {
            return .gray.opacity(0.6)
        } else {
            return .accentColor
        }
    }
    
    private func validateAndSubmit() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("Please enter a username")
            return
        }
        
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await validateUsername(cleanUsername)
        }
    }
    
    @MainActor
    private func validateUsername(_ username: String) async {
        isValidating = true
        errorMessage = nil
        showError = false
        
        do {
            // Validate by attempting to fetch user info
            let _: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))
            
            // If successful, save the user and proceed
            
            // Update the current user in the environment
            // Note: This would typically be done through a proper state management system
            UserDefaults.standard.set(username, forKey: "currentUser")
            
            isValidating = false
            
            // The app should now navigate to the main interface
            // This will be handled by RootView observing the user state
            
        } catch {
            isValidating = false
            
            switch error {
            case LastFMError.userNotFound:
                setError("Username not found. Please check your spelling or create a Last.fm account.")
            case LastFMError.networkUnavailable:
                setError("No internet connection. Please check your network and try again.")
            case LastFMError.serviceUnavailable:
                setError("Last.fm is temporarily unavailable. Please try again later.")
            case LastFMError.invalidAPIKey:
                setError("There's an issue with the app configuration. Please contact support.")
            default:
                setError("Unable to validate username. Please try again.")
            }
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
        
        // Provide haptic feedback for errors
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Previews

#Preview("Default") {
    OnboardingView()
}

#Preview("Dark Mode") {
    OnboardingView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    OnboardingView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}