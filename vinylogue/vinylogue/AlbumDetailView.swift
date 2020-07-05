import SwiftUI

struct AlbumDetailView: View {
    var body: some View {
        EmptyView()
    }
}

struct AlbumDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumDetailView()
            .previewLayout(.sizeThatFits)
    }
}

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

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
            if model.isLoading {
                OffsetRecordLoadingView()
            }
            VStack(spacing: 0) {
                Image(uiImage: model.image, placeholder: "recordPlaceholder")
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
            .overlay(
                VStack {
                    Rectangle()
                        .foregroundColor(.blacka(0.5))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .foregroundColor(.blacka(0.5))
                        .frame(height: 1)
                }
            )
            .background(BackgroundImageView(uiImage: model.image))
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

private struct BackgroundImageView: View {
    let uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 14)
                    .opacity(0.3)
            } else {
                EmptyView()
            }
        }
    }
}

struct AlbumDetailPlayCountsView: View {
    struct Model {
        let weekPlayCount: String
        let allTimePlayCount: String
        let weekLabel: String
        let textColor: Color
        let shadowColor: Color

        var weekModel: AlbumDetailPlayCountView.Model {
            .init(playCount: weekPlayCount, timeLabel: weekLabel, textColor: textColor, shadowColor: shadowColor)
        }

        var allTimeModel: AlbumDetailPlayCountView.Model {
            .init(playCount: allTimePlayCount, timeLabel: "all-time", textColor: textColor, shadowColor: shadowColor)
        }
    }

    let model: Model

    var body: some View {
        HStack(spacing: 0) {
            AlbumDetailPlayCountView(model: model.weekModel)
                .padding(.horizontal, 6.0)
                .padding(.vertical, 10.0)
                .overlay(
                    HStack {
                        Spacer()
                        Rectangle()
                            .foregroundColor(.whitea(0.35))
                            .frame(width: 1)
                    }
                )
            AlbumDetailPlayCountView(model: model.allTimeModel)
                .padding(.horizontal, 6.0)
                .padding(.vertical, 10.0)
                .overlay(
                    HStack {
                        Rectangle()
                            .foregroundColor(.blacka(0.25))
                            .frame(width: 1)
                        Spacer()
                    }
                )
        }
        .overlay(
            VStack {
                Rectangle()
                    .foregroundColor(.whitea(0.35))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .foregroundColor(.blacka(0.25))
                    .frame(height: 1)
            }
        )
    }
}

struct AlbumDetailPlayCountsView_Previews: PreviewProvider {
    static let mock = AlbumDetailPlayCountsView.Model(weekPlayCount: "13", allTimePlayCount: "39", weekLabel: "week 27 2019", textColor: .black, shadowColor: .white)
    static var previews: some View {
        AlbumDetailPlayCountsView(model: mock)
            .previewLayout(.sizeThatFits)
    }
}

struct AlbumDetailPlayCountView: View {
    struct Model {
        let playCount: String
        let timeLabel: String
        let textColor: Color
        let shadowColor: Color
    }

    let model: Model

    var body: some View {
        VStack {
            Text(model.playCount)
                .font(.avnDemiBold(30))
                .foregroundColor(model.textColor.opacity(0.85))
                .shadow(color: model.shadowColor.opacity(0.6), radius: 1, x: 0, y: 0.5)
                .multilineTextAlignment(.center)
                .padding(.bottom, -3.0)
            Text("plays")
                .font(.avnUltraLight(14))
                .foregroundColor(model.textColor.opacity(0.7))
                .shadow(color: model.shadowColor.opacity(0.5), radius: 1, x: 0, y: 0.5)
                .multilineTextAlignment(.center)
                .padding(.bottom, -3.0)
            Text("week 27 2019")
                .font(.avnRegular(18))
                .foregroundColor(model.textColor.opacity(0.7))
                .shadow(color: model.shadowColor.opacity(0.5), radius: 1, x: 0, y: 0.5)
                .multilineTextAlignment(.center)
        }
    }
}
