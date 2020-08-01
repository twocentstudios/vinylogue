import ComposableArchitecture
import Foundation
import UIKit

struct AppClient {
    var applicationDidEnterBackground: () -> Effect<Void, Never>
}

extension AppClient {
    static let live = Self(
        applicationDidEnterBackground: {
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                .map { _ in () }
                .eraseToEffect()
        }
    )
}
