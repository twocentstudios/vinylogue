import Dependencies
import MessageUI
import Sharing
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.appStorage("currentPlayCountFilter")) var playCountFilter: Int = 1

    @State private var showingMailComposer = false
    @State private var showingUsernamePicker = false
    @State private var showingUsernameChangeSheet = false
    @State private var showingLicenses = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    Section {
                        SettingsRowView(
                            title: playCountFilterString,
                            action: { cyclePlayCountFilter() }
                        )
                    } header: {
                        SectionHeaderView("play count filter")
                    }

                    Section {
                        SettingsRowView(
                            title: "change user",
                            action: { showingUsernameChangeSheet = true }
                        )
                    } header: {
                        SectionHeaderView("me")
                    }

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
                        .foregroundStyle(Color.vinylogueBlueDark)
                        .font(.f(.regular, .headline))
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
    @State private var buttonPressed = false

    var body: some View {
        Button(action: {
            buttonPressed.toggle()
            action()
        }) {
            Text(title)
                .font(.f(.regular, .title2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: buttonPressed)
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

    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Shared(.fileStorage(.curatedFriendsURL)) var curatedFriends: [User] = []

    @State private var newUsername = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var isValid = false
    @State private var showError = false

    @FocusState private var isTextFieldFocused: Bool

    private var canSave: Bool {
        !newUsername.isEmpty && newUsername != currentUsername
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("change username")
                    .font(.f(.regular, .largeTitle))
                    .tracking(2)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("a last.fm username")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.f(.ultralight, .headline))
                            .foregroundColor(.primaryText)
                            .padding(.horizontal)
                            .padding(.bottom, 0)

                        HStack(spacing: 0) {
                            Image(systemName: "music.note")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundStyle(Color.vinylogueGray)
                            TextField("username", text: $newUsername)
                                .foregroundStyle(Color.primaryText)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .minimumScaleFactor(0.7)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !newUsername.isEmpty {
                                Button(action: { newUsername = "" }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .font(.f(.demiBold, 40))
                                        .foregroundStyle(Color.primaryText.opacity(0.3))
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .font(.f(.demiBold, 60))
                        .background {
                            Color.vinylogueGray.opacity(0.4)
                        }
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            validateAndSaveUsername()
                        }
                        .accessibilityLabel("Last.fm username")
                        .accessibilityHint("Enter your Last.fm username to change")
                        .padding(.bottom, 16)
                    }

                    Button(action: validateAndSaveUsername) {
                        HStack {
                            if isValidating {
                                AnimatedLoadingIndicator(size: 20)
                            }

                            Text(isValidating ? "validating..." : "save username")
                                .font(.f(.regular, .body))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(submitButtonBackground)
                        .foregroundColor(isValidating ? .primaryText.opacity(0.6) : .vinylogueWhiteSubtle)
                    }
                    .disabled(!canSave || isValidating)
                    .sensoryFeedback(.success, trigger: currentUsername)
                    .accessibilityLabel(isValidating ? "Validating username" : "Save username")
                    .accessibilityHint("Validates your username and updates the app")
                }

                Spacer()

                Button("cancel") {
                    dismiss()
                }
                .font(.f(.medium, .body))
                .foregroundColor(.accent)
                .padding(.bottom, 32)
            }
            .background(Color.primaryBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            newUsername = currentUsername ?? ""
            isValid = false
            validationError = nil
            showError = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Username Validation", isPresented: $showError) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage = validationError {
                Text(errorMessage)
            }
        }
    }

    private var submitButtonBackground: Color {
        if !canSave || isValidating {
            .vinylogueGray
        } else {
            .accent
        }
    }

    private func validateAndSaveUsername() {
        guard canSave else { return }
        guard !newUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("please enter a username")
            return
        }

        let cleanUsername = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await validateUsername(cleanUsername)
        }
    }

    @MainActor
    private func validateUsername(_ username: String) async {
        isValidating = true
        validationError = nil
        showError = false

        do {
            let _: UserInfoResponse = try await lastFMClient.request(.userInfo(username: username))
            isValid = true
            validationError = nil
            isValidating = false
            saveUsername()
            dismiss()
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
        validationError = message
        showError = true

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func saveUsername() {
        $currentUsername.withLock { $0 = newUsername }
        $curatedFriends.withLock { $0 = [] }
    }
}

// MARK: - Previews

#Preview {
    SettingsSheet()
}
