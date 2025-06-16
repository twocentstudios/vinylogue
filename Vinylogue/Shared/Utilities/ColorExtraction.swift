import CoreImage
import SwiftUI
import UIKit

/// Utility for extracting representative colors from images
/// Direct port of the algorithm from vinylogue-legacy/UIImage+TCSImageRepresentativeColors.m
enum ColorExtraction {
    /// Container for the representative colors extracted from an image
    struct RepresentativeColors {
        let primary: Color
        let secondary: Color
        let average: Color
        let text: Color
        let textShadow: Color
    }

    /// Extracts representative colors from an image using the legacy algorithm
    /// - Parameter image: The UIImage to analyze
    /// - Returns: RepresentativeColors containing primary, secondary, average, text, and text shadow colors
    static func extractRepresentativeColors(from image: UIImage) -> RepresentativeColors? {
        guard let cgImage = image.cgImage else { return nil }
        guard let context = createARGBBitmapContext(from: cgImage) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        // Draw the image to the bitmap context
        context.draw(cgImage, in: rect)

        // Get pointer to the image data
        guard let data = context.data?.bindMemory(to: UInt8.self, capacity: width * height * 4) else {
            return nil
        }

        // First pass: calculate average color excluding very bright and very dark pixels
        var totalAlpha = 0.0, totalRed = 0.0, totalGreen = 0.0, totalBlue = 0.0
        var totalColorsInSet = 0.0

        for x in 0 ..< width {
            for y in 0 ..< height {
                let offset = 4 * (width * y + x)
                let alpha = Double(data[offset]) / 255.0
                let red = Double(data[offset + 1]) / 255.0
                let green = Double(data[offset + 2]) / 255.0
                let blue = Double(data[offset + 3]) / 255.0
                let brightness = 0.299 * red + 0.587 * green + 0.114 * blue

                // Exclude too bright and too dark pixels
                if brightness > 0.05, brightness < 0.95 {
                    totalRed += red
                    totalGreen += green
                    totalBlue += blue
                    totalAlpha += alpha
                    totalColorsInSet += 1.0
                }
            }
        }

        // Calculate averages
        let avgRed = totalRed / max(totalColorsInSet, 1.0)
        let avgGreen = totalGreen / max(totalColorsInSet, 1.0)
        let avgBlue = totalBlue / max(totalColorsInSet, 1.0)
        let avgAlpha = totalAlpha / max(totalColorsInSet, 1.0)

        // Second pass: separate colors into primary and secondary bins
        var primaryAlpha = 0.0, primaryRed = 0.0, primaryGreen = 0.0, primaryBlue = 0.0
        var primaryColorsInSet = 0.0
        var secondaryAlpha = 0.0, secondaryRed = 0.0, secondaryGreen = 0.0, secondaryBlue = 0.0
        var secondaryColorsInSet = 0.0

        let maxColorValueDifference = 0.35

        for x in 0 ..< width {
            for y in 0 ..< height {
                let offset = 4 * (width * y + x)
                let alpha = Double(data[offset]) / 255.0
                let red = Double(data[offset + 1]) / 255.0
                let green = Double(data[offset + 2]) / 255.0
                let blue = Double(data[offset + 3]) / 255.0
                let brightness = 0.299 * red + 0.587 * green + 0.114 * blue

                // Exclude too bright and too dark pixels
                if brightness > 0.05, brightness < 0.95 {
                    // Check if the color falls within bounds of the average
                    let deltaAlpha = abs(avgAlpha - alpha) < maxColorValueDifference
                    let deltaRed = abs(avgRed - red) < maxColorValueDifference
                    let deltaGreen = abs(avgGreen - green) < maxColorValueDifference
                    let deltaBlue = abs(avgBlue - blue) < maxColorValueDifference

                    if deltaAlpha, deltaRed, deltaGreen, deltaBlue {
                        // Primary color bin (similar to average)
                        primaryRed += red
                        primaryGreen += green
                        primaryBlue += blue
                        primaryAlpha += alpha
                        primaryColorsInSet += 1.0
                    } else {
                        // Secondary color bin (different from average)
                        secondaryRed += red
                        secondaryGreen += green
                        secondaryBlue += blue
                        secondaryAlpha += alpha
                        secondaryColorsInSet += 1.0
                    }
                }
            }
        }

        // Calculate final averages
        let finalPrimaryRed = primaryRed / max(primaryColorsInSet, 1.0)
        let finalPrimaryGreen = primaryGreen / max(primaryColorsInSet, 1.0)
        let finalPrimaryBlue = primaryBlue / max(primaryColorsInSet, 1.0)
        let finalPrimaryAlpha = primaryAlpha / max(primaryColorsInSet, 1.0)

        let finalSecondaryRed = secondaryRed / max(secondaryColorsInSet, 1.0)
        let finalSecondaryGreen = secondaryGreen / max(secondaryColorsInSet, 1.0)
        let finalSecondaryBlue = secondaryBlue / max(secondaryColorsInSet, 1.0)
        let finalSecondaryAlpha = secondaryAlpha / max(secondaryColorsInSet, 1.0)

        // Calculate text colors based on primary color brightness
        let primaryBrightness = 0.299 * finalPrimaryRed + 0.587 * finalPrimaryGreen + 0.114 * finalPrimaryBlue
        let textGray = primaryBrightness < 0.6 ? 1.0 : 0.0
        let textShadowGray = primaryBrightness < 0.6 ? 0.0 : 1.0

        return RepresentativeColors(
            primary: Color(.sRGB, red: finalPrimaryRed, green: finalPrimaryGreen, blue: finalPrimaryBlue, opacity: finalPrimaryAlpha),
            secondary: Color(.sRGB, red: finalSecondaryRed, green: finalSecondaryGreen, blue: finalSecondaryBlue, opacity: finalSecondaryAlpha),
            average: Color(.sRGB, red: avgRed, green: avgGreen, blue: avgBlue, opacity: avgAlpha),
            text: Color(.sRGB, red: textGray, green: textGray, blue: textGray, opacity: 1.0),
            textShadow: Color(.sRGB, red: textShadowGray, green: textShadowGray, blue: textShadowGray, opacity: 1.0)
        )
    }

    /// Extracts the primary color from an image (for backward compatibility)
    /// - Parameter image: The UIImage to analyze
    /// - Returns: The primary color or nil if extraction fails
    static func dominantColor(from image: UIImage) -> Color? {
        extractRepresentativeColors(from: image)?.primary
    }

    /// Creates an ARGB bitmap context from a CGImage
    /// - Parameter cgImage: The CGImage to create context for
    /// - Returns: A CGContext configured for ARGB bitmap rendering
    private static func createARGBBitmapContext(from cgImage: CGImage) -> CGContext? {
        let width = cgImage.width
        let height = cgImage.height
        let bitmapBytesPerRow = width * 4
        _ = bitmapBytesPerRow * height

        // Use the generic RGB color space
        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
            return nil
        }

        // Create the bitmap context with pre-multiplied ARGB, 8-bits per component
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        return context
    }

    /// Enhances a color for better UI contrast by adjusting saturation and brightness
    /// - Parameter color: The input color to enhance
    /// - Returns: An enhanced version of the color suitable for UI backgrounds
    static func enhanceForUI(_ color: Color) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Enhance saturation for more vibrant colors
        let enhancedSaturation = min(saturation * 1.3, 1.0)

        // Adjust brightness to ensure good contrast
        let enhancedBrightness = brightness < 0.5 ? brightness * 1.2 : brightness * 0.8

        let enhancedColor = UIColor(hue: hue,
                                    saturation: enhancedSaturation,
                                    brightness: enhancedBrightness,
                                    alpha: alpha)

        return Color(enhancedColor)
    }

    /// Creates a gradient suitable for backgrounds from a dominant color
    /// - Parameter dominantColor: The dominant color extracted from an image
    /// - Returns: A LinearGradient for use in backgrounds
    static func createBackgroundGradient(from dominantColor: Color) -> LinearGradient {
        let enhancedColor = enhanceForUI(dominantColor)

        return LinearGradient(
            colors: [
                enhancedColor,
                enhancedColor.opacity(0.8),
                Color.black.opacity(0.9),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    /// Extracts the dominant color from this image
    var dominantColor: Color? {
        ColorExtraction.dominantColor(from: self)
    }
}
