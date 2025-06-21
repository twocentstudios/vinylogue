import Nuke
import NukeUI
import SwiftUI

struct AlbumRowView: View {
    let album: UserChartAlbum

    var body: some View {
        HStack(spacing: 12) {
            ReusableAlbumArtworkView.fixedSize(imageURL: album.detail?.imageURL, size: 80)

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
    }
}

struct AlbumRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .vinylogueWhiteSubtle : .vinylogueBlueDark)
            .background(configuration.isPressed ? Color.vinylogueBlueDark : Color.vinylogueWhiteSubtle)
    }
}

// MARK: - Preview

#Preview("Album Row") {
    let album1 = UserChartAlbum(
        username: "testuser",
        weekNumber: 1,
        year: 2024,
        name: "The Sea of Tragic Beasts",
        artist: "Fit For An Autopsy",
        playCount: 20,
        rank: 1
    )
    let album2 = UserChartAlbum(
        username: "testuser",
        weekNumber: 1,
        year: 2024,
        name: "Is This Thing Cursed?",
        artist: "Alkaline Trio",
        playCount: 25,
        rank: 2
    )
    let album3 = UserChartAlbum(
        username: "testuser",
        weekNumber: 1,
        year: 2024,
        name: "A Very Long Album Title That Should Be Truncated Properly",
        artist: "An Artist With A Long Name",
        playCount: 5,
        rank: 3
    )

    return VStack(spacing: 0) {
        AlbumRowView(album: album1)

        Divider()

        AlbumRowView(album: album2)

        Divider()

        AlbumRowView(album: album3)
    }
    .background(Color.primaryBackground)
}
