import Dependencies
import Nuke
import NukeUI
import SwiftUI

struct AlbumDetailView: View {
    @Bindable var store: AlbumDetailStore

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
        .background(store.animatedBackgroundColor)
        .toolbarVisibility(.visible, for: .navigationBar) // This doesn't work for some reason
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(Material.ultraThin, for: .navigationBar)
        .task {
            await store.loadAlbumDetails()
        }
        .task(id: store.representativeColors != nil) {
            store.startColorAnimation()
        }
        .navigationTint(store.textColor)
    }

    // MARK: - View Components

    @ViewBuilder
    private var backgroundArtworkSection: some View {
        Group {
            if let imageURL = store.album.detail?.imageURL, let url = URL(string: imageURL) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 25)
                            .opacity(0.6)
                            .clipped()
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
        ReusableAlbumArtworkView.flexible(
            imageURL: store.album.detail?.imageURL,
            imagePipeline: store.imagePipeline,
            cornerRadius: 6,
            showShadow: true,
            onImageLoaded: { uiImage in
                store.extractRepresentativeColors(from: uiImage)
            }
        )
    }

    @ViewBuilder
    private var albumInfoSection: some View {
        VStack(spacing: 2) {
            Text(store.album.artist.uppercased())
                .font(.f(.regular, .subheadline))
                .foregroundColor(store.textColor.opacity(0.85))
                .shadow(color: store.shadowColor, radius: 0, x: 0, y: 0.5)
                .multilineTextAlignment(.center)

            Text(store.album.name)
                .font(.f(.demiBold, .title1))
                .foregroundColor(store.textColor.opacity(0.95))
                .shadow(color: store.shadowColor, radius: 0, x: 0, y: 0.5)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }

    @ViewBuilder
    var playCountSection: some View {
        // TODO: correct labels
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                playCountBlock(count: store.album.playCount.formatted(), period: store.weekInfo.displayText)
                playCountBlock(count: store.album.detail?.userPlayCount?.formatted() ?? "-", period: "all-time")
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
                .foregroundStyle(store.textColor.opacity(0.85))
                .padding(.bottom, -5)
            Text("plays")
                .font(.f(.ultralight, .subheadline))
                .foregroundStyle(store.textColor.opacity(0.7))
            Text(period)
                .font(.f(.regular, .body))
                .foregroundStyle(store.textColor.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.isLoadingDetails {
                HStack {
                    AnimatedLoadingIndicator(size: 32)
                    Text("loading album details...")
                        .font(.f(.regular, .body))
                        .foregroundColor(store.textColor.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if let description = store.album.detail?.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("about this album")
                        .font(.f(.demiBold, .title1))
                        .foregroundColor(store.textColor.opacity(0.6))

                    Text(description)
                        .font(.f(.regular, .body))
                        .foregroundColor(store.textColor.opacity(0.95))
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
            } else if store.album.detail != nil {
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
}

// MARK: - Preview

#Preview("Album Detail") {
    let album: UserChartAlbum = {
        var album = UserChartAlbum(username: "ybsd", weekNumber: 3, year: 1949, name: "The Amulet", artist: "Circa Survive", playCount: 181, rank: nil, url: "https://www.last.fm/music/Circa+Survive/The+Amulet", mbid: nil)
        album.detail = UserChartAlbum.Detail(
            imageURL: "https://lastfm.freetls.fastly.net/i/u/300x300/771d0911b2ad83def05210412c7cec1c.jpg",
            description: "This album was released on September 22nd, 2017 through Hopeless Records.",
            totalPlayCount: 0,
            userPlayCount: 181
        )
        return album
    }()

    NavigationStack {
        let store = AlbumDetailStore(album: album, weekInfo: .init(weekNumber: 3, year: 1949, username: "ybsd"))
        AlbumDetailView(store: store)
    }
}
