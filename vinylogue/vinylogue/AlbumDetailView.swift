import ComposableArchitecture
import SwiftUI

struct AlbumDetailView: View {
    struct Model: Equatable {
        let image: UIImage?
        let artist: String
        let album: String

        let weekPlayCount: String
        let allTimePlayCount: String
        let weekLabel: String

        let albumAboutText: String?

        let backgroundColor: UIColor?
        let textColor: UIColor?
        let shadowColor: UIColor?

        let isLoading: Bool

        var derivedBackgroundColor: Color { backgroundColor.flatMap(Color.init) ?? Color(.tertiarySystemBackground) }
        var derivedTextColor: Color { textColor.flatMap(Color.init) ?? Color(.label) }
        var derivedShadowColor: Color { shadowColor.flatMap(Color.init) ?? Color.highlighta(1.0) }

        var headerModel: AlbumDetailHeaderView.Model {
            .init(image: image, artist: artist, album: album, textColor: derivedTextColor, shadowColor: derivedShadowColor, isLoading: isLoading)
        }

        var playCountsModel: AlbumDetailPlayCountsView.Model {
            .init(weekPlayCount: weekPlayCount, allTimePlayCount: allTimePlayCount, weekLabel: weekLabel, textColor: derivedTextColor, shadowColor: derivedShadowColor)
        }

        var aboutModel: AlbumDetailAboutView.Model {
            .init(text: albumAboutText, textColor: derivedTextColor, shadowColor: derivedShadowColor)
        }
    }

    let store: Store<AlbumDetailState, AlbumDetailAction>

    var body: some View {
        WithViewStore(store.scope(state: \.view)) { viewStore in
            ScrollView {
                VStack(spacing: 0) {
                    AlbumDetailHeaderView(model: viewStore.headerModel)
                    AlbumDetailPlayCountsView(model: viewStore.playCountsModel)
                    AlbumDetailAboutView(model: viewStore.aboutModel)
                }
            }
            .navigationBarHidden(true)
            .background(viewStore.derivedBackgroundColor.edgesIgnoringSafeArea(.all))
        }
    }
}

extension AlbumDetailState {
    var view: AlbumDetailView.Model {
        let image = (/ImageState.loaded).extract(from: imageState)
        let artistName = albumChartStub.artist.name
        let albumName = albumChartStub.album.name
        let album = (/AlbumState.loaded).extract(from: albumState)
        let weekPlayCount = String(albumChartStub.playCount)
        let allTimePlayCount = album?.totalPlayCount.flatMap(String.init) ?? "-"
        let weekLabel = "week 30 2019" // TODO: use SwiftUI date formatting or do it in State?
        let albumAboutText = album?.about
        let imageColors = (/ImageColorsState.loaded).extract(from: imageColorsState)
        let backgroundColor = imageColors?.primaryColor
        let textColor = imageColors?.textColor
        let shadowColor = imageColors?.textShadowColor
        let isLoading = albumState == .loading || imageState == .loading

        return .init(
            image: image,
            artist: artistName,
            album: albumName,
            weekPlayCount: weekPlayCount,
            allTimePlayCount: allTimePlayCount,
            weekLabel: weekLabel,
            albumAboutText: albumAboutText,
            backgroundColor: backgroundColor,
            textColor: textColor,
            shadowColor: shadowColor,
            isLoading: isLoading
        )
    }
}

//struct AlbumDetailView_Previews: PreviewProvider {
//    static let mock: AlbumDetailView.Model = .init(
//        image: AlbumDetailHeaderView_Previews.mock.image,
//        artist: AlbumDetailHeaderView_Previews.mock.artist,
//        album: AlbumDetailHeaderView_Previews.mock.album,
//        weekPlayCount: AlbumDetailPlayCountsView_Previews.mock.weekPlayCount,
//        allTimePlayCount: AlbumDetailPlayCountsView_Previews.mock.allTimePlayCount,
//        weekLabel: AlbumDetailPlayCountsView_Previews.mock.weekLabel,
//        albumAboutText: AlbumDetailAboutView_Previews.mock.text,
//        backgroundColor: .init(red: 218.0 / 255.0, green: 38.0 / 255.0, blue: 15.0 / 255.0, alpha: 1.0),
//        textColor: .white,
//        shadowColor: .black,
//        isLoading: false
//    )
//
//    static let mockLoading: AlbumDetailView.Model = .init(
//        image: nil,
//        artist: AlbumDetailHeaderView_Previews.mock.artist,
//        album: AlbumDetailHeaderView_Previews.mock.album,
//        weekPlayCount: AlbumDetailPlayCountsView_Previews.mock.weekPlayCount,
//        allTimePlayCount: AlbumDetailPlayCountsView_Previews.mock.allTimePlayCount,
//        weekLabel: AlbumDetailPlayCountsView_Previews.mock.weekLabel,
//        albumAboutText: AlbumDetailAboutView_Previews.mock.text,
//        backgroundColor: nil,
//        textColor: nil,
//        shadowColor: nil,
//        isLoading: true
//    )
//
//    static var previews: some View {
//        Group {
//            NavigationView {
//                AlbumDetailView(model: mock)
//            }
//            NavigationView {
//                AlbumDetailView(model: mockLoading)
//            }
//            NavigationView {
//                AlbumDetailView(model: mockLoading)
//            }
//            .preferredColorScheme(.dark)
//        }
//    }
//}

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
                    .border(Color.blacka(0.2), width: 1)
                    .shadow(color: .blacka(0.2), radius: 3, x: 0, y: 1)
                    .padding(.bottom, 14)
                Text(model.artist.uppercased())
                    .font(.avnRegular(15))
                    .foregroundColor(model.textColor)
                    .shadow(color: model.shadowColor, radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, -1)
                Text(model.album)
                    .font(.avnDemiBold(30))
                    .foregroundColor(model.textColor)
                    .shadow(color: model.shadowColor, radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 26)
            .overlay(
                VStack {
                    Rectangle()
                        .foregroundColor(.blacka(0.1))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .foregroundColor(.blacka(0.1))
                        .frame(height: 1)
                }
            )
            .background(BackgroundImageView(uiImage: model.image))
        }
        .background(Color.black.opacity(0.15))
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
                    .blur(radius: 10)
                    .opacity(0.45)
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
            .init(playCount: weekPlayCount, timePeriodLabel: weekLabel, textColor: textColor, shadowColor: shadowColor)
        }

        var allTimeModel: AlbumDetailPlayCountView.Model {
            .init(playCount: allTimePlayCount, timePeriodLabel: "all-time", textColor: textColor, shadowColor: shadowColor)
        }
    }

    let model: Model

    var body: some View {
        HStack(spacing: 0) {
            AlbumDetailPlayCountView(model: model.weekModel)
                .overlay(
                    HStack {
                        Spacer()
                        Rectangle()
                            .foregroundColor(.whitea(0.35))
                            .frame(width: 1)
                    }
                )
            AlbumDetailPlayCountView(model: model.allTimeModel)
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
        let timePeriodLabel: String
        let textColor: Color
        let shadowColor: Color
    }

    let model: Model

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text(model.playCount)
                    .font(.avnDemiBold(30))
                    .foregroundColor(model.textColor.opacity(0.85))
                    .shadow(color: model.shadowColor.opacity(0.6), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, -3.0)
                Text("plays")
                    .font(.avnUltraLight(14))
                    .foregroundColor(model.textColor.opacity(1.0))
                    .shadow(color: model.shadowColor.opacity(0.5), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, -3.0)
                Text(model.timePeriodLabel)
                    .font(.avnRegular(18))
                    .foregroundColor(model.textColor.opacity(0.7))
                    .shadow(color: model.shadowColor.opacity(0.5), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6.0)
            .padding(.vertical, 10.0)
            Spacer()
        }
    }
}

struct AlbumDetailAboutView: View {
    struct Model {
        let text: String?
        let textColor: Color
        let shadowColor: Color
    }

    let model: Model

    var body: some View {
        VStack(alignment: .leading) {
            if let text = model.text {
                Text("about this album")
                    .font(.avnDemiBold(24))
                    .foregroundColor(model.textColor.opacity(0.7))
                    .shadow(color: model.shadowColor.opacity(0.3), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                Text(text)
                    .font(.avnRegular(16))
                    .foregroundColor(model.textColor.opacity(0.95))
                    .shadow(color: model.shadowColor.opacity(0.2), radius: 1, x: 0, y: 0.5)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            } else {
                HStack {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 26.0)
        .padding(.vertical, 48.0)
        .overlay(
            VStack {
                Rectangle()
                    .foregroundColor(.blacka(0.1))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .foregroundColor(.blacka(0.1))
                    .frame(height: 1)
            }
        )
        .background(Color.black.opacity(0.15))
    }
}

struct AlbumDetailAboutView_Previews: PreviewProvider {
    static let mock = AlbumDetailAboutView.Model(text: "Maladroit is the fourth studio album by the American alternative rock band Weezer, released on May 14, 2002 on Geffen Records. This is the first Weezer album to feature bassist Scott Shriner, who joined the band in 2001 after the breakdown and departure of Mikey Welsh.", textColor: .black, shadowColor: .white)
    static let mockEmpty = AlbumDetailAboutView.Model(text: nil, textColor: .black, shadowColor: .white)
    static var previews: some View {
        AlbumDetailAboutView(model: mockEmpty)
            .previewLayout(.sizeThatFits)
    }
}
