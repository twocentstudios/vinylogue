import SwiftUI

struct WeeklyAlbumChartView: View {
    struct Model {
        struct Section {
            let label: String
            let albums: [WeeklyAlbumChartCell.Model]
        }

        let sections: [Section]
    }

    let model: Model

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(model.sections, id: \.label) { section in
                    Section(header: WeeklyAlbumChartHeaderView(label: section.label)) {
                        ForEach(section.albums, id: \.album) { album in
                            WeeklyAlbumChartCell(model: album)
                        }
                    }
                }
            }
        }
        .navigationTitle("ybsc's week 27 charts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            ProgressView()
        )
        .background(Color.whiteSubtle.edgesIgnoringSafeArea(.all))
    }
}

struct WeeklyAlbumChartView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WeeklyAlbumChartView(model: .init(sections: mockSections))
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

    private var imageView: Image {
        if let image = model.image {
            return Image(uiImage: image)
        } else {
            return Image("recordPlaceholderThumb")
        }
    }

    var body: some View {
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
    }
}

struct WeeklyAlbumChartCell_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartCell(model: .init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
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
        .init(label: "2018", albums: mockAlbums),
    ]
