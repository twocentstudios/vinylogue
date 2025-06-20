import Sharing
import SwiftUI

struct WeeklyAlbumsView: View {
    let user: User
    @State private var loader: WeeklyAlbumLoader = .init()
    @State private var currentYearOffset = 1 // Start with 1 year ago
    @Shared(.currentPlayCountFilter) var playCountFilter

    @State private var performCurrentYearOffsetChangeOnScrollIdle: Int? = nil
    @State private var topProgress: Double = 0.0
    @State private var bottomProgress: Double = 0.0

    init(user: User) {
        self.user = user
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ContentStateView(loader: loader, user: user)
            }
            .animation(.snappy(duration: 0.20), value: loader.albumsState)
        }
        .modifier(OverscrollHandler(
            currentYearOffset: $currentYearOffset,
            loader: loader,
            performCurrentYearOffsetChangeOnScrollIdle: $performCurrentYearOffsetChangeOnScrollIdle,
            topProgress: $topProgress,
            bottomProgress: $bottomProgress
        ))
        .modifier(YearNavigationButtons(currentYearOffset: $currentYearOffset, loader: loader, topProgress: topProgress, bottomProgress: bottomProgress))
        .background(Color.primaryBackground)
        .navigationTitle("charts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbarTitle
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarTrailing
            }
        }
        .task {
            // Only load if data isn't already loaded for this user, year offset, and play count filter
            if !loader.isDataLoaded(for: user, yearOffset: currentYearOffset, playCountFilter: playCountFilter) {
                await loader.updatePlayCountFilter(playCountFilter, for: user, yearOffset: currentYearOffset)
                await loader.loadAlbums(for: user, yearOffset: currentYearOffset)
            }
        }
        .onChange(of: currentYearOffset) { _, newOffset in
            Task {
                await loader.updatePlayCountFilter(playCountFilter, for: user, yearOffset: newOffset)
                await loader.loadAlbums(for: user, yearOffset: newOffset)
            }
        }
        .onChange(of: playCountFilter) { _, newFilter in
            Task {
                await loader.updatePlayCountFilter(newFilter, for: user, yearOffset: currentYearOffset)
            }
        }
    }

    @ViewBuilder private var toolbarTitle: some View {
        VStack(spacing: 2) {
            Text("\(user.username)'s charts")
                .foregroundStyle(Color.vinylogueBlueDark)
                .font(.f(.regular, .headline))
                .padding(.bottom, -2)

            if let weekInfo = loader.currentWeekInfo {
                Text(weekInfo.displayText)
                    .font(.caption)
                    .foregroundColor(.primaryText)
                    .contentTransition(.numericText())
            }
        }
        .animation(.default, value: loader.currentWeekInfo?.displayText)
    }

    @ViewBuilder private var toolbarTrailing: some View {
        Group {
            if case .loading = loader.albumsState {
                AnimatedLoadingIndicator(size: 24)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Content State View

private struct ContentStateView: View {
    let loader: WeeklyAlbumLoader
    let user: User

    var body: some View {
        switch loader.albumsState {
        case .initialized, .loading:
            EmptyView()
        case .loaded:
            AlbumListView(loader: loader, user: user)
        case let .failed(error):
            ErrorStateView(error: error)
        }
    }
}

// MARK: - Album List View

private struct AlbumListView: View {
    let loader: WeeklyAlbumLoader
    let user: User

    var body: some View {
        if loader.albums.isEmpty {
            EmptyStateView(username: user.username)
        } else if let weekInfo = loader.currentWeekInfo {
            ForEach(loader.albums) { album in
                let index = loader.albums.firstIndex(where: { $0.id == album.id }) ?? 0
                NavigationLink(destination: AlbumDetailView(album: album, weekInfo: weekInfo)) {
                    AlbumRowView(album: album)
                }
                .buttonStyle(AlbumRowButtonStyle())
                .transition(albumTransition(for: index))
                .task(id: album.id) {
                    if album.imageURL == nil {
                        await loader.loadAlbum(album, for: user)
                    }
                }
            }
        }
    }

    private func albumTransition(for index: Int) -> AnyTransition {
        .asymmetric(
            insertion: .offset(x: 0, y: 100).combined(with: .opacity).animation(.snappy(duration: 0.2).delay(Double(index) * 0.07)),
            removal: .offset(x: 0, y: -100).combined(with: .opacity).animation(.snappy(duration: 0.2).delay(Double(index) * 0.07))
        )
    }
}

// MARK: - Overscroll Handler

private struct OverscrollHandler: ViewModifier {
    struct ScrollProgress: Equatable {
        let top: Double
        let bottom: Double
    }
    
    @Binding var currentYearOffset: Int
    let loader: WeeklyAlbumLoader
    @Binding var performCurrentYearOffsetChangeOnScrollIdle: Int?
    @Binding var topProgress: Double
    @Binding var bottomProgress: Double

    private static let overscrollThreshold: CGFloat = 90

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollProgress.self) { geometry in
                let topOverscroll = -(geometry.contentOffset.y + geometry.contentInsets.top)
                let bottomOverscroll = geometry.contentOffset.y - max(0.0, geometry.contentSize.height - geometry.containerSize.height) + geometry.contentInsets.top

                let newTopProgress = max(0.0, topOverscroll / Self.overscrollThreshold)
                let newBottomProgress = max(0.0, bottomOverscroll / Self.overscrollThreshold)

                return ScrollProgress(top: newTopProgress, bottom: newBottomProgress)
            } action: { _, value in
                guard performCurrentYearOffsetChangeOnScrollIdle == nil else { return }
                topProgress = value.top
                bottomProgress = value.bottom
            }
            .onScrollPhaseChange { oldPhase, newPhase, context in
                // 0 when scrolled exactly to top of content, positive when overscrolled above
                let topOverscroll = -(context.geometry.contentOffset.y + context.geometry.contentInsets.top)

                // 0 when scrolled exactly to bottom of content, positive when overscrolled below
                let bottomOverscroll = context.geometry.contentOffset.y - max(0.0, context.geometry.contentSize.height - context.geometry.containerSize.height) + context.geometry.contentInsets.top

                if newPhase == .idle {
                    // Wait until scroll has returned to idle before changing navigation
                    if let performCurrentYearOffsetChangeOnScrollIdle {
                        if loader.canNavigate(to: performCurrentYearOffsetChangeOnScrollIdle) {
                            currentYearOffset = performCurrentYearOffsetChangeOnScrollIdle
                        }
                        self.performCurrentYearOffsetChangeOnScrollIdle = nil
                        topProgress = 0.0
                        bottomProgress = 0.0
                    }
                } else if oldPhase == .interacting, newPhase == .decelerating {
                    if topOverscroll > Self.overscrollThreshold {
                        performCurrentYearOffsetChangeOnScrollIdle = currentYearOffset - 1
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        withAnimation(.snappy(duration: 0.2)) {
                            topProgress = 1.0
                        }
                    } else if bottomOverscroll > Self.overscrollThreshold {
                        performCurrentYearOffsetChangeOnScrollIdle = currentYearOffset + 1
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        withAnimation(.snappy(duration: 0.2)) {
                            bottomProgress = 1.0
                        }
                    }
                }
            }
    }
}

// MARK: - Year Navigation Buttons

private struct YearNavigationButtons: ViewModifier {
    @Binding var currentYearOffset: Int
    let loader: WeeklyAlbumLoader
    let topProgress: Double
    let bottomProgress: Double

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top) {
                let prevOffset = currentYearOffset - 1
                if loader.canNavigate(to: prevOffset) {
                    Button(action: {
                        currentYearOffset = prevOffset
                    }) {
                        VStack(spacing: -2) {
                            Image(systemName: "arrow.up")
                                .font(.f(.regular, .caption1))
                                .foregroundColor(.vinylogueBlueDark)
                            Text(String(loader.getYear(for: prevOffset)))
                                .font(.f(.regular, .title2))
                                .foregroundColor(.vinylogueBlueDark)
                                .contentTransition(.numericText(value: Double(prevOffset)))
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                        .padding(.top, 10)
                        .overlay {
                            GeometryReader { proxy in
                                VStack(spacing: -2) {
                                    Image(systemName: "arrow.up")
                                        .font(.f(.regular, .caption1))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                    Text(String(loader.getYear(for: prevOffset)))
                                        .font(.f(.regular, .title2))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                        .contentTransition(.numericText(value: Double(prevOffset)))
                                }
                                .padding(.horizontal, 26)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.vinylogueBlueDark)
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                                )
                                .padding(.top, 10)
                                .mask(alignment: .bottom) {
                                    Rectangle().fill(.black).frame(height: proxy.size.height * max(0.0, min(1.0, topProgress)))
                                }
                            }
                        }
                        .scaleEffect(x: 1 - pow(max(1.0, topProgress) - 1.0, 0.5) * 0.1, y: max(1.0, pow(topProgress - 1.0, 0.5) * 0.3 + 1.0), anchor: .top)
                    }
                    .sensoryFeedback(.selection, trigger: currentYearOffset)
                    .transition(.offset(x: 0, y: -100).combined(with: .opacity))
                }
            }
            .safeAreaInset(edge: .bottom) {
                let nextOffset = currentYearOffset + 1
                if loader.canNavigate(to: nextOffset) {
                    Button(action: {
                        currentYearOffset = nextOffset
                    }) {
                        VStack(spacing: -2) {
                            Text(String(loader.getYear(for: nextOffset)))
                                .font(.f(.regular, .title2))
                                .foregroundColor(.vinylogueBlueDark)
                                .contentTransition(.numericText(value: Double(nextOffset)))
                            Image(systemName: "arrow.down")
                                .font(.f(.regular, .caption1))
                                .foregroundColor(.vinylogueBlueDark)
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                        .overlay {
                            GeometryReader { proxy in
                                VStack(spacing: -2) {
                                    Text(String(loader.getYear(for: nextOffset)))
                                        .font(.f(.regular, .title2))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                        .contentTransition(.numericText(value: Double(nextOffset)))
                                    Image(systemName: "arrow.down")
                                        .font(.f(.regular, .caption1))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                }
                                .padding(.horizontal, 26)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.vinylogueBlueDark)
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                                )
                                .mask(alignment: .top) {
                                    Rectangle().fill(.black).frame(height: proxy.size.height * max(0.0, min(1.0, bottomProgress)))
                                }
                            }
                        }
                        .scaleEffect(x: 1 - pow(max(1.0, bottomProgress) - 1.0, 0.5) * 0.1, y: max(1.0, pow(bottomProgress - 1.0, 0.5) * 0.3 + 1.0), anchor: .bottom)
                    }
                    .sensoryFeedback(.selection, trigger: currentYearOffset)
                }
            }
            .disabled(loader.albumsState == .loading)
            .animation(.snappy, value: currentYearOffset)
    }
}
