import SwiftUI

struct AlbumDetailHeaderView: View {
    struct Model {
        let image: UIImage?
        let artist: String
        let album: String
        let textColor: Color
        let shadowColor: Color
        let isLoading: Bool
    }

    let model: Model

    private var imageView: Image {
        if let image = model.image {
            return Image(uiImage: image)
        } else {
            return Image("recordPlaceholder")
        }
    }

    private var backgroundImageView: some View {
        Group {
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 14)
                    .opacity(0.3)
            } else {
                EmptyView()
            }
        }
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            if model.isLoading {
                Circle()
                    .frame(width: 40, height: 40, alignment: .center)
                    .offset(CGSize(width: 0, height: -20.0))
            }
            VStack(spacing: 0) {
                imageView
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.bottom, 14)
                Text(model.artist.uppercased())
                    .font(.avnRegular(15))
                    .foregroundColor(model.textColor)
                    .shadow(color: model.shadowColor.opacity(0.85), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, -1)
                Text(model.album)
                    .font(.avnDemiBold(30))
                    .foregroundColor(model.textColor.opacity(0.85))
                    .shadow(color: model.shadowColor, radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 26)
            .background(backgroundImageView)
        }
        .background(Color.blacka(0.05))
        .clipped()
    }
}

struct AlbumDetailHeaderView_Previews: PreviewProvider {
    static let mock = AlbumDetailHeaderView.Model(image: UIImage(named: "album"), artist: "Saves The Day", album: "Sound The Alarm", textColor: .black, shadowColor: .white, isLoading: false)
    static let mockLoading = AlbumDetailHeaderView.Model(image: nil, artist: "Saves The Day", album: "Sound The Alarm", textColor: .black, shadowColor: .white, isLoading: true)
    static var previews: some View {
        Group {
            AlbumDetailHeaderView(model: mock)
            AlbumDetailHeaderView(model: mockLoading)
        }
        .previewLayout(.sizeThatFits)
    }
}
