import SwiftUI

struct WeeklyAlbumChartView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                WeeklyAlbumChartHeaderView(label: "WEEK 27 of 2019")
//                ForEach(friends, id: \.self) { friend in
//                    SimpleCell(friend)
//                }
            }
        }
        .navigationTitle("ybsc's charts")
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
            WeeklyAlbumChartView()
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
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.bluePeri)
    }
}

struct WeeklyAlbumChartHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartHeaderView(label: "WEEK 27 of 2019")
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

    var body: some View {
        HStack(spacing: 9) {
            Image(uiImage: model.image ?? UIImage())
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
    }
}

struct WeeklyAlbumChartCell_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyAlbumChartCell(model: .init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
            .previewLayout(.sizeThatFits)
    }
}
