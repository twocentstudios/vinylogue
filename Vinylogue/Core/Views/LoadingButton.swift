import SwiftUI

struct LoadingButton: View {
    let title: String
    let loadingTitle: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    let accessibilityLabel: String
    let accessibilityHint: String

    init(
        title: String,
        loadingTitle: String = "loading...",
        isLoading: Bool = false,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityHint: String = "",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.loadingTitle = loadingTitle
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel ?? (isLoading ? "Loading" : title)
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    private var submitButtonBackground: Color {
        if isDisabled || isLoading {
            .vinylogueGray.opacity(0.3)
        } else {
            .accent
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    AnimatedLoadingIndicator(size: 20)
                }

                Text(isLoading ? loadingTitle : title)
                    .font(.f(.regular, .body))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(submitButtonBackground)
            .foregroundColor(isLoading ? .primaryText.opacity(0.6) : .vinylogueWhiteSubtle)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}
