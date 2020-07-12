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
    case loggedOut
    case loggedIn(User)
}

enum AppAction: Equatable {
    case loadUserFromDisk
    case logOut
    case logInVerifiedUser(User)
    case updateFriends([Username])
}

struct AppEnvironment {
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
                state.userState = .loggedOut
            }
            return .none

        case .logOut:
            state.userState = .loggedOut
            return Effect.fireAndForget {
                environment.saveUserToDisk(nil)
            }

        case let .logInVerifiedUser(user):
            state.userState = .loggedIn(user)
            return Effect.fireAndForget {
                environment.saveUserToDisk(user)
            }

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
    }
)

let mockUserEnvironment = AppEnvironment(
    loadUserFromDisk: { User(me: "ybsc", friends: ["BobbyStompy"]) },
    saveUserToDisk: { _ in }
)

let mockFirstTimeEnvironment = AppEnvironment(
    loadUserFromDisk: { nil },
    saveUserToDisk: { _ in }
)
