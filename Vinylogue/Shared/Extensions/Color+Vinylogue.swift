import SwiftUI

extension Color {
    // MARK: - Vinylogue Color Palette
    
    /// Primary text color - dark for light mode, light for dark mode
    static let primaryText = Color.primary
    
    /// Secondary text color for less important information
    static let secondaryText = Color.secondary
    
    /// Tertiary text color for very subtle information
    static let tertiaryText = Color.gray
    
    /// Background colors
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    /// Interactive elements
    static let accent = Color.accentColor
    static let destructive = Color.red
    
    /// Custom Vinylogue colors matching legacy design
    static let vinylogueBlue = Color(red: 0.0, green: 0.478, blue: 1.0) // iOS blue
    static let vinylrogueGray = Color(.systemGray4)
}

extension Font {
    // MARK: - Vinylogue Typography with Dynamic Type Support
    
    /// Large username text in users list - scales with Dynamic Type
    static let usernameLarge = Font.title2.weight(.medium)
    
    /// Regular username text - scales with Dynamic Type  
    static let usernameRegular = Font.headline.weight(.medium)
    
    /// Section headers like "me" and "friends" - scales with Dynamic Type
    static let sectionHeader = Font.subheadline.weight(.medium)
    
    /// Secondary information like play counts - scales with Dynamic Type
    static let secondaryInfo = Font.caption.weight(.regular)
    
    /// Album/artist names in charts - scales with Dynamic Type
    static let albumTitle = Font.body.weight(.medium)
    static let artistName = Font.caption.weight(.regular)
    
    /// Navigation titles - scales with Dynamic Type
    static let navigationTitle = Font.headline.weight(.semibold)
    
    // MARK: - Dynamic Type Scaling Methods
    
    /// Creates a font that scales with Dynamic Type, using title3 as the base
    static func scaledTitle3() -> Font {
        return Font.title3
    }
    
    /// Creates a font that scales with Dynamic Type for body text
    static func scaledBody() -> Font {
        return Font.body
    }
    
    /// Creates a font that scales with Dynamic Type for captions
    static func scaledCaption() -> Font {
        return Font.caption
    }
}