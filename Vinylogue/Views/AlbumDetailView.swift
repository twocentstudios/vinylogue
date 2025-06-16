import Nuke
import NukeUI
import SwiftUI

struct AlbumDetailView: View {
    @Binding var album: Album
    @State private var artworkImage: UIImage?
    @State private var dominantColor: Color = .gray
    @State private var isLoadingDetails = false
    @Environment(\.lastFMClient) private var lastFMClient

    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            // Dynamic gradient background
            ColorExtraction.createBackgroundGradient(from: dominantColor)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: dominantColor)

            ScrollView {
                VStack(spacing: 24) {
                    // Album artwork
                    artworkSection

                    // Album information
                    albumInfoSection

                    // Description section
                    descriptionSection

                    Spacer(minLength: 100) // Extra space at bottom
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark) // Force dark mode for better contrast
        .task {
            await loadAlbumDetails()
        }
    }

    // MARK: - View Components

    private var artworkSection: some View {
        VStack(spacing: 16) {
            // Album artwork with matched geometry effect
            Group {
                if let imageURL = album.imageURL, let url = URL(string: imageURL) {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .onAppear {
                                    // Extract dominant color from loaded image
                                    extractDominantColor(from: state.imageContainer?.image)
                                }
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
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    private var albumPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
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
        VStack(spacing: 12) {
            // Album title
            Text(album.name)
                .font(.title.weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            // Artist name
            Text(album.artist.uppercased())
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            // Play count
            HStack(spacing: 4) {
                Text("\(album.playCount)")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                Text("plays")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Rank if available
            if let rank = album.rank {
                Text("Ranked #\(rank)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingDetails {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)

                    Text("Loading album details...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let description = album.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
            } else if album.isDetailLoaded {
                // No description available
                Text("No description available for this album.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Methods

    private func extractDominantColor(from platformImage: PlatformImage?) {
        guard let platformImage else { return }

        #if os(iOS)
            let uiImage = platformImage
        #else
            // Convert NSImage to UIImage if needed for macOS
            let uiImage = UIImage(data: platformImage.tiffRepresentation!)!
        #endif

        // Store the image for future reference
        artworkImage = uiImage

        // Extract dominant color
        if let extractedColor = album.dominantColor(from: uiImage) {
            withAnimation(.easeInOut(duration: 0.6)) {
                dominantColor = extractedColor
            }
        }
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
