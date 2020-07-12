import Combine
import ComposableArchitecture

typealias Username = String
struct User: Equatable {
    let me: Username
    var friends: [Username]
    var settings: Bool = false // TODO:
}

struct UnverifiedUser: Equatable {
    let me: Username
}

struct AppState: Equatable {
    var userState: UserState
}

enum UserState: Equatable {
    case uninitialized
    case loggedOut(LoginState)
    case loggedIn(User)
}

enum AppAction: Equatable {
    case loadUserFromDisk
    case logOut
    case login(LoginAction)
    case updateFriends([Username])
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var lastFMClient: LastFMClient
    var loadUserFromDisk: () -> User?
    var saveUserToDisk: (User?) -> ()
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    Reducer { state, action, environment in
        switch action {
        case .loadUserFromDisk:
            if let user = environment.loadUserFromDisk() {
                state.userState = .loggedIn(user)
            } else {
                state.userState = .loggedOut(.empty)
            }
            return .none

        case .logOut:
            state.userState = .loggedOut(.empty)
            return Effect.fireAndForget {
                environment.saveUserToDisk(nil)
            }

        case let .login(.logIn(user)):
            state.userState = .loggedIn(user)
            return Effect.fireAndForget {
                environment.saveUserToDisk(user)
            }

        case .login:
            return .none

        case let .updateFriends(friends):
            guard case let .loggedIn(user) = state.userState else {
                assertionFailure()
                return .none
            }
            state.userState = .loggedIn(user)
            return Effect.fireAndForget {
                environment.saveUserToDisk(user)
            }
        }
    },
    loginReducer.pullback(
        state: \.userState,
        action: /AppAction.login,
        environment: LoginEnvironment.init
    )
)

struct LastFMClient {
    let verifyUsername: (String) -> Effect<Username, LoginError>
}

enum LoginState: Equatable {
    case input(String)
    case verifying(String)
    case verified(Username)

    static let empty = Self.input("")
}

enum LoginAction: Equatable {
    case textFieldChanged(String)
    case startButtonTapped
    case verificationResponse(Result<Username, LoginError>)
    case logIn(User)
}

struct LoginError: Error, Equatable {}

struct LoginEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let verifyUsername: (String) -> Effect<Username, LoginError>
}
// TODO: ComposableArchitecture limitation:
//       UserState should be LoginState once there's a way to pullback into an associated value
//       We could then removed .loggedOut(...) from all the state cases
let loginReducer = Reducer<UserState, LoginAction, LoginEnvironment> { state, action, environment in
    switch action {
    case let .textFieldChanged(text):
        guard case .loggedOut(.input) = state else { assertionFailure("Unexpected state"); return .none }
        state = .loggedOut(.input(text))
        return .none

    case .startButtonTapped:
        guard case let .loggedOut(.input(text)) = state else { assertionFailure("Unexpected state"); return .none }
        state = .loggedOut(.verifying(text))

        return environment.verifyUsername(text)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(LoginAction.verificationResponse)

    case let .verificationResponse(result):
        guard case let .loggedOut(.verifying(text)) = state else { assertionFailure("Unexpected state"); return .none }
        switch result {
        case let .success(username):
            state = .loggedOut(.verified(username))
            return Effect(value: LoginAction.logIn(User(me: username, friends: [])))
                .delay(for: .seconds(1.5), scheduler: environment.mainQueue)
                .eraseToEffect()

        case let .failure(error):
            // TODO: show error
            state = .loggedOut(.input(text))
            return .none
        }

    case .logIn:
        return .none
    }
}


extension AppEnvironment {
    static let mockUser = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFMClient: .mock,
        loadUserFromDisk: { User(me: "ybsc", friends: []) },
        saveUserToDisk: { _ in }
    )

    static let mockFirstTime = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFMClient: .mock,
        loadUserFromDisk: { nil },
        saveUserToDisk: { _ in }
    )
}

extension LoginEnvironment {
    static let mock: Self = .init(.mockUser)

    init(_ environment: AppEnvironment) {
        mainQueue = environment.mainQueue
        verifyUsername = environment.lastFMClient.verifyUsername
    }
}

extension LastFMClient {
    static let mock = LastFMClient(
        verifyUsername: { username in Effect(value: username) }
    )
}
