import SwiftUI

struct LastFMUsernameInputView: View {
    @Binding var username: String
    @Binding var isValidating: Bool
    @FocusState var isFocused: Bool

    let errorMessage: String?
    let showError: Bool
    let onSubmit: () -> Void
    let accessibilityHint: String

    init(
        username: Binding<String>,
        isValidating: Binding<Bool>,
        errorMessage: String? = nil,
        showError: Bool = false,
        accessibilityHint: String = "Enter your Last.fm username",
        onSubmit: @escaping () -> Void
    ) {
        _username = username
        _isValidating = isValidating
        self.errorMessage = errorMessage
        self.showError = showError
        self.accessibilityHint = accessibilityHint
        self.onSubmit = onSubmit
    }

    var body: some View {
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
                TextField("username", text: $username)
                    .foregroundStyle(Color.primaryText)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .minimumScaleFactor(0.7)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !username.isEmpty {
                    Button(action: { username = "" }) {
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
            .focused($isFocused)
            .onSubmit {
                onSubmit()
            }
            .accessibilityLabel("Last.fm username")
            .accessibilityHint(accessibilityHint)
            .padding(.bottom, 16)

            if let errorMessage, showError {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.destructive)
                    .font(.f(.regular, .caption1))
                    .padding(.horizontal)
            }
        }
    }
}
