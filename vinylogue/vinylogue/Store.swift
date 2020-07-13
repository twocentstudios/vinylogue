import Combine
import ComposableArchitecture
import SwiftUI

typealias Username = String
struct User: Equatable, Codable {
    let me: Username
    var friends: [Username]
    var settings: Bool = false // TODO:

    var editMode: EditMode = .inactive
    var isLoadingFriends: Bool = false

    enum CodingKeys: CodingKey {
        case me
        case friends
        case settings
    }
}

struct AppState: Equatable {
    var userState: UserState
}

enum UserState: Equatable {
    case uninitialized
    case loggedOut(LoginState)
    case loggedIn(User)

    var loginState: LoginState? {
        get {
            guard case let .loggedOut(value) = self else { return nil }
            return value
        }
        set {
            if let value = newValue {
                self = .loggedOut(value)
            }
        }
    }
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
    loginReducer.optional.pullback(
        state: \.userState.loginState,
        action: /AppAction.login,
        environment: LoginEnvironment.init
    ),
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
    }
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

let loginReducer = Reducer<LoginState, LoginAction, LoginEnvironment> { state, action, environment in
    switch action {
    case let .textFieldChanged(text):
        guard case .input = state else { assertionFailure("Unexpected state"); return .none }
        state = .input(text)
        return .none

    case .startButtonTapped:
        guard case let .input(text) = state else { assertionFailure("Unexpected state"); return .none }
        state = .verifying(text)

        return environment.verifyUsername(text)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(LoginAction.verificationResponse)

    case let .verificationResponse(result):
        guard case let .verifying(text) = state else { assertionFailure("Unexpected state"); return .none }
        switch result {
        case let .success(username):
            state = .verified(username)
            return Effect(value: LoginAction.logIn(User(me: username, friends: [])))
                .delay(for: .seconds(1.5), scheduler: environment.mainQueue)
                .eraseToEffect()

        case let .failure(error):
            // TODO: show error
            state = .input(text)
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

enum FavoriteUsersAction: Equatable {
    case editModeChanged(EditMode)
    case deleteFriend(IndexSet)
    case moveFriend(IndexSet, Int)
    case importLastFMFriends
    case importLastFMFriendsResponse(Result<[Username], FavoriteUsersError>)
    case didTapMe
    case logOut
}

struct FavoriteUsersError: Error, Equatable {}
struct FavoriteUsersEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let friendsForUsername: (Username) -> Effect<[Username], FavoriteUsersError>
}

// TODO: ComposableArchitecture limitation:
//       UserState should be FavoriteUsersState once there's a way to pullback into an associated value
//       We could then removed .loggedIn(...) from all the state cases
let favoriteUsersReducer = Reducer<UserState, FavoriteUsersAction, FavoriteUsersEnvironment> { state, action, environment in
    switch action {
    case let .editModeChanged(editMode):
        guard case var .loggedIn(user) = state else { assertionFailure("Unexpected state"); return .none }
        user.editMode = editMode
        state = .loggedIn(user) // TODO: is this needed?
        return .none

    case let .deleteFriend(indexSet):
        guard case var .loggedIn(user) = state else { assertionFailure("Unexpected state"); return .none }
        guard user.editMode != .inactive,
            !user.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        user.friends.remove(atOffsets: indexSet)
        state = .loggedIn(user) // TODO: is this needed?
        return .none

    case let .moveFriend(source, destination):
        guard case var .loggedIn(user) = state else { assertionFailure("Unexpected state"); return .none }
        guard user.editMode != .inactive,
            !user.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        user.friends.move(fromOffsets: source, toOffset: destination)
        state = .loggedIn(user) // TODO: is this needed?
        return .none

    case .importLastFMFriends:
        guard case var .loggedIn(user) = state else { assertionFailure("Unexpected state"); return .none }
        guard user.editMode != .inactive,
            !user.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        user.isLoadingFriends = true
        return environment.friendsForUsername(user.me)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(FavoriteUsersAction.importLastFMFriendsResponse)

    case let .importLastFMFriendsResponse(result):
        guard case var .loggedIn(user) = state else { assertionFailure("Unexpected state"); return .none }
        guard user.editMode != .inactive,
            user.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        user.isLoadingFriends = false
        switch result {
        case let .success(friends):
            var friendsToAdd = friends
            friendsToAdd.removeAll(where: { user.friends.contains($0) })
            user.friends.append(contentsOf: friendsToAdd)
            state = .loggedIn(user) // TODO: is this needed?
        case let .failure(error):
            // TODO: surface error
            break
        }
        return .none

    case .didTapMe:
        guard case var .loggedIn(user) = state else { assertionFailure("Unexpected state"); return .none }
        guard !user.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        if user.editMode == .inactive {
            // open charts
            return .none
        } else {
            return Effect(value: .logOut)
        }

    case .logOut:
        return .none
    }
}
