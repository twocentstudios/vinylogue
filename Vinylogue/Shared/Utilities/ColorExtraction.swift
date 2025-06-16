import UIKit
import CoreImage
import SwiftUI

/// Utility for extracting dominant colors from images using Core Image
struct ColorExtraction {
    private static let context = CIContext()
    
    /// Extracts the dominant color from an image using CIAreaAverage
    /// - Parameter image: The UIImage to analyze
    /// - Returns: A Color representing the dominant color, or nil if extraction fails
    static func dominantColor(from image: UIImage) -> Color? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Use CIAreaAverage to get the average color of the entire image
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Extract the single pixel color value
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)
        
        // Convert to SwiftUI Color
        let red = Double(bitmap[0]) / 255.0
        let green = Double(bitmap[1]) / 255.0
        let blue = Double(bitmap[2]) / 255.0
        let alpha = Double(bitmap[3]) / 255.0
        
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
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
                Color.black.opacity(0.9)
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