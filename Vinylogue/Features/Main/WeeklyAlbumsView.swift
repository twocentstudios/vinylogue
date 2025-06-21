import Dependencies
import Sharing
import SwiftUI

struct WeeklyAlbumsView: View {
    @Bindable var store: WeeklyAlbumsStore

    @State private var performCurrentYearOffsetChangeOnScrollIdle: Int? = nil
    @State private var topProgress: Double = 0.0
    @State private var bottomProgress: Double = 0.0
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ContentStateView(store: store)
            }
        }
        .scrollPosition($scrollPosition)
        .modifier(OverscrollHandler(
            store: store,
            performCurrentYearOffsetChangeOnScrollIdle: $performCurrentYearOffsetChangeOnScrollIdle,
            topProgress: $topProgress,
            bottomProgress: $bottomProgress
        ))
        .modifier(YearNavigationButtons(store: store, topProgress: topProgress, bottomProgress: bottomProgress))
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
        .task(id: store.currentYearOffset) {
            // This task is also called on first load
            await store.loadAlbums()
        }
        .onChange(of: store.currentYearOffset) { _, _ in
            scrollPosition.scrollTo(edge: .top)
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 1.0), trigger: store.currentYearOffset)
    }

    @ViewBuilder private var toolbarTitle: some View {
        VStack(spacing: 2) {
            Text("\(store.user.username)'s charts")
                .foregroundStyle(Color.vinylogueBlueDark)
                .font(.f(.regular, .headline))
                .padding(.bottom, -2)

            if let weekInfo = store.currentWeekInfo {
                Text(weekInfo.displayText)
                    .font(.caption)
                    .foregroundColor(.primaryText)
                    .contentTransition(.numericText())
            }
        }
        .animation(.default, value: store.currentWeekInfo?.displayText)
    }

    @ViewBuilder private var toolbarTrailing: some View {
        Group {
            if case .loading = store.albumsState {
                AnimatedLoadingIndicator(size: 24)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Content State View

private struct ContentStateView: View {
    let store: WeeklyAlbumsStore

    var body: some View {
        switch store.albumsState {
        case .initialized, .loading:
            EmptyView()
        case .loaded:
            AlbumListView(store: store, onAlbumTap: store.navigateToAlbum)
        case let .failed(error):
            ErrorStateView(error: error)
        }
    }
}

// MARK: - Album List View

private struct AlbumListView: View {
    let store: WeeklyAlbumsStore
    let onAlbumTap: (UserChartAlbum) -> Void

    var body: some View {
        if store.albums.isEmpty {
            EmptyStateView(username: store.user.username)
        } else {
            ForEach(store.albums) { album in
                Button {
                    onAlbumTap(album)
                } label: {
                    AlbumRowView(album: album)
                }
                .buttonStyle(AlbumRowButtonStyle())
                .transition(.identity)
                .task(id: album.id) {
                    if album.detail?.imageURL == nil || album.detail?.imageURL?.isEmpty == true {
                        await store.loadAlbum(album)
                    }
                }
            }
        }
    }
}

// MARK: - Overscroll Handler

private struct OverscrollHandler: ViewModifier {
    struct ScrollProgress: Equatable {
        let top: Double
        let bottom: Double
    }

    @Bindable var store: WeeklyAlbumsStore
    @Binding var performCurrentYearOffsetChangeOnScrollIdle: Int?
    @Binding var topProgress: Double
    @Binding var bottomProgress: Double
    @State var reachedOverscrollThreshold: Bool = false
    @State var reachedOverscrollThresholdFeedback: Bool = false

    private static let overscrollThreshold: CGFloat = 90

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: ScrollProgress.self) { geometry in
                let topOverscroll = -(geometry.contentOffset.y + geometry.contentInsets.top)
                let bottomOverscroll = geometry.contentOffset.y - max(0.0, geometry.contentSize.height - geometry.containerSize.height) + geometry.contentInsets.top

                let newTopProgress = max(0.0, topOverscroll / Self.overscrollThreshold)
                let newBottomProgress = max(0.0, bottomOverscroll / Self.overscrollThreshold)

                return ScrollProgress(top: newTopProgress, bottom: newBottomProgress)
            } action: { oldValue, newValue in
                guard performCurrentYearOffsetChangeOnScrollIdle == nil else { return }
                guard case .loaded = store.albumsState else { return }
                topProgress = newValue.top
                bottomProgress = newValue.bottom
                if oldValue.top < 1.0, newValue.top >= 1.0 {
                    reachedOverscrollThreshold = true
                } else if oldValue.bottom < 1.0, newValue.bottom >= 1.0 {
                    reachedOverscrollThreshold = true
                } else if oldValue.top > 1.0, newValue.top < 1.0 {
                    reachedOverscrollThreshold = false
                } else if oldValue.bottom > 1.0, newValue.bottom < 1.0 {
                    reachedOverscrollThreshold = false
                }
            }
            .onScrollPhaseChange { oldPhase, newPhase, context in
                // 0 when scrolled exactly to top of content, positive when overscrolled above
                let topOverscroll = -(context.geometry.contentOffset.y + context.geometry.contentInsets.top)

                // 0 when scrolled exactly to bottom of content, positive when overscrolled below
                let bottomOverscroll = context.geometry.contentOffset.y - max(0.0, context.geometry.contentSize.height - context.geometry.containerSize.height) + context.geometry.contentInsets.top

                if newPhase == .idle {
                    // Wait until scroll has returned to idle before changing navigation
                    if let performCurrentYearOffsetChangeOnScrollIdle {
                        if store.canNavigate(to: performCurrentYearOffsetChangeOnScrollIdle) {
                            store.currentYearOffset = performCurrentYearOffsetChangeOnScrollIdle
                        }
                        self.performCurrentYearOffsetChangeOnScrollIdle = nil
                        topProgress = 0.0
                        bottomProgress = 0.0
                    }
                    reachedOverscrollThreshold = false
                } else if oldPhase == .interacting, newPhase == .decelerating {
                    if topOverscroll > Self.overscrollThreshold {
                        performCurrentYearOffsetChangeOnScrollIdle = store.currentYearOffset - 1
                        withAnimation(.snappy(duration: 0.2)) {
                            topProgress = 1.0
                        }
                    } else if bottomOverscroll > Self.overscrollThreshold {
                        performCurrentYearOffsetChangeOnScrollIdle = store.currentYearOffset + 1
                        withAnimation(.snappy(duration: 0.2)) {
                            bottomProgress = 1.0
                        }
                    }
                }
            }
            .onChange(of: reachedOverscrollThreshold) { oldValue, newValue in
                if !oldValue, newValue {
                    reachedOverscrollThresholdFeedback.toggle()
                }
            }
            .sensoryFeedback(.impact(weight: .light, intensity: 1.0), trigger: reachedOverscrollThresholdFeedback)
            .sensoryFeedback(.impact(weight: .medium, intensity: 1.0), trigger: performCurrentYearOffsetChangeOnScrollIdle != nil)
    }
}

// MARK: - Year Navigation Buttons

private struct YearNavigationButtons: ViewModifier {
    @Bindable var store: WeeklyAlbumsStore
    let topProgress: Double
    let bottomProgress: Double

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top) {
                let prevOffset = store.currentYearOffset - 1
                if store.canNavigate(to: prevOffset) {
                    Button(action: {
                        store.currentYearOffset = prevOffset
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up")
                                .font(.f(.ultralight, .caption1))
                                .foregroundColor(.vinylogueBlueDark)
                            Text(String(store.getYear(for: prevOffset)))
                                .font(.f(.medium, .headline))
                                .foregroundColor(.vinylogueBlueDark)
                                .contentTransition(.numericText(value: Double(prevOffset)))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                        .padding(.top, 10)
                        .overlay {
                            GeometryReader { proxy in
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.up")
                                        .font(.f(.ultralight, .caption1))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                    Text(String(store.getYear(for: prevOffset)))
                                        .font(.f(.medium, .headline))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                        .contentTransition(.numericText(value: Double(prevOffset)))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.vinylogueBlueDark)
                                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                                )
                                .padding(.top, 10)
                                .mask(alignment: .bottom) {
                                    Rectangle().fill(.black).frame(height: proxy.size.height * max(0.0, min(1.0, topProgress)))
                                }
                            }
                        }
                        .scaleEffect(x: 1 - pow(max(1.0, topProgress) - 1.0, 0.5) * 0.1, y: max(1.0, pow(topProgress - 1.0, 0.5) * 0.3 + 1.0), anchor: .top)
                    }
                    .sensoryFeedback(.selection, trigger: store.currentYearOffset)
                    .transition(.offset(x: 0, y: -100).combined(with: .opacity))
                }
            }
            .safeAreaInset(edge: .bottom) {
                let nextOffset = store.currentYearOffset + 1
                if store.canNavigate(to: nextOffset) {
                    Button(action: {
                        store.currentYearOffset = nextOffset
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down")
                                .font(.f(.ultralight, .caption1))
                                .foregroundColor(.vinylogueBlueDark)
                            Text(String(store.getYear(for: nextOffset)))
                                .font(.f(.medium, .headline))
                                .foregroundColor(.vinylogueBlueDark)
                                .contentTransition(.numericText(value: Double(nextOffset)))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                        .overlay {
                            GeometryReader { proxy in
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.down")
                                        .font(.f(.ultralight, .caption1))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                    Text(String(store.getYear(for: nextOffset)))
                                        .font(.f(.medium, .headline))
                                        .foregroundColor(.vinylogueWhiteSubtle)
                                        .contentTransition(.numericText(value: Double(nextOffset)))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.vinylogueBlueDark)
                                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                                )
                                .mask(alignment: .top) {
                                    Rectangle().fill(.black).frame(height: proxy.size.height * max(0.0, min(1.0, bottomProgress)))
                                }
                            }
                        }
                        .scaleEffect(x: 1 - pow(max(1.0, bottomProgress) - 1.0, 0.5) * 0.1, y: max(1.0, pow(bottomProgress - 1.0, 0.5) * 0.3 + 1.0), anchor: .bottom)
                    }
                    .sensoryFeedback(.selection, trigger: store.currentYearOffset)
                }
            }
            .disabled(store.albumsState == .loading)
            .animation(.snappy, value: store.currentYearOffset)
    }
}
