import SwiftUI

struct WeeklyAlbumChartView: View {
    struct Model {
        struct Section {
            let label: String
            let albums: [WeeklyAlbumChartCell.Model]
        }

        let sections: [Section]
        let error: ErrorRetryView.Model?
        let isLoading: Bool
    }

    let model: Model

    @State var selectedItem: String?

    var body: some View {
        ZStack {
            if let error = model.error {
                Rectangle()
                    .foregroundColor(.clear)
                    .overlay(
                        ErrorRetryView(model: error)
                    )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // TODO: real ids are required
                        ForEach(model.sections, id: \.label) { section in
                            Section(header: WeeklyAlbumChartHeaderView(label: section.label)) {
                                ForEach(section.albums, id: \.album) { album in
                                    VStack {
                                        NavigationLink(
                                            destination: Text("Destination"),
                                            isActive: Binding(get: {
                                                self.selectedItem == album.album
                                            }, set: { value in
                                                self.selectedItem = value ? album.album : nil
                                        })
                                        ) {
                                            EmptyView()
                                        }
                                        WeeklyAlbumChartCell(album) {
                                            self.selectedItem = album.album
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("ybsc's week 27 charts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            ZStack {
                if model.isLoading {
                    ProgressView()
                } else {
                    EmptyView()
                }
            }
        )
        .background(Color.whiteSubtle.edgesIgnoringSafeArea(.all))
    }
}

struct WeeklyAlbumChartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WeeklyAlbumChartView(model: .init(sections: mockSections, error: ErrorRetryView_Previews.mock, isLoading: false))
        }
    }
}

struct WeeklyAlbumChartHeaderView: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.avnMedium(19))
                .foregroundColor(.gray(120))
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .padding(.horizontal, 12)
        .background(Color.bluePeri)
    }
}

struct WeeklyAlbumChartHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartHeaderView(label: "2019")
            .previewLayout(.sizeThatFits)
    }
}

struct WeeklyAlbumChartCell: View {
    struct Model {
        let image: UIImage?
        let artist: String
        let album: String
        let plays: String
    }

    let model: Model
    let action: () -> ()

    init(_ model: Model, action: @escaping () -> () = {}) {
        self.model = model
        self.action = action
    }

    private var imageView: Image {
        if let image = model.image {
            return Image(uiImage: image)
        } else {
            return Image("recordPlaceholderThumb")
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundColor(.whitea(0.8))
                    .frame(height: 1)
                HStack(spacing: 9) {
                    imageView
                        .resizable()
                        .frame(width: 80, height: 80, alignment: .center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2.0, style: .circular)
                                .strokeBorder(Color.blacka(0.2), lineWidth: 1.0, antialiased: true)
                        )
                        .cornerRadius(2.0)
                    VStack {
                        HStack {
                            Text(model.artist.uppercased())
                                .font(.avnUltraLight(12))
                                .foregroundColor(.blueDark)
                                .multilineTextAlignment(.leading)
                                .shadow(
                                    color: .whitea(0.8),
                                    radius: 1,
                                    x: 0,
                                    y: -0.5
                                )
                                .padding(.bottom, -1)
                            Spacer()
                        }
                        HStack {
                            Text(model.album)
                                .font(.avnRegular(16))
                                .foregroundColor(.blueDark)
                                .multilineTextAlignment(.leading)
                                .shadow(
                                    color: .blacka(0.25),
                                    radius: 1,
                                    x: 0,
                                    y: 0.5
                                )
                                .padding(.top, -1)
                            Spacer()
                        }
                    }
                    VStack {
                        Text(model.plays)
                            .font(.avnRegular(28))
                            .foregroundColor(.blueBold)
                            .lineLimit(1)
                            .shadow(
                                color: .whitea(0.8),
                                radius: 1,
                                x: 0,
                                y: -0.5
                            )
                            .padding(.bottom, -5)
                        Text("plays")
                            .font(.avnUltraLight(15))
                            .foregroundColor(.gray(126))
                            .lineLimit(1)
                            .padding(.top, -5)
                    }
                    .padding(.trailing, 2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                Rectangle()
                    .foregroundColor(.blacka(0.1))
                    .frame(height: 1)
            }
            .background(Color.whiteSubtle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeeklyAlbumChartCell_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartCell(.init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
            .previewLayout(.sizeThatFits)
    }
}

struct ErrorRetryView: View {
    struct Model {
        let title: String
        let subtitle: String
        let action: (() -> ())?

        init(title: String, subtitle: String, action: (() -> ())? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.action = action
        }
    }

    let model: Model

    var body: some View {
        HStack {
            VStack {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .foregroundColor(.blueDark)
                Text(model.title)
                    .font(.avnMedium(27))
                    .foregroundColor(.blueDark)
                    .shadow(color: .white, radius: 1, x: 0, y: -0.5)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                Text(model.subtitle)
                    .font(.avnRegular(13))
                    .foregroundColor(.blueDark)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                if let action = model.action {
                    Button(action: action) {
                        Text("try again")
                            .font(.avnMedium(18))
                            .foregroundColor(.bluePeri)
                            .padding(.all, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8.0)
                                    .foregroundColor(.blueDark)
                            )
                    }
                }
            }
            .padding(.all, 16)
        }
    }
}

struct ErrorRetryView_Previews: PreviewProvider {
    static let mock = ErrorRetryView.Model(title: "The internet connection appears to be offline.", subtitle: "Connect to the internet and try again.")
    static var previews: some View {
        ErrorRetryView(model: mock)
            .previewLayout(.sizeThatFits)
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
    ]
