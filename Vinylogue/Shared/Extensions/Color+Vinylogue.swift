import SwiftUI

extension Color {
    // MARK: - Vinylogue Color Palette (Legacy Design - No Dark Mode Support)

    /// Primary text color - always black (legacy design doesn't support dark mode)
    static let primaryText = Color.vinylogueBlueDark

    /// Secondary text color for less important information
    static let secondaryText = Color.vinylogueBlueDark

    /// Tertiary text color for very subtle information
    static let tertiaryText = Color.vinylogueBlueDark

    /// Background colors - always light (legacy design doesn't support dark mode)
    static let primaryBackground = Color.vinylogueWhiteSubtle
    static let secondaryBackground = Color.vinylogueWhiteSubtle
    static let tertiaryBackground = Color.vinylogueWhiteSubtle

    /// Interactive elements
    static let accent = Color.vinylogueBlueBold
    static let destructive = Color.red

    // MARK: - Legacy Vinylogue Colors (from TCSVinylogueDesign.h)

    /// WHITE_SUBTLE - RGB(240, 240, 240)
    static let vinylogueWhiteSubtle = Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255)

    /// BLUE_DARK - RGB(15, 24, 46)
    static let vinylogueBlueDark = Color(red: 15 / 255, green: 24 / 255, blue: 46 / 255)

    /// BLUE_BOLD - RGB(67, 85, 129)
    static let vinylogueBlueBold = Color(red: 67 / 255, green: 85 / 255, blue: 129 / 255)

    /// BLUE_PERI - RGB(220, 220, 220)
    static let vinylogueBluePeri = Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)

    /// BLUE_PERI_SHADOW - RGB(195, 195, 195)
    static let vinylogueBluePeriShadow = Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255)

    /// BAR_BUTTON_TINT - RGB(220, 220, 220)
    static let vinylogueButtonTint = Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)

    /// Legacy gray for disabled states
    static let vinylogueGray = Color.vinylogueBluePeri
}

extension Font {
    // MARK: - Vinylogue Typography (Legacy AvenirNext with Dynamic Type Support)

    /// Legacy AvenirNext fonts with Dynamic Type scaling
    static func vinylogueUltraLight(_ size: CGFloat) -> Font {
        .custom("AvenirNext-UltraLight", size: size)
    }

    static func vinylrogeDemiBold(_ size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size)
    }

    static func vinylrogueMedium(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Medium", size: size)
    }

    static func vinylogueRegular(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size)
    }

    // MARK: - Semantic Font Roles with Dynamic Type Support

    /// Large username text in users list - AvenirNext-DemiBold scaled
    static let usernameLarge = Font.custom("AvenirNext-DemiBold",
                                           size: UIFont.preferredFont(forTextStyle: .title2).pointSize)

    /// Regular username text - AvenirNext-Medium scaled
    static let usernameRegular = Font.custom("AvenirNext-Medium",
                                             size: UIFont.preferredFont(forTextStyle: .headline).pointSize)

    /// Section headers like "me" and "friends" - AvenirNext-Medium scaled
    static let sectionHeader = Font.custom("AvenirNext-Ultralight",
                                           size: UIFont.preferredFont(forTextStyle: .headline).pointSize)

    /// Secondary information like play counts - AvenirNext-Regular scaled
    static let secondaryInfo = Font.custom("AvenirNext-Regular",
                                           size: UIFont.preferredFont(forTextStyle: .caption1).pointSize)

    /// Album/artist names in charts - AvenirNext-Medium scaled
    static let albumTitle = Font.custom("AvenirNext-Medium",
                                        size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    static let artistName = Font.custom("AvenirNext-Regular",
                                        size: UIFont.preferredFont(forTextStyle: .caption1).pointSize)

    /// Navigation titles - AvenirNext-DemiBold scaled
    static let navigationTitle = Font.custom("AvenirNext-DemiBold",
                                             size: UIFont.preferredFont(forTextStyle: .headline).pointSize)

    // MARK: - Dynamic Type Scaling Methods

    /// Creates a font that scales with Dynamic Type, using title3 as the base
    static func scaledLargeTitle() -> Font {
        Font.custom("AvenirNext-Regular", size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize)
    }

    static func scaledTitle2() -> Font {
        Font.custom("AvenirNext-Regular", size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    /// Creates a font that scales with Dynamic Type for body text
    static func scaledBody() -> Font {
        Font.custom("AvenirNext-Medium", size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    }

    /// Creates a font that scales with Dynamic Type for captions
    static func scaledCaption() -> Font {
        Font.custom("AvenirNext-Regular", size: UIFont.preferredFont(forTextStyle: .caption1).pointSize)
    }
}
