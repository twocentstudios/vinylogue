import Sharing
import SwiftUI

struct WeeklyAlbumsView: View {
    let user: User

    @Bindable private var loader: WeeklyAlbumLoader = .init()
    @State private var currentYearOffset = 1 // Start with 1 year ago
    @Shared(.appStorage("currentPlayCountFilter")) var playCountFilter: Int = 1

    init(user: User) {
        self.user = user
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch loader.albumsState {
                case .initialized, .loading:
                    EmptyView()
                case .loaded:
                    if loader.albums.isEmpty {
                        EmptyStateView(username: user.username)
                    } else {
                        ForEach($loader.albums) { $album in
                            VStack(spacing: 0) {
                                NavigationLink(destination: AlbumDetailView(album: $album)) {
                                    AlbumRowView(album: $album)
                                }
                                .buttonStyle(AlbumRowButtonStyle())
                            }
                        }
                    }
                case let .failed(error):
                    ErrorStateView(error: error)
                }
            }
        }
        .modifier(YearNavigationButtons(currentYearOffset: $currentYearOffset, loader: loader))
        .background(Color.primaryBackground)
        .navigationTitle("charts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("charts")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primaryText)

                    if let weekInfo = loader.currentWeekInfo {
                        Text(weekInfo.displayText)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if case .loading = loader.albumsState {
                    LoadingIndicatorView()
                } else {
                    EmptyView()
                }
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
}

// MARK: - Year Navigation Buttons

private struct YearNavigationButtons: ViewModifier {
    @Binding var currentYearOffset: Int
    let loader: WeeklyAlbumLoader

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top) {
                let prevOffset = currentYearOffset - 1
                if loader.canNavigate(to: prevOffset) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentYearOffset = prevOffset
                        }
                    }) {
                        VStack(spacing: -2) {
                            Image(systemName: "arrow.up")
                                .font(.f(.regular, .caption1))
                                .foregroundColor(.vinylogueBlueBold)
                            Text(String(loader.getYear(for: prevOffset)))
                                .font(.f(.regular, .title2))
                                .foregroundColor(.vinylogueBlueBold)
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
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                let nextOffset = currentYearOffset + 1
                if loader.canNavigate(to: nextOffset) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentYearOffset = nextOffset
                        }
                    }) {
                        VStack(spacing: -2) {
                            Text(String(loader.getYear(for: nextOffset)))
                                .font(.f(.regular, .title2))
                                .foregroundColor(.vinylogueBlueBold)
                                .contentTransition(.numericText(value: Double(nextOffset)))
                            Image(systemName: "arrow.down")
                                .font(.f(.regular, .caption1))
                                .foregroundColor(.vinylogueBlueBold)
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                    }
                }
            }
    }
}

// MARK: - Loading Indicator

private struct LoadingIndicatorView: View {
    var body: some View {
        AnimatedLoadingIndicator(size: 24)
    }
}

// MARK: - Preview

#Preview("With Albums") {
    NavigationView {
        WeeklyAlbumsView(user: User(
            username: "ybsc",
            realName: "Christopher",
            imageURL: nil,
            url: nil,
            playCount: 1500
        ))
    }
}

#Preview("Empty State") {
    EmptyStateView(username: "ybsc")
        .background(Color.primaryBackground)
}

#Preview("Error State") {
    ErrorStateView(error: .networkUnavailable)
        .background(Color.primaryBackground)
}
