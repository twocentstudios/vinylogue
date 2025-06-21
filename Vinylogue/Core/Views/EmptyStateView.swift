import SwiftUI

struct EmptyStateView: View {
    let username: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.vinylogueBlueDark)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text("No charts!")
                    .font(.f(.medium, .title2))
                    .foregroundColor(.primaryText)

                Text("Looks like \(username) didn't listen to\nmuch music this week.")
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
    EmptyStateView(username: "ybsc")
        .background(Color.primaryBackground)
}
