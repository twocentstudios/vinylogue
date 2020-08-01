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
    case saveUserToDisk
    case logOut
    case login(LoginAction)
    case favoriteUsers(FavoriteUsersAction)
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var appClient: AppClient
    var dateClient: DateClient
    var lastFMClient: LastFMClient
    var imageClient: ImageClient
    var persistenceClient: PersistenceClient
}

extension AppEnvironment {
    static let live = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        appClient: .live,
        dateClient: .live,
        lastFMClient: .live,
        imageClient: .live,
        persistenceClient: .live
    )

    static let mockUser = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        appClient: .live,
        dateClient: .mock,
        lastFMClient: .mock,
        imageClient: .mock,
        persistenceClient: .live
    )

    static let mockFirstTime = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        appClient: .live,
        dateClient: .mock,
        lastFMClient: .mock,
        imageClient: .mock,
        persistenceClient: .live
    )
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
            if let user = environment.persistenceClient.loadUser() {
                state.userState = .loggedIn(user)
                state.viewState = .favoriteUsers(.init(user: user))
            } else {
                state.userState = .loggedOut
                state.viewState = .login(.empty)
            }
            return environment.appClient.applicationDidEnterBackground()
                .map { _ in AppAction.saveUserToDisk }

        case .saveUserToDisk:
            let saveableUser = (/UserState.loggedIn).extract(from: state.userState)
            environment.persistenceClient.saveUser(saveableUser)
            return .none

        case .logOut:
            state.userState = .loggedOut
            state.viewState = .login(.empty)
            return Effect.fireAndForget {
                environment.persistenceClient.saveUser(nil)
            }

        case let .login(.logIn(user)):
            state.userState = .loggedIn(user)
            state.viewState = .favoriteUsers(.init(user: user))
            return Effect.fireAndForget {
                environment.persistenceClient.saveUser(user)
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
            guard case let .settings(value) = viewState else { return nil }
            print(value.systemInformation)
            return .init(user: user, systemInformation: value.systemInformation)
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
            return state // TODO: I guess it's okay not to reinitialize with the root state's user
        }
        set {
            guard case .weeklyAlbumChart = viewState,
                let state = newValue else { return }
            viewState = .weeklyAlbumChart(state)
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
    weeklyAlbumChartReducer.optional.pullback(
        state: \.weeklyAlbumChartState,
        action: /FavoriteUsersAction.weeklyAlbumChart,
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
            state.viewState = .weeklyAlbumChart(
                .init(
                    username: username,
                    now: environment.dateClient.date(),
                    playCountFilter: .off,
                    calendar: environment.dateClient.calendar
                )
            )
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
            state.viewState = .settings(SettingsState(user: state.user, systemInformation: environment.appClient.systemInformation()))
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
    var systemInformation: SystemInformation
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
    enum ViewState: Equatable {
        case albumDetail(AlbumDetailState)
    }

    enum WeeklyChartListState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.WeeklyChartList) // TODO: cache this on disk
        case failed(LastFMClient.Error)
    }

    enum AlbumChartsState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.WeeklyAlbumCharts)
        case failed(LastFMClient.Error)
    }

    enum AlbumImagesState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.AlbumImagesStub)
        case failed(LastFMClient.Error)
    }

    enum ImageState: Equatable {
        case initialized
        case loading
        case loaded(UIImage)
        case failed
    }

    var viewState: ViewState?

    let username: Username
    let now: Date
    let playCountFilter: Settings.PlayCountFilter

    var weeklyChartListState: WeeklyChartListState
    var albumCharts: [LastFM.WeeklyChartRange.ID: AlbumChartsState]
    var albumImageStubs: [LastFM.WeeklyAlbumChartStub.ID: AlbumImagesState]
    var albumImageThumbnails: [LastFM.WeeklyAlbumChartStub.ID: ImageState]

    // derived
    let weekOfYear: Int // for `now`
    let datesForYearsWithCurrentWeek: [Date]
    var chartRanges: [LastFM.WeeklyChartRange.ID: LastFM.WeeklyChartRange]
    var displayingChartRanges: [LastFM.WeeklyChartRange]
    var titlesForChartRanges: [LastFM.WeeklyChartRange.ID: String]
    var albumChartCache: [LastFM.WeeklyAlbumChartStub.ID: LastFM.WeeklyAlbumChartStub]
}

extension WeeklyAlbumChartState {
    init(username: Username, now: Date, playCountFilter: Settings.PlayCountFilter, calendar: Calendar) {
        self.username = username
        self.now = now
        self.playCountFilter = playCountFilter

        weeklyChartListState = .initialized
        albumCharts = [:]
        albumImageStubs = [:]
        albumImageThumbnails = [:]

        let components = calendar.dateComponents([.weekOfYear], from: now)
        weekOfYear = components.weekOfYear!

        datesForYearsWithCurrentWeek = (1 ... 30)
            .map { -$0 }
            .map { var d = DateComponents(); d.yearForWeekOfYear = $0; return d }
            .map { calendar.date(byAdding: $0, to: now)! } // TODO: ensure this never returns nil

        chartRanges = [:]
        displayingChartRanges = []
        titlesForChartRanges = [:]
        albumChartCache = [:]
        viewState = nil
    }

    mutating func updateDerivedChartRanges(_ calendar: Calendar) {
        guard case let .loaded(weeklyChartList) = weeklyChartListState else { return }
        displayingChartRanges = weeklyChartList.ranges
            .sorted(by: { $0.from > $1.from })
            .map { range in
                datesForYearsWithCurrentWeek.map { (range.from ... range.to).contains($0) }.contains(true) ? range : nil
            }
            .compactMap { $0 }
        chartRanges = displayingChartRanges.reduce(into: [:]) { $0[$1.id] = $1 }
        titlesForChartRanges = displayingChartRanges.reduce(into: [:]) { result, range in
            let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: range.from)
            result[range.id] = String(yearForWeekOfYear)
        }
    }

    func weeklyChartRange(for albumChartStub: LastFM.WeeklyAlbumChartStub) -> LastFM.WeeklyChartRange? {
        albumCharts
            .first { key, value -> Bool in
                guard case let .loaded(charts) = value else { return false }
                return charts.charts.contains(albumChartStub)
            }
            .flatMap { chartRanges[$0.key] }
    }
}

extension WeeklyAlbumChartState {
    var albumDetailState: AlbumDetailState? {
        get {
            guard case let .albumDetail(state) = viewState else { return nil }
            return state
        }
        set {
            guard case .albumDetail = viewState,
                let state = newValue else { return }
            viewState = .albumDetail(state)
        }
    }
}

enum WeeklyAlbumChartAction: Equatable {
    case fetchWeeklyChartList
    case fetchWeeklyChartListResponse(Result<LastFM.WeeklyChartList, LastFMClient.Error>)
    case fetchWeeklyAlbumChart(LastFM.WeeklyChartRange.ID)
    case fetchWeeklyAlbumChartResponse(LastFM.WeeklyChartRange.ID, Result<LastFM.WeeklyAlbumCharts, LastFMClient.Error>)
    case fetchImageThumbnailForChart(LastFM.WeeklyAlbumChartStub.ID)
    case fetchAlbumImages(LastFM.WeeklyAlbumChartStub.ID)
    case fetchAlbumImagesResponse(LastFM.WeeklyAlbumChartStub.ID, Result<LastFM.AlbumImagesStub, LastFMClient.Error>)
    case fetchImageThumbnail(LastFM.WeeklyAlbumChartStub.ID)
    case fetchImageThumbnailResponse(LastFM.WeeklyAlbumChartStub.ID, Result<UIImage, ImageClient.Error>)
    case setAlbumDetailView(isActive: Bool, LastFM.WeeklyAlbumChartStub.ID)
    case albumDetail(AlbumDetailAction)
}

let weeklyAlbumChartReducer = Reducer<WeeklyAlbumChartState, WeeklyAlbumChartAction, AppEnvironment>.combine(
    albumDetailReducer.optional.pullback(
        state: \.albumDetailState,
        action: /WeeklyAlbumChartAction.albumDetail,
        environment: { $0 }
    ),
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
            state.updateDerivedChartRanges(environment.dateClient.calendar)
            return .none

        case let .fetchWeeklyAlbumChart(chartRangeID):
            guard let chartRange = state.chartRanges[chartRangeID] else { assertionFailure("id not found"); return .none }
            switch state.albumCharts[chartRangeID] {
            case .none, .initialized, .failed: break
            // TODO: This gets erroneously called by SwiftUI even after the chartRange has changed to `.loading`
            // This shouldn't be possible. For now, we'll just silently ignore it.
            // case .loading, .loaded: assertionFailure("Unexpected state"); return .none
            case .loading, .loaded: return .none
            }
            state.albumCharts[chartRangeID] = .loading
            return environment.lastFMClient.weeklyAlbumChart(state.username, chartRange)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { WeeklyAlbumChartAction.fetchWeeklyAlbumChartResponse(chartRange.id, $0) }

        case let .fetchWeeklyAlbumChartResponse(chartRangeID, result):
            guard case .loading = state.albumCharts[chartRangeID] else { assertionFailure("Unexpected state"); return .none }
            switch result {
            case let .success(value):
                state.albumCharts[chartRangeID] = .loaded(value)
                state.albumChartCache.merge(Dictionary(uniqueKeysWithValues: value.charts.map { ($0.id, $0) }), uniquingKeysWith: { _, new in new })
            case let .failure(error): state.albumCharts[chartRangeID] = .failed(error)
            }
            return .none // TODO: consider prefetching logic for albums and thumbnails

        case let .fetchImageThumbnailForChart(albumChartStubID):
            switch state.albumImageStubs[albumChartStubID] {
            case .none, .initialized: return Effect(value: .fetchAlbumImages(albumChartStubID))
            case .loading, .failed: return .none // Don't retry failed albums (they probably don't exist)
            case .loaded:
                switch state.albumImageThumbnails[albumChartStubID] {
                case .none, .initialized, .failed: return Effect(value: .fetchImageThumbnail(albumChartStubID))
                case .loading, .loaded: return .none
                }
            }

        case let .fetchAlbumImages(albumChartStubID):
            guard let albumChartStub = state.albumChartCache[albumChartStubID] else { assertionFailure("id not found"); return .none }
            switch state.albumImageStubs[albumChartStubID] {
            case .none, .initialized, .failed: break
            case .loading, .loaded: assertionFailure("Unexpected state"); return .none
            }
            state.albumImageStubs[albumChartStubID] = .loading
            return environment.lastFMClient.albumImages(albumChartStub.artist, albumChartStub.album)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { WeeklyAlbumChartAction.fetchAlbumImagesResponse(albumChartStubID, $0) }

        case let .fetchAlbumImagesResponse(albumChartStubID, result):
            guard case .loading = state.albumImageStubs[albumChartStubID] else { assertionFailure("Unexpected state"); return .none }
            switch result {
            case let .success(value):
                state.albumImageStubs[albumChartStubID] = .loaded(value)
                switch state.albumImageThumbnails[albumChartStubID] {
                case .none, .initialized, .failed: return Effect(value: .fetchImageThumbnail(albumChartStubID))
                case .loading, .loaded: return .none
                }
            case let .failure(error):
                state.albumImageStubs[albumChartStubID] = .failed(error)
                return .none
            }

        case let .fetchImageThumbnail(albumChartStubID):
            switch state.albumImageThumbnails[albumChartStubID] {
            case .none, .initialized, .failed: break
            case .loading, .loaded: return .none
            }
            guard case let .loaded(album) = state.albumImageStubs[albumChartStubID] else { assertionFailure("Unexpected state"); return .none }

            guard let thumbnailURL = album.imageSet?.thumbnailURL else { return .none }
            state.albumImageThumbnails[albumChartStubID] = .loading
            return environment.imageClient.fetchImage(thumbnailURL)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { WeeklyAlbumChartAction.fetchImageThumbnailResponse(albumChartStubID, $0) }

        case let .fetchImageThumbnailResponse(albumChartStubID, result):
            guard case .loading = state.albumImageThumbnails[albumChartStubID] else { assertionFailure("Unexpected state"); return .none }
            switch result {
            case let .success(value): state.albumImageThumbnails[albumChartStubID] = .loaded(value)
            case let .failure(error): state.albumImageThumbnails[albumChartStubID] = .failed
            }
            return .none

        case let .setAlbumDetailView(isActive: true, albumChartStubID):
            guard let albumChartStub = state.albumChartCache[albumChartStubID] else { assertionFailure("Unexpected state"); return .none }
            guard let weeklyChartRange = state.weeklyChartRange(for: albumChartStub) else { assertionFailure("Unexpected state"); return .none }
            let image = (/WeeklyAlbumChartState.ImageState.loaded).extract(from: state.albumImageThumbnails[albumChartStub.id])
            let albumDetailState = AlbumDetailState(
                username: state.username,
                albumChartStub: albumChartStub,
                weeklyChartRange: weeklyChartRange,
                image: image
            )
            state.viewState = .albumDetail(albumDetailState)
            return .none

        case .setAlbumDetailView(isActive: false, _):
            state.viewState = nil
            return .none

        case .albumDetail:
            return .none
        }
    }
)

struct AlbumDetailState: Equatable {
    enum AlbumState: Equatable {
        case initialized
        case loading
        case loaded(LastFM.Album)
        case failed(LastFMClient.Error) // TODO: failed view state
    }

    enum ImageState: Equatable {
        case initialized
        case loading
        case loaded(UIImage)
        case failed
    }

    enum ImageColorsState: Equatable {
        case initialized
        case loading
        case loaded(ImageClient.ImageColors)
        case failed
    }

    let username: Username
    let albumChartStub: LastFM.WeeklyAlbumChartStub
    let weeklyChartRange: LastFM.WeeklyChartRange
    var albumState: AlbumState
    var imageState: ImageState
    var imageColorsState: ImageColorsState
}

extension AlbumDetailState {
    init(username: Username, albumChartStub: LastFM.WeeklyAlbumChartStub, weeklyChartRange: LastFM.WeeklyChartRange, image: UIImage?) {
        self.username = username
        self.albumChartStub = albumChartStub
        self.weeklyChartRange = weeklyChartRange
        albumState = .initialized
        imageState = image.flatMap(ImageState.loaded) ?? .initialized
        imageColorsState = .initialized
    }
}

enum AlbumDetailAction: Equatable {
    case fetchInitial
    case fetchAlbum
    case fetchAlbumResponse(Result<LastFM.Album, LastFMClient.Error>)
    case fetchImage
    case fetchImageResponse(Result<UIImage, ImageClient.Error>)
    case fetchImageColors
    case fetchImageColorsResponse(Result<ImageClient.ImageColors, ImageClient.Error>)
}

let albumDetailReducer = Reducer<AlbumDetailState, AlbumDetailAction, AppEnvironment> { state, action, environment in
    switch action {
    case .fetchInitial:
        let effect: Effect<AlbumDetailAction, Never> = .init(value: .fetchAlbum)
        switch state.imageState {
        case .initialized: return effect.append(Effect(value: .fetchImage)).eraseToEffect()
        case .loaded: return effect.append(Effect(value: .fetchImageColors)).eraseToEffect()
        case .loading, .failed: assertionFailure("Unexpected state")
        }

    case .fetchAlbum:
        switch state.albumState {
        case .initialized, .failed:
            state.albumState = .loading
            return environment.lastFMClient.album(state.username, state.albumChartStub.artist, state.albumChartStub.album)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(AlbumDetailAction.fetchAlbumResponse)
        case .loading, .loaded: break // assertionFailure("Unexpected state")  TODO: ignoring this for now because of the onAppear multiple calls issue
        }

    case let .fetchAlbumResponse(result):
        guard case .loading = state.albumState else { assertionFailure("Unexpected state"); break }
        switch result {
        case let .success(value):
            state.albumState = .loaded(value)
            return Effect(value: .fetchImage)
        case let .failure(error):
            state.albumState = .failed(error)
        }

    case .fetchImage:
        guard case let .loaded(album) = state.albumState,
            let imageURL = album.imageSet?.url else { break }
        switch state.imageState {
        case .initialized, .failed:
            state.imageState = .loading
            return environment.imageClient.fetchImage(imageURL)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(AlbumDetailAction.fetchImageResponse)
        case .loading, .loaded: break
        }

    case let .fetchImageResponse(result):
        guard case .loading = state.imageState else { assertionFailure("Unexpected state"); break }
        switch result {
        case let .success(value):
            state.imageState = .loaded(value)
            return Effect(value: .fetchImageColors)
        case .failure:
            state.imageState = .failed
        }

    case .fetchImageColors:
        guard case let .loaded(image) = state.imageState else { assertionFailure("Unexpected state"); break }
        switch state.imageColorsState {
        case .initialized, .failed:
            state.imageColorsState = .loading
            return environment.imageClient.fetchImageColors(image)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(AlbumDetailAction.fetchImageColorsResponse)
        case .loading, .loaded: break // assertionFailure("Unexpected state") TODO: eventually clean this up
        }

    case let .fetchImageColorsResponse(result):
        guard case .loading = state.imageColorsState else { assertionFailure("Unexpected state"); break }
        switch result {
        case let .success(value): state.imageColorsState = .loaded(value)
        case .failure: state.imageColorsState = .failed
        }
    }

    return .none
}
