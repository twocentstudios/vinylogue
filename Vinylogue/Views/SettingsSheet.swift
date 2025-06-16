import MessageUI
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.playCountFilter) private var playCountFilter
    @Environment(\.currentUser) private var currentUser

    @State private var currentPlayCountFilter: Int
    @State private var showingMailComposer = false
    @State private var showingUsernamePicker = false
    @State private var showingUsernameChangeSheet = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    init() {
        // Initialize with current filter value from UserDefaults
        let filter = UserDefaults.standard.object(forKey: "currentPlayCountFilter") as? Int ?? 1
        _currentPlayCountFilter = State(initialValue: filter)
    }

    var body: some View {
        NavigationView {
            List {
                // User section
                Section {
                    Button(action: {
                        showingUsernameChangeSheet = true
                    }) {
                        HStack {
                            Text("Username")
                                .font(.scaledBody())
                                .foregroundColor(.primaryText)

                            Spacer()

                            Text(currentUser?.username ?? "Not set")
                                .font(.scaledBody())
                                .foregroundColor(.accent)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("user")
                        .font(.sectionHeader)
                        .foregroundColor(.tertiaryText)
                        .textCase(.lowercase)
                }

                // Play count filter section
                Section {
                    Button(action: {
                        cyclePlayCountFilter()
                    }) {
                        HStack {
                            Text("Play count filter")
                                .font(.scaledBody())
                                .foregroundColor(.primaryText)

                            Spacer()

                            Text(playCountFilterString)
                                .font(.scaledBody())
                                .foregroundColor(.accent)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("play count filter")
                        .font(.sectionHeader)
                        .foregroundColor(.tertiaryText)
                        .textCase(.lowercase)
                }

                // Support section
                Section {
                    Button("Report an issue") {
                        reportIssue()
                    }
                    .foregroundColor(.primaryText)

                    Button("Rate on App Store") {
                        rateOnAppStore()
                    }
                    .foregroundColor(.primaryText)

                    Button("Licenses") {
                        viewLicenses()
                    }
                    .foregroundColor(.primaryText)
                } header: {
                    Text("support")
                        .font(.sectionHeader)
                        .foregroundColor(.tertiaryText)
                        .textCase(.lowercase)
                }

                // About section
                Section {
                    Button("twocentstudios.com") {
                        openDeveloperWebsite()
                    }
                    .foregroundColor(.primaryText)

                    Button("@twocentstudios") {
                        openDeveloperTwitter()
                    }
                    .foregroundColor(.primaryText)
                } header: {
                    Text("about")
                        .font(.sectionHeader)
                        .foregroundColor(.tertiaryText)
                        .textCase(.lowercase)
                }

                // Data source section
                Section {
                    Button("last.fm") {
                        openLastFMWebsite()
                    }
                    .foregroundColor(.primaryText)
                } header: {
                    Text("artist & album data")
                        .font(.sectionHeader)
                        .foregroundColor(.tertiaryText)
                        .textCase(.lowercase)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.accent)
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView(result: $mailResult)
        }
        .sheet(isPresented: $showingUsernameChangeSheet) {
            UsernameChangeSheet()
        }
        .onAppear {
            // Sync with current environment value
            currentPlayCountFilter = playCountFilter
        }
    }

    // MARK: - Private Methods

    private var playCountFilterString: String {
        switch currentPlayCountFilter {
        case 0:
            "off"
        case 1:
            "1 play"
        default:
            "\(currentPlayCountFilter) plays"
        }
    }

    private func cyclePlayCountFilter() {
        if currentPlayCountFilter > 31 {
            currentPlayCountFilter = 0
        } else if currentPlayCountFilter == 0 {
            currentPlayCountFilter = 1
        } else {
            currentPlayCountFilter *= 2
        }

        // Save to UserDefaults
        UserDefaults.standard.set(currentPlayCountFilter, forKey: "currentPlayCountFilter")
    }

    private func reportIssue() {
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        }
    }

    private func rateOnAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/id617471119?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    private func viewLicenses() {
        // This would open a licenses view - for now just a placeholder
        // In a real app, you'd present a web view or dedicated licenses view
    }

    private func openDeveloperWebsite() {
        if let url = URL(string: "https://twocentstudios.com") {
            UIApplication.shared.open(url)
        }
    }

    private func openDeveloperTwitter() {
        if let url = URL(string: "https://twitter.com/twocentstudios") {
            UIApplication.shared.open(url)
        }
    }

    private func openLastFMWebsite() {
        if let url = URL(string: "https://last.fm") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.presentationMode) var presentation

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(["support@twocentstudios.com"])
        mailComposer.setSubject("vinylogue: Support Request")

        // Add debug info
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion

        let messageBody = """




        -------------------
        DEBUG INFO:
        App Version: \(appVersion)
        App Build: \(buildNumber)
        Device: \(deviceModel)
        OS Version: \(systemVersion)
        """

        mailComposer.setMessageBody(messageBody, isHTML: false)

        return mailComposer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView

        init(_ parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.presentation.wrappedValue.dismiss()
        }
    }
}

// MARK: - Username Change Sheet

struct UsernameChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.lastFMClient) private var lastFMClient
    @Environment(\.currentUser) private var currentUser

    @State private var newUsername = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var isValid = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Change Username")
                        .font(.scaledTitle3())
                        .foregroundColor(.primaryText)

                    Text("Enter your Last.fm username to continue")
                        .font(.scaledBody())
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    TextField("Username", text: $newUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.scaledBody())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onSubmit {
                            validateUsername()
                        }

                    if let error = validationError {
                        Text(error)
                            .font(.scaledCaption())
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 24)

                if isValidating {
                    ProgressView("Validating...")
                        .font(.scaledBody())
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        saveUsername()
                    }) {
                        Text("Save Username")
                            .font(.scaledBody())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(isValid ? Color.accent : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isValid || isValidating)
                    .padding(.horizontal, 24)

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.scaledBody())
                    .foregroundColor(.accent)
                }
                .padding(.bottom, 32)
            }
            .background(Color.primaryBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            newUsername = currentUser?.username ?? ""
        }
        .onChange(of: newUsername) { _ in
            if newUsername != currentUser?.username {
                validateUsername()
            } else {
                isValid = false
                validationError = nil
            }
        }
    }

    private func validateUsername() {
        guard !newUsername.isEmpty else {
            isValid = false
            validationError = nil
            return
        }

        guard newUsername != currentUser?.username else {
            isValid = false
            validationError = nil
            return
        }

        isValidating = true
        validationError = nil

        Task {
            do {
                let _: UserInfoResponse = try await lastFMClient.request(.userInfo(username: newUsername))
                await MainActor.run {
                    isValid = true
                    validationError = nil
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    isValid = false
                    validationError = "User not found or invalid username"
                    isValidating = false
                }
            }
        }
    }

    private func saveUsername() {
        guard isValid else { return }

        // Save to UserDefaults
        UserDefaults.standard.set(newUsername, forKey: "currentUser")

        // Clear friends list since we're changing users
        UserDefaults.standard.removeObject(forKey: "curatedFriends")

        dismiss()
    }
}

// MARK: - Previews

#Preview {
    SettingsSheet()
        .environment(\.playCountFilter, 4)
        .environment(\.currentUser, User(username: "ybsc", realName: "Christopher", imageURL: nil, url: nil, playCount: 1500))
}
