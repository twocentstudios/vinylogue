import SwiftUI

extension Font {
    static func avnUltraLight(_ size: CGFloat) -> Font { .custom("AvenirNext-UltraLight", size: size) }
    static func avnDemiBold(_ size: CGFloat) -> Font { .custom("AvenirNext-DemiBold", size: size) }
    static func avnMedium(_ size: CGFloat) -> Font { .custom("AvenirNext-Medium", size: size) }
    static func avnRegular(_ size: CGFloat) -> Font { .custom("AvenirNext-Regular", size: size) }
}

extension Color {
    static func rgb(_ redWebValue: Double, _ greenWebValue: Double, _ blueWebValue: Double) -> Color { rgba(redWebValue, greenWebValue, blueWebValue, alpha: 1) }
    static func rgba(_ redWebValue: Double, _ greenWebValue: Double, _ blueWebValue: Double, alpha: Double) -> Color { Color(red: redWebValue / 255.0, green: greenWebValue / 255.0, blue: blueWebValue / 255.0).opacity(alpha) }

    static func gray(_ webValue: Double) -> Color { .init(white: Double(webValue) / 255.0) }
    static func graya(_ webValue: Double, _ opacity: Double) -> Color { Color(white: Double(webValue) / 255.0).opacity(opacity) }

    static func whitea(_ opacity: Double) -> Color { graya(255, opacity) }
    static func blacka(_ opacity: Double) -> Color { graya(0, opacity) }

    static let whiteSubtle = gray(240)
    static let blueDark = rgb(15, 24, 46)
    static let blueBold = rgb(67, 85, 129)
    static let bluePeri = gray(220)
    static let bluePeriShadow = gray(195)
    static let barButtonTint = gray(220)
}
