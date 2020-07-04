import SwiftUI
import Foundation

extension Image {
    init(uiImage: UIImage?, placeholder: String) {
        if let uiImage = uiImage {
            self = .init(uiImage: uiImage)
        } else {
            self = .init(placeholder)
        }
    }
}

struct RecordLoadingView: View {
    private struct Represented: UIViewRepresentable {
        func makeUIView(context: Self.Context) -> UIImageView {
            let view = UIImageView()
            let images = (1...12).map { String(format: "loading%02d", $0) }.map { UIImage(named: $0)! }
            view.animationImages = images
            view.animationDuration = 0.5
            view.animationRepeatCount = 0
            view.startAnimating()
            return view
        }

        func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<Represented>) {
        }
    }

    var body: some View {
        Represented()
            .frame(width: 40, height: 40)
    }
}
