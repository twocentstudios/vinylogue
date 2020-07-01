import SwiftUI

private struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(.avnDemiBold(60))
            .foregroundColor(.blueDark)
            .minimumScaleFactor(0.4)
    }
}

struct LoginView: View {
    @Binding var userName: String
    @State var isLoading: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            Text("welcome to vinylogue")
                .font(.avnUltraLight(30))
                .foregroundColor(.blueDark)
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, 30)
            HStack {
                if !isLoading {
                    Text("♫")
                        .font(.avnDemiBold(50))
                        .foregroundColor(.gray(160))
                } else {
                    ProgressView()
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                }
                TextField("username", text: $userName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.horizontal, 10)
            .background(Color.blacka(0.05))
            Text(!isLoading ? "enter your last.fm username (ex. ybsc)" : "validating username...")
                .font(.avnUltraLight(17))
                .foregroundColor(.gray(70))
                .multilineTextAlignment(.center)
            Button { } label: {
                Text("start")
                    .font(.avnDemiBold(30))
                    .foregroundColor(!isLoading ? .blueDark : .gray(160))
            }
            .disabled(isLoading)
            Spacer()
        }
    }
}
