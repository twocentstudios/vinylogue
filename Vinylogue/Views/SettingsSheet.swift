import Dependencies
import MessageUI
import Sharing
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Use @Shared directly instead of environment
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.appStorage("currentPlayCountFilter")) var playCountFilter: Int = 1

    @State private var showingMailComposer = false
    @State private var showingUsernamePicker = false
    @State private var showingUsernameChangeSheet = false
    @State private var showingLicenses = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    // Computed property for User object (for backward compatibility)
    private var currentUser: User? {
        guard let username = currentUsername else { return nil }
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Play count filter section
                    Section {
                        SettingsRowView(
                            title: playCountFilterString,
                            action: { cyclePlayCountFilter() }
                        )
                    } header: {
                        SectionHeaderView("play count filter")
                    }

                    // User section
                    Section {
                        SettingsRowView(
                            title: "change user",
                            action: { showingUsernameChangeSheet = true }
                        )
                    } header: {
                        SectionHeaderView("me")
                    }

                    // Support section
                    Section {
                        SettingsRowView(
                            title: "report an issue",
                            action: { reportIssue() }
                        )

                        SettingsRowView(
                            title: "rate on appstore",
                            action: { rateOnAppStore() }
                        )

                        SettingsRowView(
                            title: "licenses",
                            action: { viewLicenses() }
                        )
                    } header: {
                        SectionHeaderView("support")
                    }

                    // About section
                    Section {
                        SettingsRowView(
                            title: "twocentstudios.com",
                            action: { openDeveloperWebsite() }
                        )

                        SettingsRowView(
                            title: "@twocentstudios",
                            action: { openDeveloperTwitter() }
                        )
                    } header: {
                        SectionHeaderView("about")
                    }

                    // Data source section
                    Section {
                        SettingsRowView(
                            title: "last.fm",
                            action: { openLastFMWebsite() }
                        )
                    } header: {
                        SectionHeaderView("artist & album data")
                    }
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") {
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }

                ToolbarItem(placement: .principal) {
                    Text("settings")
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView(result: $mailResult)
        }
        .sheet(isPresented: $showingUsernameChangeSheet) {
            UsernameChangeSheet()
        }
        .sheet(isPresented: $showingLicenses) {
            LicensesView()
        }
    }

    // MARK: - Private Methods

    private var playCountFilterString: String {
        switch playCountFilter {
        case 0:
            "off"
        case 1:
            "1 play"
        default:
            "\(playCountFilter) plays"
        }
    }

    private func cyclePlayCountFilter() {
        $playCountFilter.withLock { filter in
            if filter > 31 {
                filter = 0
            } else if filter == 0 {
                filter = 1
            } else {
                filter *= 2
            }
        }
        // Automatic persistence via @Shared
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
        showingLicenses = true
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

// MARK: - Settings Row View

private struct SettingsRowView: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.f(.regular, .title2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
    }
}

struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .vinylogueWhiteSubtle : .primaryText)
            .background {
                Rectangle().fill(Color.vinylogueBlueDark.opacity(configuration.isPressed ? 1.0 : 0.0))
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

    class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let parent: MailComposerView

        init(_ parent: MailComposerView) {
            self.parent = parent
        }

        @MainActor
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
    @Dependency(\.lastFMClient) private var lastFMClient

    // Use @Shared directly
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @State private var newUsername = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var isValid = false

    // Computed property for User object (for backward compatibility)
    private var currentUser: User? {
        guard let username = currentUsername else { return nil }
        return User(
            username: username,
            realName: nil,
            imageURL: nil,
            url: nil,
            playCount: nil
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Change Username")
                        .font(.f(.regular, .title2))
                        .foregroundColor(.primaryText)

                    Text("Enter your Last.fm username to continue")
                        .font(.f(.medium, .body))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    TextField("Username", text: $newUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.f(.medium, .body))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onSubmit {
                            validateUsername()
                        }

                    if let error = validationError {
                        Text(error)
                            .font(.f(.regular, .caption1))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 24)

                if isValidating {
                    HStack {
                        AnimatedLoadingIndicator(size: 24)
                        Text("Validating...")
                            .font(.f(.medium, .body))
                    }
                    .foregroundColor(.secondaryText)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        saveUsername()
                    }) {
                        Text("Save Username")
                            .font(.f(.medium, .body))
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
                    .font(.f(.medium, .body))
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
        .onChange(of: newUsername) {
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

        // Save using @Shared - automatic persistence
        $currentUsername.withLock { $0 = newUsername }

        // Clear friends list since we're changing users
        $curatedFriends.withLock { $0 = [] }

        dismiss()
    }
}

// MARK: - Previews

#Preview {
    SettingsSheet()
}
