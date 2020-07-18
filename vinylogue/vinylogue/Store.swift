import Combine
import ComposableArchitecture
import SwiftUI

typealias Username = String
struct User: Equatable, Codable {
    let me: Username
    var friends: [Username]
    var settings: Settings

    static func new(me: Username) -> Self {
        User(me: me, friends: [], settings: .default)
    }
}

struct Settings: Equatable, Codable {
    enum PlayCountFilter: String, Equatable, Codable {
        case off
        case p1
        case p2
        case p4
        case p8
        case p16
    }

    let playCountFilter: PlayCountFilter

    static let `default` = Self(playCountFilter: .off)
}

enum AppViewState: Equatable {
    case startup
    case login(LoginState)
    case favoriteUsers(FavoriteUsersState)
}

struct AppState: Equatable {
    var userState: UserState

    var viewState: AppViewState

    var loginState: LoginState? {
        get {
            guard case let .login(state) = viewState else { return nil }
            return state
        }
        set {
            if let value = newValue,
                case .login = viewState {
                viewState = .login(value)
            }
        }
    }

    var favoriteUsersState: FavoriteUsersState? {
        get {
            guard case let .favoriteUsers(state) = viewState else { return nil }
            return state
        }
        set {
            guard case var .loggedIn(user) = userState,
                case .favoriteUsers = viewState,
                let state = newValue else { return }

            // favoriteUsers is only allowed to modify settings or friends
            user.friends = state.user.friends
            user.settings = state.user.settings

            userState = .loggedIn(user)
            viewState = .favoriteUsers(state)
        }
    }
}

enum UserState: Equatable {
    case uninitialized
    case loggedOut
    case loggedIn(User)
}

enum AppAction: Equatable {
    case loadUserFromDisk
    case logOut
    case login(LoginAction)
    case favoriteUsers(FavoriteUsersAction)
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var lastFMClient: LastFMClient
    var loadUserFromDisk: () -> User?
    var saveUserToDisk: (User?) -> ()
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    loginReducer.optional.pullback(
        state: \.loginState,
        action: /AppAction.login,
        environment: LoginEnvironment.init
    ),
    favoriteUsersReducer.optional.pullback(
        state: \.favoriteUsersState,
        action: /AppAction.favoriteUsers,
        environment: FavoriteUsersEnvironment.init
    ),
    Reducer { state, action, environment in
        switch action {
        case .loadUserFromDisk:
            if let user = environment.loadUserFromDisk() {
                state.userState = .loggedIn(user)
                state.viewState = .favoriteUsers(.init(user: user))
            } else {
                state.userState = .loggedOut
                state.viewState = .login(.empty)
            }
            return .none

        case .logOut:
            state.userState = .loggedOut
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

        case .favoriteUsers:
            // TODO:
            return .none
        }
    }
)

struct LastFMClient {
    let verifyUsername: (String) -> Effect<Username, LoginError>
    let friendsForUsername: (Username) -> Effect<[Username], FavoriteUsersError>
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
            return Effect(value: LoginAction.logIn(User.new(me: username)))
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
        loadUserFromDisk: { User.new(me: "ybsc") },
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
        verifyUsername: { username in Effect(value: username) },
        friendsForUsername: { username in Effect(value: []) }
    )
}

struct FavoriteUsersState: Equatable {
    var user: User
    var editMode: EditMode = .inactive
    var isLoadingFriends: Bool = false
}

enum FavoriteUsersAction: Equatable {
    case editModeChanged(EditMode)
    case deleteFriend(IndexSet)
    case moveFriend(IndexSet, Int)
    case importLastFMFriends
    case importLastFMFriendsResponse(Result<[Username], FavoriteUsersError>)
    case didTapMe
//    case didTapSettings
//    case didTapFriend
//    case showCharts(Username)
    case logOut
}

struct FavoriteUsersError: Error, Equatable {}
struct FavoriteUsersEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let friendsForUsername: (Username) -> Effect<[Username], FavoriteUsersError>
}

extension FavoriteUsersEnvironment {
    static let mock: Self = .init(.mockUser)

    init(_ environment: AppEnvironment) {
        mainQueue = environment.mainQueue
        friendsForUsername = environment.lastFMClient.friendsForUsername
    }
}

let favoriteUsersReducer = Reducer<FavoriteUsersState, FavoriteUsersAction, FavoriteUsersEnvironment> { state, action, environment in
    switch action {
    case let .editModeChanged(editMode):
        state.editMode = editMode
        return .none

    case let .deleteFriend(indexSet):
        guard state.editMode != .inactive,
            !state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        state.user.friends.remove(atOffsets: indexSet)
        return .none

    case let .moveFriend(source, destination):
        guard state.editMode != .inactive,
            !state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        state.user.friends.move(fromOffsets: source, toOffset: destination)
        return .none

    case .importLastFMFriends:
        guard state.editMode != .inactive,
            !state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        state.isLoadingFriends = true
        return environment.friendsForUsername(state.user.me)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(FavoriteUsersAction.importLastFMFriendsResponse)

    case let .importLastFMFriendsResponse(result):
        guard state.editMode != .inactive,
            state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        state.isLoadingFriends = false
        switch result {
        case let .success(friends):
            var friendsToAdd = friends
            friendsToAdd.removeAll(where: { state.user.friends.contains($0) })
            state.user.friends.append(contentsOf: friendsToAdd)
        case let .failure(error):
            // TODO: surface error
            break
        }
        return .none

    case .didTapMe:
        guard !state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
        if state.editMode == .inactive {
            // open charts
            return .none
        } else {
            return Effect(value: .logOut)
        }

    case .logOut:
        return .none
    }
}
