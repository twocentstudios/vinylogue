import SwiftUI
import Nuke
import NukeUI

struct AlbumRowView: View {
    let album: Album
    let namespace: Namespace.ID
    @State private var albumImageURL: String?
    @Environment(\.lastFMClient) private var lastFMClient
    
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork with matched geometry effect
            NavigationLink(destination: AlbumDetailView(album: album, namespace: namespace)) {
                AlbumArtworkView(imageURL: albumImageURL)
                    .frame(width: 80, height: 80)
                    .matchedGeometryEffect(id: "album-\(album.id)", in: namespace)
            }
            .buttonStyle(PlainButtonStyle())
            
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
                    .foregroundColor(.vinylogueBlue)
                
                Text("plays")
                    .font(.scaledCaption())
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.primaryBackground)
        .task {
            // TODO: Load album artwork URL - deferred for Sprint 5
            // if albumImageURL == nil && !album.isDetailLoaded {
            //     await loadAlbumArtwork()
            // }
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
            albumImageURL = detailedAlbum.imageURL
        } catch {
            // If we can't load the details, we'll show the placeholder
            albumImageURL = nil
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
            .fill(Color.vinylrogueGray)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .fill(Color.vinylrogueGray)
                            .frame(width: 8, height: 8)
                    }
            }
    }
}


// MARK: - Preview

#Preview("Album Row") {
    @Previewable @Namespace var namespace
    
    return VStack(spacing: 0) {
        AlbumRowView(album: Album(
            name: "The Sea of Tragic Beasts",
            artist: "Fit For An Autopsy", 
            imageURL: nil,
            playCount: 20,
            rank: 1
        ), namespace: namespace)
        
        Divider()
        
        AlbumRowView(album: Album(
            name: "Is This Thing Cursed?",
            artist: "Alkaline Trio",
            imageURL: nil,
            playCount: 25,
            rank: 2
        ), namespace: namespace)
        
        Divider()
        
        AlbumRowView(album: Album(
            name: "A Very Long Album Title That Should Be Truncated Properly",
            artist: "An Artist With A Long Name",
            imageURL: nil,
            playCount: 5,
            rank: 3
        ), namespace: namespace)
    }
    .background(Color.primaryBackground)
    .environment(\.lastFMClient, LastFMClient.shared)
}