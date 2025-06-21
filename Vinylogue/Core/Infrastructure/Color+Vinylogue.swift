import SwiftUI

extension Color {
    // MARK: - Vinylogue Color Palette (Legacy Design - No Dark Mode Support)

    /// Primary text color - always black (legacy design doesn't support dark mode)
    static let primaryText = Color.vinylogueBlueDark

    /// Background colors - always light (legacy design doesn't support dark mode)
    static let primaryBackground = Color.vinylogueWhiteSubtle

    /// Interactive elements
    static let accent = Color.accentColor
    static let destructive = Color.red

    // MARK: - Legacy Vinylogue Colors (from TCSVinylogueDesign.h)

    /// WHITE_SUBTLE - RGB(240, 240, 240)
    static let vinylogueWhiteSubtle = Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255)

    /// BLUE_DARK - RGB(15, 24, 46)
    static let vinylogueBlueDark = Color(red: 15 / 255, green: 24 / 255, blue: 46 / 255)

    /// BLUE_PERI - RGB(220, 220, 220)
    static let vinylogueBluePeri = Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)

    /// Legacy gray for disabled states
    static let vinylogueGray = Color.vinylogueBluePeri
}

extension Font {
    // MARK: - VinylogueFont System

    static func f(_ fontVariant: VinylogueFont, _ textStyle: UIFont.TextStyle) -> Font {
        Font.custom(fontVariant.rawValue, size: UIFont.preferredFont(forTextStyle: textStyle).pointSize)
    }

    static func f(_ fontVariant: VinylogueFont, _ pointSize: CGFloat) -> Font {
        Font.custom(fontVariant.rawValue, size: pointSize)
    }
}

enum VinylogueFont: String {
    case ultralight = "AvenirNext-Ultralight"
    case regular = "AvenirNext-Regular"
    case medium = "AvenirNext-Medium"
    case demiBold = "AvenirNext-Demibold"
    case bold = "AvenirNext-Bold"
    case heavy = "AvenirNext-Heavy"
}
