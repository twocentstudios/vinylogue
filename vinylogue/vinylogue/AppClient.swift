import ComposableArchitecture
import Foundation
import UIKit

struct AppClient {
    var applicationDidEnterBackground: () -> Effect<Void, Never>
    var systemInformation: () -> SystemInformation
    var openExternalURL: (URL) -> Void
}

struct SystemInformation: Equatable {
    let appVersion: String
    let appBuild: String
    let device: String
    let systemVersion: String
}

extension AppClient {
    static let live = Self(
        applicationDidEnterBackground: {
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                .map { _ in () }
                .eraseToEffect()
        },
        systemInformation: {
            SystemInformation(
                appVersion: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String,
                appBuild: Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String,
                device: UIDevice.current.model,
                systemVersion: UIDevice.current.systemVersion
            )
        },
        openExternalURL: { url in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { _ in }
            }
        }
    )
}
