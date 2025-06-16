import SwiftUI

struct WeeklyAlbumsView: View {
    let user: User
    
    @StateObject private var loader = WeeklyAlbumLoader()
    @State private var currentYearOffset = 1 // Start with 1 year ago
    @Environment(\.playCountFilter) private var playCountFilter
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if loader.albums.isEmpty && !loader.isLoading {
                            if loader.error != nil {
                                ErrorStateView(error: loader.error!)
                            } else {
                                EmptyStateView(username: user.username)
                            }
                        } else {
                            ForEach(loader.albums) { album in
                                VStack(spacing: 0) {
                                    AlbumRowView(album: album)
                                    
                                    if album.id != loader.albums.last?.id {
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
            await loader.loadAlbums(for: user, yearOffset: currentYearOffset)
        }
        .onChange(of: currentYearOffset) { _, newOffset in
            Task {
                await loader.loadAlbums(for: user, yearOffset: newOffset)
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
                            Text("\(loader.getYear(for: currentYearOffset - 1))")
                                .font(.title2.weight(.medium))
                                .foregroundColor(.vinylogueBlue)
                            
                            Image(systemName: "arrow.right")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.vinylogueBlue)
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
                                .foregroundColor(.vinylogueBlue)
                            
                            Text("\(loader.getYear(for: currentYearOffset + 1))")
                                .font(.title2.weight(.medium))
                                .foregroundColor(.vinylogueBlue)
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
    @State private var rotation = 0.0
    
    var body: some View {
        Image(systemName: "record.circle")
            .font(.title2)
            .foregroundColor(.vinylogueBlue)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    let username: String
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.vinylogueBlue)
            
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
    .environment(\.playCountFilter, 1)
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