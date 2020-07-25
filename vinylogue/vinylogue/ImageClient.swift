import Combine
import ComposableArchitecture
import Foundation
import ImagePublisher
import Nuke
import UIKit.UIImage

struct ImageClient {
    let fetchImage: (URL) -> Effect<UIImage, Error>
    let fetchImageColors: (UIImage) -> Effect<ImageColors, Error>
}

extension ImageClient {
    struct Error: Swift.Error, Equatable {}
}

extension ImageClient {
    static let live = Self(
        fetchImage: { url -> Effect<UIImage, Error> in
            ImagePipeline.shared.imagePublisher(with: url)
                .mapError { _ in Self.Error() }
                .map { $0.image }
                .eraseToEffect()
        },
        fetchImageColors: { image -> Effect<ImageColors, Error> in
            Future<ImageColors, Error> { promise in
                do {
                    let imageColors = try colors(for: image)
                    promise(.success(imageColors))
                } catch {
                    promise(.failure(Error()))
                }
            }
            .eraseToEffect()
        }
    )

    static let mock = Self(
        fetchImage: { url -> Effect<UIImage, Error> in
            Just(UIImage(named: "recordPlaceholderThumb")!)
                .mapError { _ in Self.Error() }
                .eraseToEffect()
        },
        fetchImageColors: { image -> Effect<ImageColors, Error> in
            fatalError()
        }
    )
}

extension ImageClient {
    struct ImageColors: Equatable {
        let primaryColor: UIColor
        let secondaryColor: UIColor
        let averageColor: UIColor
        let textColor: UIColor
        let textShadowColor: UIColor
    }

    private static func colors(for image: UIImage) throws -> ImageColors {
        guard let cgImage = image.cgImage else { throw Error() }
        let scaledSize = CGSize(width: 60, height: 60)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let (width, height) = (Int(scaledSize.width), Int(scaledSize.height))
        let maxColorValueDifference: Double = 0.35

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        else { throw Error() }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        struct RGBA {
            var r: Double
            var g: Double
            var b: Double
            var a: Double
            var brightness: Double { 0.299 * r + 0.587 * g + 0.114 * b }

            func withinBounds(_ maxColorValueDifference: Double, total: RGBA) -> Bool {
                fabs(total.r - r) < maxColorValueDifference
                    && fabs(total.g - g) < maxColorValueDifference
                    && fabs(total.b - b) < maxColorValueDifference
                    && fabs(total.a - a) < maxColorValueDifference
            }

            var color: UIColor { UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a)) }
        }

        struct RGBAAccumulator {
            private var r: Double = 0
            private var g: Double = 0
            private var b: Double = 0
            private var a: Double = 0
            private var count: Int = 0

            mutating func append(_ value: RGBA) {
                r += value.r
                g += value.g
                b += value.b
                a += value.a
                count += 1
            }

            var average: RGBA {
                let c = Double(count)
                return RGBA(
                    r: r / max(c, 1.0),
                    g: g / max(c, 1.0),
                    b: b / max(c, 1.0),
                    a: a / max(c, 1.0)
                )
            }
        }

        func enumerateRGBAContext(_ context: CGContext, handler: (Int, Int, RGBA) -> Void) {
            struct RGBAPixel {
                let r: UInt8
                let g: UInt8
                let b: UInt8
                let a: UInt8
            }
            let (width, height) = (context.width, context.height)
            let data = unsafeBitCast(context.data, to: UnsafeMutablePointer<RGBAPixel>.self)
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let pixel = data[Int(x + y * width)]
                    let rgba = RGBA(
                        r: Double(pixel.r) / 255.0,
                        g: Double(pixel.g) / 255.0,
                        b: Double(pixel.b) / 255.0,
                        a: Double(pixel.a) / 255.0
                    )
                    handler(x, y, rgba)
                }
            }
        }

        // First pass: find the average color of the entire image,
        // discarding pixels that are too dark or too bright.
        var totalAccumulator = RGBAAccumulator()
        enumerateRGBAContext(context) { _, _, value in
            if (0.06 ... 0.94).contains(value.brightness) {
                totalAccumulator.append(value)
            }
        }
        let total = totalAccumulator.average

        // Second pass: categorize pixels as `primary` if they are
        // close to the image average.
        var primaryAccumulator = RGBAAccumulator()
        var secondaryAccumulator = RGBAAccumulator()
        enumerateRGBAContext(context) { _, _, value in
            if (0.06 ... 0.94).contains(value.brightness) {
                if value.withinBounds(maxColorValueDifference, total: total) {
                    primaryAccumulator.append(value)
                } else {
                    secondaryAccumulator.append(value)
                }
            }
        }
        let primary = primaryAccumulator.average
        let secondary = secondaryAccumulator.average

        let textWhite: CGFloat
        let textShadowWhite: CGFloat
        if primary.brightness < 0.6 {
            textWhite = 1.0
            textShadowWhite = 0.0
        } else {
            textWhite = 0.0
            textShadowWhite = 1.0
        }
        let textColor = UIColor(white: textWhite, alpha: 1.0)
        let textShadowColor = UIColor(white: textShadowWhite, alpha: 1.0)

        let imageColors = ImageColors(
            primaryColor: primary.color,
            secondaryColor: secondary.color,
            averageColor: total.color,
            textColor: textColor,
            textShadowColor: textShadowColor
        )

        return imageColors
    }
}
