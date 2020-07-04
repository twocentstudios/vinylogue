import SwiftUI

extension Image {
    init(uiImage: UIImage?, placeholder: String) {
        if let uiImage = uiImage {
            self = .init(uiImage: uiImage)
        } else {
            self = .init(placeholder)
        }
    }
}
