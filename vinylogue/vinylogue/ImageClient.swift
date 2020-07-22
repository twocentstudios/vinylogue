import Combine
import ComposableArchitecture
import Foundation
import Nuke
import UIKit.UIImage

struct ImageClient {
    let fetchImage: (URL) -> Effect<UIImage, Error>
}

extension ImageClient {
    struct Error: Swift.Error {}
}

