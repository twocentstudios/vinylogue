import Dependencies
import Nuke
import NukeUI
import SwiftUI

struct AlbumRowView: View {
    @Binding var album: Album
    @Dependency(\.lastFMClient) private var lastFMClient

    private var albumImageURL: String? {
        album.imageURL
    }

    var body: some View {
        HStack(spacing: 12) {
            AlbumArtworkView(imageURL: albumImageURL)
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 2) {
                Text(album.artist.uppercased())
                    .font(.f(.ultralight, .caption1))
                    .lineLimit(1)
                    .padding(.vertical, -1)

                Text(album.name)
                    .font(.f(.regular, .body))
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 1)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, -1)
            }

            Spacer()

            VStack(alignment: .center, spacing: 0) {
                Text("\(album.playCount)")
                    .font(.f(.regular, .title2))
                    .padding(.vertical, -3)

                Text("plays")
                    .font(.f(.ultralight, .caption1))
                    .padding(.vertical, -3)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 18)
        .padding(.vertical, 10)
        .background(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.8)).frame(height: 1)
        }
        .background(alignment: .bottom) {
            Rectangle().fill(Color.black.opacity(0.1)).frame(height: 1)
        }
        .contentShape(Rectangle())
        .task(id: album.id) {
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
            album.imageURL = nil
        }
    }
}

struct AlbumRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .vinylogueWhiteSubtle : .vinylogueBlueDark)
            .background(configuration.isPressed ? Color.vinylogueBlueDark : Color.vinylogueWhiteSubtle)
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
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
        AlbumRowView(album: $album1)

        Divider()

        AlbumRowView(album: $album2)

        Divider()

        AlbumRowView(album: $album3)
    }
    .background(Color.primaryBackground)
}
