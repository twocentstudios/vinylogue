import SwiftUI

struct AlbumDetailHeaderView: View {
    struct Model {
        let artist: String
        let album: String
        let textColor: Color
        let shadowColor: Color
        let isLoading: Bool
    }

    let model: Model

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            if model.isLoading {
                Circle()
                    .frame(width: 40, height: 40, alignment: .center)
                    .offset(CGSize(width: 0, height: -20.0))
            }
            VStack(spacing: 0) {
                Image("recordPlaceholder")
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
        }
        .background(Color.blacka(0.05))
        .clipped()
    }
}

struct AlbumDetailHeaderView_Previews: PreviewProvider {
    static let mock = AlbumDetailHeaderView.Model(artist: "Banner Pilot", album: "Collapser", textColor: .black, shadowColor: .white, isLoading: true)
    static var previews: some View {
        AlbumDetailHeaderView(model: mock)
    }
}
