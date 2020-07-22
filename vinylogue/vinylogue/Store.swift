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

extension User {
    static let mock = Self(me: "ybsc", friends: ["BobbyStompy", "slippydrums"], settings: .default)
}

struct Settings: Equatable, Codable {
    enum PlayCountFilter: String, Equatable, CaseIterable, Codable {
        case off
        case p1
        case p2
        case p4
        case p8
        case p16
    }

    var playCountFilter: PlayCountFilter

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
            guard case let .loggedIn(user) = userState,
                case let .favoriteUsers(state) = viewState else { return nil }
            return .init(user: user, editMode: state.editMode, isLoadingFriends: state.isLoadingFriends, viewState: state.viewState)
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
        environment: { $0 }
    ),
    favoriteUsersReducer.optional.pullback(
        state: \.favoriteUsersState,
        action: /AppAction.favoriteUsers,
        environment: { $0 }
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
            state.viewState = .login(.empty)
            return Effect.fireAndForget {
                environment.saveUserToDisk(nil)
            }

        case let .login(.logIn(user)):
            state.userState = .loggedIn(user)
            state.viewState = .favoriteUsers(.init(user: user))
            return Effect.fireAndForget {
                environment.saveUserToDisk(user)
            }

        case .login:
            return .none

        case .favoriteUsers(.logOut):
            return Effect(value: .logOut)

        case .favoriteUsers:
            // TODO:
            return .none
        }
    }
)

enum LoginState: Equatable {
    case input(String)
    case verifying(String)
    case verified(Username)

    static let empty = Self.input("")
}

enum LoginAction: Equatable {
    case textFieldChanged(String)
    case startButtonTapped
    case verificationResponse(Result<Username, LastFMClient.Error>)
    case logIn(User)
}

struct LoginError: Error, Equatable {}

let loginReducer = Reducer<LoginState, LoginAction, AppEnvironment> { state, action, environment in
    switch action {
    case let .textFieldChanged(text):
        guard case .input = state else { assertionFailure("Unexpected state"); return .none }
        state = .input(text)
        return .none

    case .startButtonTapped:
        guard case let .input(text) = state else { assertionFailure("Unexpected state"); return .none }
        state = .verifying(text)

        return environment.lastFMClient.verifyUsername(text)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(LoginAction.verificationResponse)

    case let .verificationResponse(result):
        guard case let .verifying(text) = state else { assertionFailure("Unexpected state"); return .none }
        switch result {
        case let .success(username):
            state = .verified(username)
            return Effect(value: LoginAction.logIn(User.new(me: username)))

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
    static let live = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFMClient: .live,
        loadUserFromDisk: { nil },
        saveUserToDisk: { _ in }
    )

    static let mockUser = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFMClient: .mock,
        loadUserFromDisk: { User.mock },
        saveUserToDisk: { _ in }
    )

    static let mockFirstTime = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFMClient: .mock,
        loadUserFromDisk: { nil },
        saveUserToDisk: { _ in }
    )
}

struct FavoriteUsersState: Equatable {
    var user: User
    var editMode: EditMode = .inactive
    var isLoadingFriends: Bool = false

    enum ViewState: Equatable {
        case settings(SettingsState)
        case weeklyAlbumChart(WeeklyAlbumChartState)
    }

    var viewState: ViewState?

    var settingsState: SettingsState? {
        get {
            guard case .settings = viewState else { return nil }
            return .init(user: user)
        }
        set {
            guard case .settings = viewState,
                let newState = newValue else { return }

            // settingsState is only allowed to modify settings.
            user.settings = newState.user.settings
        }
    }

    var weeklyAlbumChartState: WeeklyAlbumChartState? {
        get {
            // TODO:
            guard case let .weeklyAlbumChart(state) = viewState else { return nil }
            return .init(username: state.username, now: state.now, playCountFilter: user.settings.playCountFilter)
        }
        set {
            // TODO:
            guard case .weeklyAlbumChart = viewState,
                let _ = newValue else { return }
        }
    }
}

enum FavoriteUsersAction: Equatable {
    case editModeChanged(EditMode)
    case deleteFriend(IndexSet)
    case moveFriend(IndexSet, Int)
    case importLastFMFriends
    case importLastFMFriendsResponse(Result<[Username], LastFMClient.Error>)
    case setFriendWeeklyAlbumChartView(isActive: Bool, username: Username)
    case setMeWeeklyAlbumChartView(isActive: Bool)
    case setWeeklyAlbumChartView(isActive: Bool, username: Username)
    case weeklyAlbumChart(WeeklyAlbumChartAction)
    case setSettingsView(isActive: Bool)
    case settings(SettingsAction)
    case logOut
}

struct FavoriteUsersError: Error, Equatable {}

let favoriteUsersReducer = Reducer<FavoriteUsersState, FavoriteUsersAction, AppEnvironment>.combine(
    settingsReducer.optional.pullback(
        state: \.settingsState,
        action: /FavoriteUsersAction.settings,
        environment: { $0 }
    ),
    Reducer { state, action, environment in
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
            return environment.lastFMClient.friendsForUsername(state.user.me)
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

        case let .setMeWeeklyAlbumChartView(isActive):
            return Effect(value: .setWeeklyAlbumChartView(isActive: isActive, username: state.user.me))

        case let .setFriendWeeklyAlbumChartView(isActive, username):
            return Effect(value: .setWeeklyAlbumChartView(isActive: isActive, username: username))

        case let .setWeeklyAlbumChartView(isActive: true, username):
            guard !state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
            state.viewState = .weeklyAlbumChart(.init(username: username, now: Date(), playCountFilter: .off)) // TODO real values from state/env
            return .none

        case .setWeeklyAlbumChartView(isActive: false, _):
            // TODO: this action is sent twice in a row (I don't know why), which asserts the line below.
            // guard case .weeklyAlbumChart = state.viewState else { assertionFailure("Unexpected state"); return .none }
            state.viewState = nil
            return .none

        case .weeklyAlbumChart:
            return .none

        case .setSettingsView(isActive: true):
            guard !state.isLoadingFriends else { assertionFailure("Unexpected state"); return .none }
            state.viewState = .settings(SettingsState(user: state.user))
            return .none

        case .setSettingsView(isActive: false):
            // TODO: this action is sent twice in a row (I don't know why), which asserts the line below.
            // guard case .settings = state.viewState else { assertionFailure("Unexpected state"); return .none }
            state.viewState = nil
            return .none

        case .settings:
            return .none

        case .logOut:
            return .none
        }
    }
)

struct SettingsState: Equatable {
    var user: User
}
enum SettingsAction: Equatable {
    case updatePlayCountFilter
}

let settingsReducer = Reducer<SettingsState, SettingsAction, AppEnvironment> { state, action, environment in
    switch action {
    case .updatePlayCountFilter:
        let cases = Settings.PlayCountFilter.allCases + Settings.PlayCountFilter.allCases
        let nextIndex = cases.firstIndex(of: state.user.settings.playCountFilter)! + 1
        let newCase = cases[nextIndex]
        state.user.settings.playCountFilter = newCase
        return .none
    }
}

struct WeeklyAlbumChartState: Equatable {
    enum WeeklyChartListState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.WeeklyChartList) // TODO: cache this on disk
        case failed(LastFMClient.Error)
    }

    enum WeeklyAlbumChartState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.WeeklyAlbumCharts)
        case failed(LastFMClient.Error)
    }

    enum AlbumState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.Album)
        case failed(LastFMClient.Error)
    }

    enum ImageState: Equatable {
        case initialized
        case loading
        case loaded(UIImage)
        case failed
    }

    private var displayingDates: [Date] {
        fatalError()
    }

    var displayingChartRanges: [LastFM.WeeklyChartRange] {
        fatalError()
    }

    let username: Username
    let now: Date
    let playCountFilter: Settings.PlayCountFilter

    var weeklyChartListState: WeeklyChartListState
    var weeklyCharts: [LastFM.WeeklyChartRange: WeeklyAlbumChartState]
    var albums: [LastFM.WeeklyAlbumChartStub: AlbumState]
    var albumImageThumbnails: [LastFM.Album: ImageState]
}

extension WeeklyAlbumChartState {
    init(username: Username, now: Date, playCountFilter: Settings.PlayCountFilter) {
        self.username = username
        self.now = now
        self.playCountFilter = playCountFilter

        weeklyChartListState = .initialized
        weeklyCharts = [:]
        albums = [:]
        albumImageThumbnails = [:]
    }
}

enum WeeklyAlbumChartAction: Equatable {
    case fetchWeeklyChartList
    case fetchWeeklyChartListResponse(Result<LastFM.WeeklyChartList, LastFMClient.Error>)
    case fetchWeeklyAlbumChart(LastFM.WeeklyChartRange)
    case fetchWeeklyAlbumChartResponse(LastFM.WeeklyChartRange, Result<LastFM.WeeklyAlbumCharts, LastFMClient.Error>)
    case fetchAlbum(LastFM.WeeklyAlbumChartStub)
    case fetchAlbumResponse(LastFM.WeeklyAlbumChartStub, Result<LastFM.Album, LastFMClient.Error>)
    case fetchImageThumbnail(LastFM.Album)
    case fetchImageThumbnailResponse(LastFM.Album, Result<LastFM.Album, LastFMClient.Error>)
    case setAlbumDetailView(isActive: Bool, LastFM.WeeklyAlbumChartStub)
}

let weeklyAlbumChartReducer = Reducer<WeeklyAlbumChartState, WeeklyAlbumChartAction, AppEnvironment>.combine(
//    settingsReducer.optional.pullback(
//        state: \.settingsState,
//        action: /FavoriteUsersAction.settings,
//        environment: { $0 }
//    ),
    Reducer { state, action, environment in
        switch action {
        case .fetchWeeklyChartList:
            switch state.weeklyChartListState {
            case .initialized, .failed: break
            case .loading, .loaded: assertionFailure("Unexpected state"); return .none
            }
            state.weeklyChartListState = .loading
            return environment.lastFMClient.weeklyChartList(state.username)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(WeeklyAlbumChartAction.fetchWeeklyChartListResponse)

        case let .fetchWeeklyChartListResponse(result):
            guard case .loading = state.weeklyChartListState else { assertionFailure("Unexpected state"); return .none }
            switch result {
            case let .success(value): state.weeklyChartListState = .loaded(value)
            case let .failure(error): state.weeklyChartListState = .failed(error)
            }
            return .none

        case let .fetchWeeklyAlbumChart(chartRange):
            switch state.weeklyCharts[chartRange] {
            case .none, .initialized?, .failed?: break
            case .loading?, .loaded?: assertionFailure("Unexpected state"); return .none
            }
            state.weeklyCharts[chartRange] = .loading
            return environment.lastFMClient.weeklyAlbumChart(state.username, chartRange)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { WeeklyAlbumChartAction.fetchWeeklyAlbumChartResponse(chartRange, $0) }

        case let .fetchWeeklyAlbumChartResponse(chartRange, result):
            guard case .loading? = state.weeklyCharts[chartRange] else { assertionFailure("Unexpected state"); return .none }
            switch result {
            case let .success(value): state.weeklyCharts[chartRange] = .loaded(value)
            case let .failure(error): state.weeklyCharts[chartRange] = .failed(error)
            }
            return .none // TODO: consider prefetching logic for albums and thumbnails

        case let .fetchAlbum(albumChartStub):
            switch state.albums[albumChartStub] {
            case .none, .initialized?, .failed?: break
            case .loading?, .loaded?: assertionFailure("Unexpected state"); return .none
            }
            state.albums[albumChartStub] = .loading
            return environment.lastFMClient.album(state.username, albumChartStub.artist, albumChartStub.album)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { WeeklyAlbumChartAction.fetchAlbumResponse(albumChartStub, $0) }

        case let .fetchAlbumResponse(albumChartStub, result):
            guard case .loading? = state.albums[albumChartStub] else { assertionFailure("Unexpected state"); return .none }
            switch result {
            case let .success(value): state.albums[albumChartStub] = .loaded(value)
            case let .failure(error): state.albums[albumChartStub] = .failed(error)
            }
            return .none

        case let .fetchImageThumbnail(album):
            return .none
        case let .fetchImageThumbnailResponse(album, result):
            return .none
        case let .setAlbumDetailView(isActive, albumChartStub):
            return .none
        }
    }
)
