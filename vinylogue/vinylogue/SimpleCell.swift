import SwiftUI

struct SimpleHeader: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.avnUltraLight(17))
                .foregroundColor(.blueDark)
                .padding(.leading, 20)
                .padding(.top, 20)
            Spacer()
        }
    }
}

struct SimpleCell: View {
    let label: String
    let action: () -> ()

    init(_ label: String, action: @escaping () -> () = {}) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.avnRegular(24))
                    .padding(.leading, 20)
                    .padding(.vertical, 6)
                Spacer()
            }
        }
        .buttonStyle(SimpleCellButtonStyle())
    }
}

struct LargeSimpleCell: View {
    let label: String
    let action: () -> ()

    init(_ label: String, action: @escaping () -> () = {}) {
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.avnRegular(34))
                    .padding(.leading, 20)
                Spacer()
            }
        }
        .buttonStyle(SimpleCellButtonStyle())
    }
}

private struct SimpleCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(!configuration.isPressed ? Color.blueDark : Color.whiteSubtle)
            .background(!configuration.isPressed ? Color.whiteSubtle : Color.blueDark)
    }
}
