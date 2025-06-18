import Dependencies
import Nuke
import NukeUI
import SwiftUI

struct AlbumDetailView: View {
    @State private var album: Album
    @State private var artworkImage: UIImage?
    @State private var representativeColors: ColorExtraction.RepresentativeColors?
    @State private var isLoadingDetails = false
    @Dependency(\.lastFMClient) private var lastFMClient

    init(album: Album) {
        _album = State(initialValue: album)
    }

    var body: some View {
        ZStack {
            (representativeColors?.primary ?? Color.gray)
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        backgroundArtworkSection

                        VStack(spacing: 20) {
                            artworkSection

                            albumInfoSection
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                    }

                    descriptionSection
                        .padding(.horizontal, 30)

                    Spacer(minLength: 100) // Extra space at bottom
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAlbumDetails()
        }
    }

    // MARK: - View Components

    private var backgroundArtworkSection: some View {
        Group {
            if let imageURL = album.imageURL, let url = URL(string: imageURL) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 15)
                            .opacity(0.3)
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
        .frame(width: 280, height: 280)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
    }

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

    private var albumInfoSection: some View {
        VStack(spacing: 8) {
            Text(album.artist.uppercased())
                .font(.f(.regular, .caption1))
                .foregroundColor(textColor.opacity(0.85))
                .multilineTextAlignment(.center)

            Text(album.name)
                .font(.title.weight(.bold))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    VStack(spacing: 2) {
                        Text("\(album.playCount)")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(textColor)

                        Text("plays")
                            .font(.caption)
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                            )
                    )

                    VStack(spacing: 2) {
                        Text("\(album.totalPlayCount ?? 0)")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(textColor)

                        Text("all-time")
                            .font(.caption)
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingDetails {
                HStack {
                    AnimatedLoadingIndicator(size: 32)

                    Text("Loading album details...")
                        .font(.body)
                        .foregroundColor(textColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let description = album.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("about this album")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(textColor)

                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.9))
                        )
                }
            } else if album.isDetailLoaded {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textColor: Color {
        representativeColors?.text ?? .primary
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
    let album = Album(
        name: "The Sea of Tragic Beasts",
        artist: "Fit For An Autopsy",
        imageURL: "https://lastfm.freetls.fastly.net/i/u/300x300/example.jpg",
        playCount: 42,
        rank: 1
    )

    return NavigationStack {
        AlbumDetailView(album: album)
    }
}
