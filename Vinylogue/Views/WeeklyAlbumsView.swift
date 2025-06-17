import Sharing
import SwiftUI

struct WeeklyAlbumsView: View {
    let user: User

    @State private var loader: WeeklyAlbumLoader
    @State private var currentYearOffset = 1 // Start with 1 year ago
    @Shared(.appStorage("currentPlayCountFilter")) var playCountFilter: Int = 1
    @Namespace private var albumNamespace

    init(user: User) {
        self.user = user
        // Initialize with current environment values - will be updated in onAppear
        _loader = State(wrappedValue: WeeklyAlbumLoader())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()

                // Main content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if loader.albums.isEmpty, !loader.isLoading {
                            if loader.error != nil {
                                ErrorStateView(error: loader.error!)
                            } else {
                                EmptyStateView(username: user.username)
                            }
                        } else {
                            ForEach(loader.albums) { album in
                                // TODO: fix this
                                let index = loader.albums.firstIndex(where: { $0.id == album.id })!
                                VStack(spacing: 0) {
                                    AlbumRowView(album: $loader.albums[index], namespace: albumNamespace)

                                    if index != loader.albums.indices.last {
                                        Divider()
                                            .padding(.leading, 108) // Align with text, not image
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, yearNavigationTopPadding(in: geometry))
                    .padding(.bottom, yearNavigationBottomPadding(in: geometry))
                }

                // Year navigation buttons overlaid on safe areas
                YearNavigationButtons(
                    currentYearOffset: $currentYearOffset,
                    loader: loader,
                    geometry: geometry
                )
            }
        }
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
                if loader.isLoading {
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

    // Calculate padding for year navigation buttons
    private func yearNavigationTopPadding(in geometry: GeometryProxy) -> CGFloat {
        let topSafeArea = geometry.safeAreaInsets.top
        return loader.canNavigate(to: currentYearOffset - 1) ? max(topSafeArea + 60, 80) : 20
    }

    private func yearNavigationBottomPadding(in geometry: GeometryProxy) -> CGFloat {
        let bottomSafeArea = geometry.safeAreaInsets.bottom
        return loader.canNavigate(to: currentYearOffset + 1) ? max(bottomSafeArea + 60, 80) : 20
    }
}

// MARK: - Year Navigation Buttons

private struct YearNavigationButtons: View {
    @Binding var currentYearOffset: Int
    let loader: WeeklyAlbumLoader
    let geometry: GeometryProxy

    var body: some View {
        VStack {
            // Next year button (top safe area)
            if loader.canNavigate(to: currentYearOffset - 1) {
                HStack {
                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentYearOffset -= 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(String(loader.getYear(for: currentYearOffset - 1)))
                                .font(.title2.weight(.medium))
                                .foregroundColor(.vinylogueBlueBold)

                            Image(systemName: "arrow.right")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.vinylogueBlueBold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.primaryBackground)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, geometry.safeAreaInsets.top + 10)
            }

            Spacer()

            // Previous year button (bottom safe area)
            if loader.canNavigate(to: currentYearOffset + 1) {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentYearOffset += 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.vinylogueBlueBold)

                            Text(String(loader.getYear(for: currentYearOffset + 1)))
                                .font(.title2.weight(.medium))
                                .foregroundColor(.vinylogueBlueBold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.primaryBackground)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.leading, 20)

                    Spacer()
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
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

// MARK: - Empty State

private struct EmptyStateView: View {
    let username: String

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.vinylogueBlueBold)

            VStack(spacing: 16) {
                Text("No charts!")
                    .font(.title.weight(.semibold))
                    .foregroundColor(.primaryText)

                Text("Looks like \(username) didn't listen to\nmuch music this week.")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Error State

private struct ErrorStateView: View {
    let error: LastFMError

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "xmark")
                .font(.system(size: 80))
                .foregroundColor(.destructive)

            VStack(spacing: 16) {
                Text("Error")
                    .font(.title.weight(.semibold))
                    .foregroundColor(.primaryText)

                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
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
    .environment(\.lastFMClient, LastFMClient.shared)
}

#Preview("Empty State") {
    NavigationView {
        EmptyStateView(username: "ybsc")
    }
}

#Preview("Error State") {
    NavigationView {
        ErrorStateView(error: .networkUnavailable)
    }
}
