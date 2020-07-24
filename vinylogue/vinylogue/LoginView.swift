import ComposableArchitecture
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
    struct Model: Equatable {
        let userName: String
        let isLoading: Bool
    }

    let store: Store<LoginState, LoginAction>

    var body: some View {
        WithViewStore(self.store.scope(state: { $0.view })) { viewStore in
            VStack(spacing: 12) {
                Text("welcome to vinylogue")
                    .font(.avnUltraLight(30))
                    .padding(.all, 30)
                HStack {
                    if !viewStore.isLoading {
                        Text("♫")
                            .font(.avnDemiBold(50))
                            .foregroundColor(Color(.tertiaryLabel))
                    } else {
                        RecordLoadingView()
                            .padding(.all, 4)
                    }
                    TextField("username", text: viewStore.binding(get: { $0.userName }, send: { .textFieldChanged($0) }))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(CustomTextFieldStyle())
                        .disabled(viewStore.isLoading)
                }
                .padding(.horizontal, 10)
                .background(Color(.secondarySystemBackground))
                Text(!viewStore.isLoading ? "enter your last.fm username (ex. ybsc)" : "validating username...")
                    .font(.avnUltraLight(17))
                    .multilineTextAlignment(.center)
                Button {
                    viewStore.send(.startButtonTapped)
                } label: {
                    Text("start")
                        .font(.avnDemiBold(30))
                        .saturation(!viewStore.isLoading ? 1.0 : 0.0)
                }
                .disabled(viewStore.isLoading)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var store: Store<LoginState, LoginAction> = {
        Store(
            initialState: .empty,
            reducer: loginReducer,
            environment: .mockFirstTime
        )
    }()
    static var previews: some View {
        Group {
            LoginView(store: store)
            LoginView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}

extension LoginState {
    var view: LoginView.Model {
        switch self {
        case let .input(text):
            return .init(userName: text, isLoading: false)
        case let .verifying(text):
            return .init(userName: text, isLoading: true)
        case let .verified(text):
            // TODO: replace loading spinner with green check when complete
            return .init(userName: text, isLoading: true)
        }
    }
}
