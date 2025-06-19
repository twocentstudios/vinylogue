import NukeUI
import SwiftUI

struct ReusableAlbumArtworkView: View {
    let imageURL: String?
    let size: CGFloat?
    let cornerRadius: CGFloat
    let showShadow: Bool
    let onImageLoaded: ((UIImage?) -> Void)?

    init(
        imageURL: String?,
        size: CGFloat? = nil,
        cornerRadius: CGFloat = 4,
        showShadow: Bool = false,
        onImageLoaded: ((UIImage?) -> Void)? = nil
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.onImageLoaded = onImageLoaded
    }

    var body: some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .task {
                                onImageLoaded?(state.imageContainer?.image)
                            }
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
        .applyFraming(size: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(
            color: showShadow ? .black.opacity(0.2) : .clear,
            radius: showShadow ? 4 : 0,
            x: 0,
            y: showShadow ? 1 : 0
        )
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.vinylogueGray)
            .overlay {
                Circle()
                    .fill(Color.vinylogueWhiteSubtle)
                    .overlay {
                        Circle()
                            .fill(Color.vinylogueGray)
                            .scaleEffect(size != nil ? 0.2 : 0.2) // Adjust inner circle size
                    }
                    .scaleEffect(size != nil ? 0.5 : 0.5) // Adjust outer circle size
            }
            .applyFraming(size: size)
    }
}

private extension View {
    @ViewBuilder
    func applyFraming(size: CGFloat?) -> some View {
        if let size {
            frame(width: size, height: size)
        } else {
            aspectRatio(1.0, contentMode: .fit)
        }
    }
}

// MARK: - Convenience Initializers

extension ReusableAlbumArtworkView {
    /// Creates an album artwork view with fixed size (for use in lists/rows)
    static func fixedSize(
        imageURL: String?,
        size: CGFloat = 80,
        cornerRadius: CGFloat = 4
    ) -> ReusableAlbumArtworkView {
        ReusableAlbumArtworkView(
            imageURL: imageURL,
            size: size,
            cornerRadius: cornerRadius,
            showShadow: false,
            onImageLoaded: nil
        )
    }

    /// Creates an album artwork view with aspect ratio (for detail views)
    static func flexible(
        imageURL: String?,
        cornerRadius: CGFloat = 6,
        showShadow: Bool = true,
        onImageLoaded: ((UIImage?) -> Void)? = nil
    ) -> ReusableAlbumArtworkView {
        ReusableAlbumArtworkView(
            imageURL: imageURL,
            size: nil,
            cornerRadius: cornerRadius,
            showShadow: showShadow,
            onImageLoaded: onImageLoaded
        )
    }
}
