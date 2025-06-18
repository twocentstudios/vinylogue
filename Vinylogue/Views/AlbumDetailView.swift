import Dependencies
import Nuke
import NukeUI
import Sharing
import SwiftUI

struct AlbumDetailView: View {
    @State private var album: Album
    @State private var artworkImage: UIImage?
    @State private var representativeColors: ColorExtraction.RepresentativeColors?
    @State private var isLoadingDetails = false
    @Shared(.appStorage("currentUser")) var currentUsername: String?
    @Dependency(\.lastFMClient) private var lastFMClient

    init(album: Album) {
        _album = State(initialValue: album)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack {
                    artworkSection
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                    albumInfoSection
                        .padding(.bottom, 36)
                }
                .background {
                    backgroundArtworkSection
                }

                playCountSection

                descriptionSection

                Spacer(minLength: 100) // Extra space at bottom
            }
        }
        .background(representativeColors?.primary ?? Color.vinylogueWhiteSubtle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .task {
            await loadAlbumDetails()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var backgroundArtworkSection: some View {
        Group {
            if let imageURL = album.imageURL, let url = URL(string: imageURL) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 25)
                            .opacity(0.6)
                            .clipped()
                            .onAppear {
                                extractRepresentativeColors(from: state.imageContainer?.image)
                            }
                    } else {
                        Color.vinylogueGray.opacity(0.2)
                    }
                }
            } else {
                Color.vinylogueGray.opacity(0.2)
            }
        }
    }

    @ViewBuilder
    private var artworkSection: some View {
        Group {
            if let imageURL = album.imageURL, let url = URL(string: imageURL) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.error != nil {
                        albumPlaceholder
                    } else {
                        albumPlaceholder
                    }
                }
            } else {
                albumPlaceholder
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private var albumPlaceholder: some View {
        Rectangle()
            .fill(Color.vinylogueGray)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .fill(Color.vinylogueGray)
                            .frame(width: 24, height: 24)
                    }
            }
    }

    @ViewBuilder
    private var albumInfoSection: some View {
        VStack(spacing: 2) {
            Text(album.artist.uppercased())
                .font(.f(.regular, .subheadline))
                .foregroundColor(textColor.opacity(0.85))
                .shadow(color: shadowColor, radius: 0, x: 0, y: 0.5)
                .multilineTextAlignment(.center)

            Text(album.name)
                .font(.f(.demiBold, .title1))
                .foregroundColor(textColor.opacity(0.95))
                .shadow(color: shadowColor, radius: 0, x: 0, y: 0.5)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }

    @ViewBuilder
    var playCountSection: some View {
        // TODO: correct labels
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                playCountBlock(count: album.playCount.formatted(), period: "week 25 2015")
                playCountBlock(count: album.userPlayCount?.formatted() ?? "-", period: "all-time")
            }
        }
        .padding(.vertical, 12)
        .overlay {
            HStack(spacing: 0) {
                Spacer()
                Rectangle().fill(.white.opacity(0.35)).frame(width: 1)
                Rectangle().fill(.black.opacity(0.25)).frame(width: 1)
                Spacer()
            }
            .padding(.vertical, 1)
        }
        .overlay {
            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.35)).frame(height: 1)
                Spacer()
                Rectangle().fill(.black.opacity(0.25)).frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private func playCountBlock(count: String, period: String) -> some View {
        VStack(spacing: 0) {
            Text(count)
                .font(.f(.demiBold, .title1))
                .foregroundStyle(textColor.opacity(0.85))
                .padding(.bottom, -5)
            Text("plays")
                .font(.f(.ultralight, .subheadline))
                .foregroundStyle(textColor.opacity(0.7))
            Text(period)
                .font(.f(.regular, .title3))
                .foregroundStyle(textColor.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingDetails {
                HStack {
                    AnimatedLoadingIndicator(size: 32)
                    Text("loading album details...")
                        .font(.f(.regular, .body))
                        .foregroundColor(textColor.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let description = album.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("about this album")
                        .font(.f(.demiBold, .title1))
                        .foregroundColor(textColor.opacity(0.6))

                    Text(description)
                        .font(.f(.regular, .body))
                        .foregroundColor(textColor.opacity(0.95))
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
            } else if album.isDetailLoaded {
                EmptyView()
            }
        }
        .padding(.vertical, 50)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { Color.black.opacity(0.05) }
        .background(alignment: .bottom) {
            Color.black.opacity(0.25).frame(height: 1)
        }
    }

    private var textColor: Color {
        representativeColors?.text ?? Color.vinylogueBlueDark
    }

    private var shadowColor: Color {
        representativeColors?.textShadow ?? Color.clear
    }

    // MARK: - Helper Methods

    private func extractRepresentativeColors(from platformImage: PlatformImage?) {
        guard let platformImage else { return }

        #if os(iOS)
            let uiImage = platformImage
        #else
            let uiImage = UIImage(data: platformImage.tiffRepresentation!)!
        #endif

        artworkImage = uiImage

        representativeColors = ColorExtraction.extractRepresentativeColors(from: uiImage)
    }

    @MainActor
    private func loadAlbumDetails() async {
        guard !album.isDetailLoaded else { return }

        isLoadingDetails = true

        do {
            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                artist: album.artist,
                album: album.name,
                mbid: album.mbid,
                username: nil
            )

            album.description = detailedAlbum.description
            album.totalPlayCount = detailedAlbum.totalPlayCount
            album.userPlayCount = detailedAlbum.userPlayCount
            album.isDetailLoaded = true

        } catch {
            album.isDetailLoaded = true
        }

        isLoadingDetails = false
    }
}

// MARK: - Preview

#Preview("Album Detail") {
    let album: Album = {
        var album = Album(name: "The Amulet", artist: "Circa Survive", imageURL: "https://lastfm.freetls.fastly.net/i/u/300x300/771d0911b2ad83def05210412c7cec1c.jpg", playCount: 181, rank: nil, url: "https://www.last.fm/music/Circa+Survive/The+Amulet", mbid: nil)
        album.description = "This album was released on September 22nd, 2017 through Hopeless Records."
        album.totalPlayCount = 0
        album.userPlayCount = 181
        album.isDetailLoaded = true
        return album
    }()

    NavigationStack {
        AlbumDetailView(album: album)
    }
}
