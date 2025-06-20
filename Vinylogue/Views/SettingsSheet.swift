import Dependencies
import MessageUI
import Sharing
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = SettingsStore()

    @Shared(.currentUser) var currentUsername: String?

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
                            title: store.playCountFilterString,
                            action: { store.cyclePlayCountFilter() }
                        )
                        .animation(.default, value: store.playCountFilterString)
                        .contentTransition(.numericText(countsDown: false))
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
    @State private var store = UsernameChangeStore()

    @Shared(.currentUser) var currentUsername: String?

    @FocusState private var isTextFieldFocused: Bool

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
                    LastFMUsernameInputView(
                        username: $store.newUsername,
                        isValidating: $store.isValidating,
                        accessibilityHint: "Enter your Last.fm username to change",
                        onSubmit: {
                            Task { await validateAndSave() }
                        }
                    )
                    .focused($isTextFieldFocused)

                    LoadingButton(
                        title: "save username",
                        loadingTitle: "validating...",
                        isLoading: store.isValidating,
                        isDisabled: !store.canSave,
                        accessibilityLabel: store.isValidating ? "Validating username" : "Save username",
                        accessibilityHint: "Validates your username and updates the app",
                        action: {
                            Task { await validateAndSave() }
                        }
                    )
                    .sensoryFeedback(.success, trigger: currentUsername)
                }

                Spacer()
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }
            }
        }
        .onAppear {
            store.prepareForEntry()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .alert("Username Validation", isPresented: $store.showError) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            if let errorMessage = store.validationError {
                Text(errorMessage)
            }
        }
    }

    private func validateAndSave() async {
        if await store.validateAndSave() {
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview {
    SettingsSheet()
}
