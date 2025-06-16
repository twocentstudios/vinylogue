import Nuke
import NukeUI
import SwiftUI

struct AlbumDetailView: View {
    @Binding var album: Album
    @State private var artworkImage: UIImage?
    @State private var representativeColors: ColorExtraction.RepresentativeColors?
    @State private var isLoadingDetails = false
    @Environment(\.lastFMClient) private var lastFMClient

    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            // Full screen dominant color background
            (representativeColors?.primary ?? Color.gray)
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: 24) {
                    // Album artwork section with blurred background
                    ZStack {
                        // Blurred background album art - only behind artwork and title
                        backgroundArtworkSection

                        VStack(spacing: 20) {
                            // Album artwork
                            artworkSection

                            // Album information
                            albumInfoSection
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                    }

                    // Description section (no blurred background)
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
                                // Extract representative colors from loaded image
                                extractRepresentativeColors(from: state.imageContainer?.image)
                            }
                    } else {
                        // Background for placeholder
                        Color.vinylrogueGray.opacity(0.2)
                    }
                }
            } else {
                Color.vinylrogueGray.opacity(0.2)
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
            .fill(Color.vinylrogueGray)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .fill(Color.vinylrogueGray)
                            .frame(width: 24, height: 24)
                    }
            }
    }

    private var albumInfoSection: some View {
        VStack(spacing: 8) {
            // Artist name (small, uppercase)
            Text(album.artist.uppercased())
                .font(.scaledCaption())
                .foregroundColor(textColor.opacity(0.85))
                .multilineTextAlignment(.center)

            // Album title (large, bold)
            Text(album.name)
                .font(.title.weight(.bold))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            // Play count and week info
            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    VStack(spacing: 2) {
                        Text("\(album.playCount)")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(textColor)

                        Text("week 25 2015") // TODO: Get from WeeklyAlbumLoader
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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)

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
                // No description available - don't show anything like legacy
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Computed text color based on representative colors
    private var textColor: Color {
        representativeColors?.text ?? .primary
    }

    // MARK: - Helper Methods

    private func extractRepresentativeColors(from platformImage: PlatformImage?) {
        guard let platformImage else { return }

        #if os(iOS)
            let uiImage = platformImage
        #else
            // Convert NSImage to UIImage if needed for macOS
            let uiImage = UIImage(data: platformImage.tiffRepresentation!)!
        #endif

        // Store the image for future reference
        artworkImage = uiImage

        // Extract representative colors using legacy algorithm
        representativeColors = ColorExtraction.extractRepresentativeColors(from: uiImage)
    }

    @MainActor
    private func loadAlbumDetails() async {
        // Skip if already loaded
        guard !album.isDetailLoaded else { return }

        isLoadingDetails = true

        do {
            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                artist: album.artist,
                album: album.name,
                mbid: album.mbid,
                username: nil
            )

            // Update album with detailed information
            album.description = detailedAlbum.description
            album.totalPlayCount = detailedAlbum.totalPlayCount
            album.userPlayCount = detailedAlbum.userPlayCount
            album.isDetailLoaded = true

        } catch {
            // Failed to load details - mark as loaded to prevent retries
            album.isDetailLoaded = true
        }

        isLoadingDetails = false
    }
}

// MARK: - Preview

#Preview("Album Detail") {
    @Previewable @Namespace var namespace
    @Previewable @State var album = Album(
        name: "The Sea of Tragic Beasts",
        artist: "Fit For An Autopsy",
        imageURL: "https://lastfm.freetls.fastly.net/i/u/300x300/example.jpg",
        playCount: 42,
        rank: 1
    )

    return NavigationStack {
        AlbumDetailView(album: $album, namespace: namespace)
    }
    .environment(\.lastFMClient, LastFMClient.shared)
}
