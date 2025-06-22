import Dependencies
import Nuke
import SwiftUI

@MainActor
@Observable
final class AlbumDetailStore: Hashable {
    @ObservationIgnored @Dependency(\.lastFMClient) private var lastFMClient
    @ObservationIgnored @Dependency(\.imagePipeline) var imagePipeline

    var album: UserChartAlbum
    var artworkImage: UIImage?
    var representativeColors: ColorExtraction.RepresentativeColors?
    var isLoadingDetails = false
    var shouldAnimateColors = false

    let weekInfo: WeekInfo

    var animatedBackgroundColor: Color {
        if shouldAnimateColors, let representativeColors {
            return representativeColors.primary
        }
        return Color.vinylogueWhiteSubtle
    }

    var textColor: Color {
        if shouldAnimateColors, let representativeColors {
            return representativeColors.text
        }
        return Color.vinylogueBlueDark
    }

    var shadowColor: Color {
        if shouldAnimateColors, let representativeColors {
            return representativeColors.textShadow
        }
        return Color.clear
    }

    init(album: UserChartAlbum, weekInfo: WeekInfo) {
        self.album = album
        self.weekInfo = weekInfo
    }

    func loadAlbumDetails() async {
        guard album.detail == nil else { return }

        isLoadingDetails = true

        do {
            let detailedAlbum = try await lastFMClient.fetchAlbumInfo(
                artist: album.artist,
                album: album.name,
                mbid: album.mbid,
                username: weekInfo.username
            )

            album.detail = UserChartAlbum.Detail(
                imageURL: detailedAlbum.imageURL,
                description: detailedAlbum.description,
                totalPlayCount: detailedAlbum.totalPlayCount,
                userPlayCount: detailedAlbum.userPlayCount
            )

        } catch {
            album.detail = UserChartAlbum.Detail(
                imageURL: nil,
                description: nil,
                totalPlayCount: nil,
                userPlayCount: nil
            )
        }

        isLoadingDetails = false
    }

    func extractRepresentativeColors(from image: UIImage?) {
        guard let image else { return }
        artworkImage = image
        representativeColors = ColorExtraction.extractRepresentativeColors(from: image)
    }

    func startColorAnimation() {
        guard representativeColors != nil else { return }
        withAnimation(.easeIn(duration: 0.75).delay(0.15)) {
            shouldAnimateColors = true
        }
    }

    // MARK: - Hashable

    nonisolated static func == (lhs: AlbumDetailStore, rhs: AlbumDetailStore) -> Bool {
        // For navigation purposes, we'll use object identity
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
