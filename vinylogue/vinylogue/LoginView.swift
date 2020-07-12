import SwiftUI

private struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(.avnDemiBold(60))
            .foregroundColor(Color(.secondaryLabel))
            .minimumScaleFactor(0.4)
    }
}

struct LoginView: View {
    @Binding var userName: String
    @State var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Text("welcome to vinylogue")
                .font(.avnUltraLight(30))
                .padding(.all, 30)
            HStack {
                if !isLoading {
                    Text("♫")
                        .font(.avnDemiBold(50))
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    RecordLoadingView()
                        .padding(.all, 4)
                }
                TextField("username", text: $userName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .disabled(isLoading)
            }
            .padding(.horizontal, 10)
            .background(Color(.secondarySystemBackgroundColor))
            Text(!isLoading ? "enter your last.fm username (ex. ybsc)" : "validating username...")
                .font(.avnUltraLight(17))
                .multilineTextAlignment(.center)
            Button {} label: {
                Text("start")
                    .font(.avnDemiBold(30))
                    .saturation(!isLoading ? 1.0 : 0.0)
            }
            .disabled(isLoading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(userName: .constant("name"))
            LoginView(userName: .constant("name"))
                .preferredColorScheme(.dark)
        }
    }
}
