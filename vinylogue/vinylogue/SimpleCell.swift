import SwiftUI

struct SimpleHeader: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.avnRegular(17))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

struct SimpleCell: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.avnRegular(24))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 3)
    }
}

struct LargeSimpleCell: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.avnRegular(34))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ButtonSimpleCell: View {
    let label: String
    let isDestructive: Bool
    let isLoading: Bool
    let action: () -> ()

    init(_ label: String, isDestructive: Bool = false, isLoading: Bool = false, action: @escaping () -> () = {}) {
        self.label = label
        self.isDestructive = isDestructive
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        // TODO: this button only extends to the width of the text
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                }
                Text(label)
                    .font(.avnRegular(24))
                    .padding(.vertical, 3)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(isDestructive ? Color(.systemRed) : .accentColor)
    }
}

struct SimpleHeader_Previews: PreviewProvider {
    static var previews: some View {
        SimpleHeader("me")
            .previewLayout(.sizeThatFits)
    }
}

struct SimpleCell_Previews: PreviewProvider {
    static var previews: some View {
        SimpleCell("ybsc")
            .previewLayout(.sizeThatFits)
    }
}

struct LargeSimpleCell_Previews: PreviewProvider {
    static var previews: some View {
        LargeSimpleCell("ybsc")
            .previewLayout(.sizeThatFits)
    }
}

struct ButtonSimpleCell_Previews: PreviewProvider {
    static var previews: some View {
        ButtonSimpleCell("import friends")
            .previewLayout(.sizeThatFits)
    }
}
