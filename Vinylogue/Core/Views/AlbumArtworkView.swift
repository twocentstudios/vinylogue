import CoreImage
import Nuke
import NukeUI
import Sharing
import SwiftUI

struct ReusableAlbumArtworkView: View {
    let imageURL: String?
    let size: CGFloat?
    let cornerRadius: CGFloat
    let showShadow: Bool
    let onImageLoaded: ((UIImage?) -> Void)?
    let imagePipeline: ImagePipeline
    @State private var isImageLoaded = false
    @Shared(.pixelationEnabled) private var pixelationEnabled

    init(
        imageURL: String?,
        imagePipeline: ImagePipeline,
        size: CGFloat? = nil,
        cornerRadius: CGFloat = 4,
        showShadow: Bool = false,
        onImageLoaded: ((UIImage?) -> Void)? = nil
    ) {
        self.imageURL = imageURL
        self.imagePipeline = imagePipeline
        self.size = size
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.onImageLoaded = onImageLoaded
    }

    var body: some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                let processors: [ImageProcessing] = pixelationEnabled ? [PixelateProcessor()] : []
                let request = ImageRequest(url: url, processors: processors)

                LazyImage(request: request) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .task {
                                isImageLoaded = true
                                onImageLoaded?(state.imageContainer?.image)
                            }
                    } else if state.error != nil {
                        placeholderView
                    } else {
                        placeholderView
                    }
                }
                .pipeline(imagePipeline)
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
        .accessibilityIdentifier(isImageLoaded ? "imageLoaded" : "imageLoading")
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
        imagePipeline: ImagePipeline,
        size: CGFloat = 80,
        cornerRadius: CGFloat = 4
    ) -> ReusableAlbumArtworkView {
        ReusableAlbumArtworkView(
            imageURL: imageURL,
            imagePipeline: imagePipeline,
            size: size,
            cornerRadius: cornerRadius,
            showShadow: false,
            onImageLoaded: nil
        )
    }

    /// Creates an album artwork view with aspect ratio (for detail views)
    static func flexible(
        imageURL: String?,
        imagePipeline: ImagePipeline,
        cornerRadius: CGFloat = 6,
        showShadow: Bool = true,
        onImageLoaded: ((UIImage?) -> Void)? = nil
    ) -> ReusableAlbumArtworkView {
        ReusableAlbumArtworkView(
            imageURL: imageURL,
            imagePipeline: imagePipeline,
            size: nil,
            cornerRadius: cornerRadius,
            showShadow: showShadow,
            onImageLoaded: onImageLoaded
        )
    }
}

// MARK: - Pixelate Processor for UI Testing

struct PixelateProcessor: ImageProcessing, Hashable {
    let scale: Float

    init(scale: Float = 50.0) {
        self.scale = scale
    }

    func process(_ image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return image }

        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: CGPoint(x: inputImage.extent.midX, y: inputImage.extent.midY)), forKey: kCIInputCenterKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)

        guard let outputImage = filter.outputImage else { return image }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    var identifier: String {
        "PixelateProcessor-\(scale)"
    }
}
