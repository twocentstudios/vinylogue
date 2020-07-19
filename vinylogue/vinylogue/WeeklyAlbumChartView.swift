import ComposableArchitecture
import SwiftUI

struct WeeklyAlbumChartView: View {
    struct Model: Equatable {
        struct Section: Equatable {
            let label: String
            let albums: [WeeklyAlbumChartCell.Model]
        }

        let sections: [Section]
        let error: ErrorRetryView.Model?
        let isLoading: Bool
    }

    let store: Store<WeeklyAlbumChartState, WeeklyAlbumChartAction>

    var body: some View {
        WithViewStore(self.store.scope(state: \.view)) { viewStore in
            ZStack {
                if viewStore.isLoading {
                    OffsetRecordLoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if let error = viewStore.error {
                    ErrorRetryView(model: error)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        // TODO: real ids are required
                        ForEach(viewStore.sections, id: \.label) { section in
                            Section(
                                header: WeeklyAlbumChartHeaderView(label: section.label)
                            ) {
                                if !section.albums.isEmpty {
                                    ForEach(section.albums, id: \.album) { album in
                                        NavigationLink(
                                            destination: Text("Destination")
                                        )
                                        {
                                            WeeklyAlbumChartCell(album)
                                        }
                                    }

                                } else {
                                    WeeklyAlbumChartEmptyCell()
                                }
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .navigationTitle("ybsc's week 27 charts") // TODO:
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// struct WeeklyAlbumChartView_Previews: PreviewProvider {
//    static let mock = WeeklyAlbumChartView.Model(sections: mockSections, error: nil, isLoading: false)
//    static let mockLoading = WeeklyAlbumChartView.Model(sections: [], error: nil, isLoading: true)
//    static let mockError = WeeklyAlbumChartView.Model(sections: mockSections, error: ErrorRetryView_Previews.mock, isLoading: false)
//    static var previews: some View {
//        Group {
//            NavigationView {
//                WeeklyAlbumChartView(model: mock)
//            }
//            NavigationView {
//                WeeklyAlbumChartView(model: mock)
//            }
//            .preferredColorScheme(.dark)
//        }
//    }
// }

extension WeeklyAlbumChartState {
    var view: WeeklyAlbumChartView.Model {
        // TODO:
        WeeklyAlbumChartView.Model(sections: mockSections, error: nil, isLoading: false)
    }
}

struct WeeklyAlbumChartHeaderView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.avnMedium(19))
            .foregroundColor(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
    }
}

struct WeeklyAlbumChartHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartHeaderView(label: "2019")
            .previewLayout(.sizeThatFits)
    }
}

struct WeeklyAlbumChartCell: View {
    struct Model: Equatable {
        let image: UIImage?
        let artist: String
        let album: String
        let plays: String
    }

    let model: Model

    init(_ model: Model) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                // TODO: light/dark placeholder
                Image(uiImage: model.image, placeholder: "recordPlaceholderThumb")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 80, height: 80, alignment: .center)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2.0, style: .circular)
                            .strokeBorder(Color.blacka(0.2), lineWidth: 1.0, antialiased: true)
                    )
                    .cornerRadius(2.0)
                VStack {
                    Text(model.artist.uppercased())
                        .font(.avnUltraLight(12))
                        .foregroundColor(Color(.label))
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, -1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(model.album)
                        .font(.avnRegular(16))
                        .foregroundColor(Color(.label))
                        .multilineTextAlignment(.leading)
                        .padding(.top, -1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack {
                    Text(model.plays)
                        .font(.avnRegular(28))
                        .foregroundColor(Color(.label).opacity(0.8))
                        .lineLimit(1)
                        .padding(.bottom, -5)
                    Text("plays")
                        .font(.avnUltraLight(15))
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                        .padding(.top, -5)
                }
                .padding(.trailing, 2)
            }
            .padding(.vertical, 6)
        }
    }
}

struct WeeklyAlbumChartCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeeklyAlbumChartCell(.init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
                .previewLayout(.sizeThatFits)
            WeeklyAlbumChartCell(.init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}

struct WeeklyAlbumChartEmptyCell: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("no charts this week")
                .font(.avnUltraLight(18))
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
                .frame(minHeight: 100)
        }
    }
}

struct WeeklyAlbumChartEmptyCell_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartEmptyCell()
            .previewLayout(.sizeThatFits)
    }
}

struct WeeklyAlbumChartLoadingCell: View {
    var body: some View {
        VStack(spacing: 0) {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
                .frame(minHeight: 100)
        }
    }
}

struct WeeklyAlbumChartLoadingCell_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartLoadingCell()
            .previewLayout(.sizeThatFits)
    }
}

struct WeeklyAlbumChartErrorCell: View {
    let action: (() -> ())?

    init(action: (() -> ())? = nil) {
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("\(Image(systemName: "xmark.circle")) failed to fetch charts")
                    .font(.avnRegular(18))
                    .frame(maxWidth: .infinity, alignment: .center)
                if let action = action {
                    Button(action: action) {
                        Text("try again")
                            .font(.avnDemiBold(20))
                            .foregroundColor(.accentColor)
                            .padding(.all, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 20)
            .frame(minHeight: 100)
        }
    }
}

struct WeeklyAlbumChartErrorCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeeklyAlbumChartErrorCell {}
                .previewLayout(.sizeThatFits)
            WeeklyAlbumChartErrorCell {}
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}

struct ErrorRetryView: View {
    struct Model: Equatable {
        let title: String
        let subtitle: String

        init(title: String, subtitle: String) {
            self.title = title
            self.subtitle = subtitle
        }
    }

    let model: Model
    let action: (() -> ())? = nil

    var body: some View {
        HStack {
            VStack {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                Text(model.title)
                    .font(.avnMedium(27))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                Text(model.subtitle)
                    .font(.avnRegular(13))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                if let action = action {
                    Button(action: action) {
                        Text("try again")
                            .font(.avnDemiBold(20))
                            .foregroundColor(.accentColor)
                            .padding(.all, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.all, 16)
        }
    }
}

struct ErrorRetryView_Previews: PreviewProvider {
    static let mock = ErrorRetryView.Model(title: "The internet connection appears to be offline.", subtitle: "Connect to the internet and try again.")
    static var previews: some View {
        Group {
            ErrorRetryView(model: mock)
                .previewLayout(.sizeThatFits)
            ErrorRetryView(model: mock)
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}

let mockAlbums: [WeeklyAlbumChartCell.Model] =
    [
        .init(image: nil, artist: "Weezer", album: "Maladroit", plays: "20"),
        .init(image: nil, artist: "Rufio", album: "The Comfort of Home", plays: "17"),
        .init(image: nil, artist: "Saves The Day", album: "Sound The Alarm", plays: "2"),
    ]

let mockSections: [WeeklyAlbumChartView.Model.Section] =
    [
        .init(label: "2019", albums: mockAlbums),
        .init(label: "2018", albums: []),
    ]

private struct TopBorderView: View {
    var body: some View {
        EmptyView()
        Rectangle()
            .foregroundColor(.highlighta(0.2))
            .frame(height: 1)
    }
}

private struct BottomBorderView: View {
    var body: some View {
        EmptyView()
        Rectangle()
            .foregroundColor(.shadowa(0.1))
            .frame(height: 1)
    }
}
