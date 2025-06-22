import SwiftUI

/// PreferenceKey for controlling NavigationStack tint color from child views
struct NavigationTintPreferenceKey: PreferenceKey {
    static let defaultValue: Color? = nil

    static func reduce(value: inout Color?, nextValue: () -> Color?) {
        value = nextValue()
    }
}

extension View {
    /// Sets the navigation tint color preference for the NavigationStack
    func navigationTint(_ color: Color?) -> some View {
        preference(key: NavigationTintPreferenceKey.self, value: color)
    }
}
