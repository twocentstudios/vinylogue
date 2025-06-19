import SwiftUI

struct ErrorStateView: View {
    let error: LastFMError

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.vinylogueBlueDark)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.f(.medium, .title2))
                    .foregroundColor(.primaryText)

                Text(error.localizedDescription)
                    .font(.f(.regular, .body))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }
}

#Preview {
    VStack(spacing: 40) {
        ErrorStateView(error: .networkUnavailable)
        ErrorStateView(error: .userNotFound)
        ErrorStateView(error: .invalidResponse)
    }
    .background(Color.primaryBackground)
}
