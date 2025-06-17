import SwiftUI

/// A reusable section header view that matches the Vinylogue design pattern
struct SectionHeaderView: View {
    let title: String
    let topPadding: CGFloat

    init(_ title: String, topPadding: CGFloat = 40) {
        self.title = title
        self.topPadding = topPadding
    }

    var body: some View {
        Text(title)
            .font(.sectionHeader)
            .foregroundColor(.tertiaryText)
            .textCase(.lowercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topPadding)
            .padding(.bottom, 0)
            .padding(.horizontal, 24)
    }
}

#Preview {
    VStack {
        SectionHeaderView("sample section")
        SectionHeaderView("another section", topPadding: 20)
    }
    .background(Color.primaryBackground)
}
