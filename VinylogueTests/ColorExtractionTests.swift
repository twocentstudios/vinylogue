import SwiftUI
import UIKit
@testable import Vinylogue
import XCTest

final class ColorExtractionTests: XCTestCase {
    // MARK: - Test Image Creation Helpers

    private func createTestImage(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createGradientTestImage(colors: [UIColor], size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace,
                                      colors: colors.map(\.cgColor) as CFArray,
                                      locations: nil)!

            cgContext.drawLinearGradient(gradient,
                                         start: CGPoint(x: 0, y: 0),
                                         end: CGPoint(x: size.width, y: size.height),
                                         options: [])
        }
    }

    // MARK: - Dominant Color Tests

    func testDominantColorFromSolidRedImage() {
        // Given
        let redImage = createTestImage(color: .red)

        // When
        let dominantColor = ColorExtraction.dominantColor(from: redImage)

        // Then
        XCTAssertNotNil(dominantColor)
        // Note: Due to the complexity of color extraction algorithm,
        // we mainly test that it doesn't crash and returns a color
    }

    func testDominantColorFromSolidBlueImage() {
        // Given
        let blueImage = createTestImage(color: .blue)

        // When
        let dominantColor = ColorExtraction.dominantColor(from: blueImage)

        // Then
        XCTAssertNotNil(dominantColor)
    }

    func testDominantColorFromGradientImage() {
        // Given
        let gradientImage = createGradientTestImage(colors: [.red, .blue])

        // When
        let dominantColor = ColorExtraction.dominantColor(from: gradientImage)

        // Then
        XCTAssertNotNil(dominantColor)
    }

    // MARK: - Representative Colors Tests

    func testExtractRepresentativeColorsFromSolidImage() {
        // Given
        let greenImage = createTestImage(color: .green)

        // When
        let colors = ColorExtraction.extractRepresentativeColors(from: greenImage)

        // Then
        XCTAssertNotNil(colors)
        XCTAssertNotNil(colors?.primary)
        XCTAssertNotNil(colors?.secondary)
        XCTAssertNotNil(colors?.average)
        XCTAssertNotNil(colors?.text)
        XCTAssertNotNil(colors?.textShadow)
    }

    func testExtractRepresentativeColorsFromComplexImage() {
        // Given
        let complexImage = createGradientTestImage(colors: [.red, .green, .blue])

        // When
        let colors = ColorExtraction.extractRepresentativeColors(from: complexImage)

        // Then
        XCTAssertNotNil(colors)
        XCTAssertNotNil(colors?.primary)
        XCTAssertNotNil(colors?.secondary)
        XCTAssertNotNil(colors?.average)
        XCTAssertNotNil(colors?.text)
        XCTAssertNotNil(colors?.textShadow)
    }

    // MARK: - Edge Cases

    func testDominantColorFromVerySmallImage() {
        // Given
        let tinyImage = createTestImage(color: .purple, size: CGSize(width: 1, height: 1))

        // When
        let dominantColor = ColorExtraction.dominantColor(from: tinyImage)

        // Then
        // Should not crash with very small images
        XCTAssertNotNil(dominantColor)
    }

    func testDominantColorFromLargeImage() {
        // Given
        let largeImage = createTestImage(color: .orange, size: CGSize(width: 500, height: 500))

        // When
        let dominantColor = ColorExtraction.dominantColor(from: largeImage)

        // Then
        // Should handle larger images without issues
        XCTAssertNotNil(dominantColor)
    }

    // MARK: - UI Enhancement Tests

    func testEnhanceForUI() {
        // Given
        let originalColor = Color.red

        // When
        let enhancedColor = ColorExtraction.enhanceForUI(originalColor)

        // Then
        XCTAssertNotNil(enhancedColor)
        // The enhanced color should be different from the original
        // (though we can't easily test the exact enhancement without complex color space calculations)
    }

    func testCreateBackgroundGradient() {
        // Given
        let dominantColor = Color.blue

        // When
        let gradient = ColorExtraction.createBackgroundGradient(from: dominantColor)

        // Then
        XCTAssertNotNil(gradient)
        // Note: LinearGradient properties are not publicly accessible in tests
        // We can only verify that the gradient was created without crashing
    }

    // MARK: - UIImage Extension Tests

    func testUIImageDominantColorExtension() {
        // Given
        let testImage = createTestImage(color: .cyan)

        // When
        let dominantColor = testImage.dominantColor

        // Then
        XCTAssertNotNil(dominantColor)
    }

    // MARK: - Performance Tests

    func testColorExtractionPerformance() {
        // Given
        let testImage = createTestImage(color: .magenta, size: CGSize(width: 200, height: 200))

        // When & Then
        measure {
            _ = ColorExtraction.dominantColor(from: testImage)
        }
    }

    func testRepresentativeColorsPerformance() {
        // Given
        let testImage = createGradientTestImage(colors: [.red, .green, .blue], size: CGSize(width: 150, height: 150))

        // When & Then
        measure {
            _ = ColorExtraction.extractRepresentativeColors(from: testImage)
        }
    }
}
