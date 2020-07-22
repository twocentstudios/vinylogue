import Combine
import ComposableArchitecture
import Foundation
import Nuke
import ImagePublisher
import UIKit.UIImage

struct ImageClient {
    let fetchImage: (URL) -> Effect<UIImage, Error>
}

extension ImageClient {
    struct Error: Swift.Error {}
}

extension ImageClient {
    static let live = Self(
        fetchImage: { url -> Effect<UIImage, Error> in
            ImagePipeline.shared.imagePublisher(with: url)
                .mapError { _ in Self.Error() }
                .map { $0.image }
                .eraseToEffect()
        }
    )

    static let mock = Self(
        fetchImage: { url -> Effect<UIImage, Error> in
            Just(UIImage(named: "recordPlaceholderThumb")!)
                .mapError { _ in Self.Error() }
                .eraseToEffect()
        }
    )
}
