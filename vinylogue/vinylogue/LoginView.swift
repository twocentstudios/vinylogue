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
    struct State: Equatable {
        let userName: String
        let isLoading: Bool
    }

    // TODO: Composable architecture limitation
    // TODO: This should be LoginState instead of UserState
    let store: Store<UserState, LoginAction>

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
                        .textFieldStyle(CustomTextFieldStyle())
                        .disabled(viewStore.isLoading)
                }
                .padding(.horizontal, 10)
                .background(Color(.secondarySystemBackgroundColor))
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
    static var store: Store<UserState, LoginAction> = {
        Store(
            initialState: UserState.loggedOut(.empty),
            reducer: loginReducer,
            environment: .mock
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

// TODO: Composable architecture limitation
// TODO: This should be an extension on LoginState
extension UserState {
    var view: LoginView.State {
        switch self {
        case let .loggedOut(.input(text)):
            return .init(userName: text, isLoading: false)
        case let .loggedOut(.verifying(text)):
            return .init(userName: text, isLoading: true)
        case let .loggedOut(.verified(text)):
            // TODO: replace loading spinner with green check when complete
            return .init(userName: text, isLoading: true)
        case .loggedIn, .uninitialized:
            // TODO: This path gets called with .loggedIn... but should it?
//            assertionFailure("Unexpected state")
            return .init(userName: "", isLoading: false)
        }
    }
}
