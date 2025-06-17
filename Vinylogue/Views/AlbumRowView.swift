import Nuke
import NukeUI
import SwiftUI

struct AlbumRowView: View {
    @Binding var album: Album
    let namespace: Namespace.ID
    @Environment(\.lastFMClient) private var lastFMClient

    private var albumImageURL: String? {
        album.imageURL
    }

    var body: some View {
        NavigationLink(destination: AlbumDetailView(album: $album, namespace: namespace)) {
            HStack(spacing: 12) {
                // Album artwork with matched geometry effect
                AlbumArtworkView(imageURL: albumImageURL)
                    .frame(width: 80, height: 80)

                // Album and artist info
                VStack(alignment: .leading, spacing: 2) {
                    // Artist name (small, gray, uppercase)
                    Text(album.artist.uppercased())
                        .font(.scaledCaption())
                        .foregroundColor(.tertiaryText)
                        .lineLimit(1)

                    // Album name (medium, black)
                    Text(album.name)
                        .font(.scaledBody())
                        .foregroundColor(.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Play count
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(album.playCount)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.vinylogueBlueBold)

                    Text("plays")
                        .font(.scaledCaption())
                        .foregroundColor(.tertiaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primaryBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .task(id: album.id) {
            // Load album artwork URL if not already available
            if album.imageURL == nil {
                await loadAlbumArtwork()
            }
        }
    }

    @MainActor
    private func loadAlbumArtwork() async {
        do {
            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                artist: album.artist,
                album: album.name,
                mbid: album.mbid,
                username: nil as String?
            )
            album.imageURL = detailedAlbum.imageURL
        } catch {
            // If we can't load the details, we'll show the placeholder
            album.imageURL = nil
        }
    }
}

// MARK: - Album Artwork View

private struct AlbumArtworkView: View {
    let imageURL: String?

    var body: some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.error != nil {
                        placeholderView
                    } else {
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.vinylogueGray)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .fill(Color.vinylogueGray)
                            .frame(width: 8, height: 8)
                    }
            }
    }
}

// MARK: - Preview

#Preview("Album Row") {
    @Previewable @Namespace var namespace
    @Previewable @State var album1 = Album(
        name: "The Sea of Tragic Beasts",
        artist: "Fit For An Autopsy",
        imageURL: nil,
        playCount: 20,
        rank: 1
    )
    @Previewable @State var album2 = Album(
        name: "Is This Thing Cursed?",
        artist: "Alkaline Trio",
        imageURL: nil,
        playCount: 25,
        rank: 2
    )
    @Previewable @State var album3 = Album(
        name: "A Very Long Album Title That Should Be Truncated Properly",
        artist: "An Artist With A Long Name",
        imageURL: nil,
        playCount: 5,
        rank: 3
    )

    return VStack(spacing: 0) {
        AlbumRowView(album: $album1, namespace: namespace)

        Divider()

        AlbumRowView(album: $album2, namespace: namespace)

        Divider()

        AlbumRowView(album: $album3, namespace: namespace)
    }
    .background(Color.primaryBackground)
    .environment(\.lastFMClient, LastFMClient.shared)
}
