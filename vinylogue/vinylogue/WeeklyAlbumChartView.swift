import ComposableArchitecture
import SwiftUI

struct WeeklyAlbumChartView: View {
    struct Model: Equatable {
        enum Status: Equatable {
            case initialized
            case loading
            case loaded([Section])
            case failed(ErrorRetryView.Model)
        }

        struct Section: Equatable, Identifiable {
            enum Status: Equatable {
                case initialized
                case loading
                case loaded([WeeklyAlbumChartCell.Model])
                case empty
                case failed
            }

            let id: LastFM.WeeklyChartRange.ID
            let label: String
            let status: Status
            var needsData: Bool { status == .initialized }
        }

        let title: String
        let status: Status
        var needsData: Bool { status == .initialized }
        var activeAlbumChartStubID: LastFM.WeeklyAlbumChartStub.ID?
    }

    let store: Store<WeeklyAlbumChartState, WeeklyAlbumChartAction>

    @Namespace private var albumImageNamespace

    var body: some View {
        WithViewStore(self.store.scope(state: \.view)) { viewStore in
            ZStack {
                switch viewStore.status {
                case .initialized, .loading:
                    OffsetRecordLoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                case let .failed(error):
                    ErrorRetryView(model: error) { viewStore.send(.fetchWeeklyChartList) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                case let .loaded(sections):
                    List {
                        ForEach(sections) { section in
                            Section(
                                header: WeeklyAlbumChartHeaderView(label: section.label)
                            ) {
                                switch section.status {
                                case .initialized, .loading:
                                    WeeklyAlbumChartLoadingCell()
                                        .onAppear { if section.needsData { viewStore.send(.fetchWeeklyAlbumChart(section.id)) } }
                                case .empty:
                                    WeeklyAlbumChartEmptyCell()
                                case let .loaded(albums):
                                    ForEach(albums, id: \.album) { album in
//                                        NavigationLink(
//                                            destination: IfLetStore(
//                                                self.store.scope(
//                                                    state: \.albumDetailState,
//                                                    action: WeeklyAlbumChartAction.albumDetail
//                                                ),
//                                                then: { AlbumDetailView(store: $0, albumImageNamespace: albumImageNamespace) }
//                                            ),
//                                            isActive: viewStore.binding(
//                                                get: { $0.activeAlbumChartStubID == album.id },
//                                                send: { WeeklyAlbumChartAction.setAlbumDetailView(isActive: $0, album.id) }
//                                            )
//                                        )
//                                        {
//                                            WeeklyAlbumChartCell(album, albumImageNamespace: albumImageNamespace)
//                                                .onAppear { if album.needsData { viewStore.send(.fetchImageThumbnailForChart(album.id)) } }
//                                        }

                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                viewStore.send(WeeklyAlbumChartAction.setAlbumDetailView(isActive: true, album.id))
                                            }
                                        }) {
                                            WeeklyAlbumChartCell(album, albumImageNamespace: albumImageNamespace)
                                        }
                                        .onAppear { if album.needsData { viewStore.send(.fetchImageThumbnailForChart(album.id)) } }
//                                        .sheet(isPresented: viewStore.binding(
//                                            get: { $0.activeAlbumChartStubID != nil },
//                                            send: { WeeklyAlbumChartAction.setAlbumDetailView(isActive: $0, album.id) }
//                                        )
//                                        ) {
//                                            IfLetStore(
//                                                self.store.scope(
//                                                    state: \.albumDetailState,
//                                                    action: WeeklyAlbumChartAction.albumDetail
//                                                ),
//                                                then: { AlbumDetailView(store: $0, albumImageNamespace: albumImageNamespace) }
//                                            )
//                                        }
                                    }
                                case .failed:
                                    WeeklyAlbumChartErrorCell { viewStore.send(.fetchWeeklyAlbumChart(section.id)) }
                                }
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
                if let activeAlbumChartStubID = viewStore.activeAlbumChartStubID {
                    IfLetStore(
                        self.store.scope(
                            state: \.albumDetailState,
                            action: WeeklyAlbumChartAction.albumDetail
                        ),
                        then: {
                            AlbumDetailView(store: $0, albumImageNamespace: albumImageNamespace)
                                .onTapGesture(count: 2) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewStore.send(WeeklyAlbumChartAction.setAlbumDetailView(isActive: false, activeAlbumChartStubID))
                                    }
                                }
                                .zIndex(1)
                                .transition(.move(edge: .bottom))
                        }
                    )
                }
            }
            .onAppear { if viewStore.needsData { viewStore.send(.fetchWeeklyChartList) } }
            .navigationTitle(viewStore.title) // TODO: split this up (it's too long)
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
        let title = "\(username)'s week \(weekOfYear) charts"
        let status: WeeklyAlbumChartView.Model.Status
        let activeAlbumChartStubID = (/ViewState.albumDetail).extract(from: viewState)?.albumChartStub.id
        switch weeklyChartListState {
        case .initialized:
            status = .initialized
        case .loading:
            status = .loading
        case .loaded:
            // Only show one loading cell at a time to prevent load thrashing
            let sections = displayingChartRanges.map(section)
            let firstLoadingIndex = sections.firstIndex(where: { $0.status == .initialized || $0.status == .loading })
            let filtered = firstLoadingIndex.flatMap { Array(sections.prefix(through: $0)) } ?? sections
            status = .loaded(filtered)
        case let .failed(error):
            _ = error // TODO: format error
            status = .failed(ErrorRetryView.Model(title: "An error occurred", subtitle: "Please try again"))
        }
        return WeeklyAlbumChartView.Model(title: title, status: status, activeAlbumChartStubID: activeAlbumChartStubID)
    }

    private func section(_ range: LastFM.WeeklyChartRange) -> WeeklyAlbumChartView.Model.Section {
        let title = titlesForChartRanges[range.id] ?? ""
        let status: WeeklyAlbumChartView.Model.Section.Status
        switch albumCharts[range.id] {
        case .none, .initialized:
            status = .initialized
        case .loading:
            status = .loading
        case let .loaded(albumChart):
            let cellModels = albumChart.charts.map(cellModel)
            status = cellModels.isEmpty ? .empty : .loaded(cellModels)
        case .failed:
            status = .failed
        }
        return WeeklyAlbumChartView.Model.Section(
            id: range.id,
            label: title,
            status: status
        )
    }

    private func cellModel(_ chart: LastFM.WeeklyAlbumChartStub) -> WeeklyAlbumChartCell.Model {
        let image: UIImage?
        // TODO: is it possible to use CasePaths?
        let albumImagesState: AlbumImagesState? = albumImageStubs[chart.id]
        if case .loaded = albumImagesState,
            let imageState = albumImageThumbnails[chart.id],
            case let .loaded(loadedImage) = imageState {
            image = loadedImage
        } else {
            image = nil
        }
        return WeeklyAlbumChartCell.Model(
            id: chart.id,
            image: image,
            artist: chart.artist.name,
            album: chart.album.name,
            plays: String(chart.playCount)
        )
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
    struct Model: Equatable, Identifiable {
        let id: LastFM.WeeklyAlbumChartStub.ID
        let image: UIImage?
        let artist: String
        let album: String
        let plays: String
        var needsData: Bool { image == nil }
    }

    let model: Model
    let albumImageNamespace: Namespace.ID

    init(_ model: Model, albumImageNamespace: Namespace.ID) {
        self.model = model
        self.albumImageNamespace = albumImageNamespace
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
                    .matchedGeometryEffect(id: model.id, in: albumImageNamespace)
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
//            WeeklyAlbumChartCell(.init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
//                .previewLayout(.sizeThatFits)
//            WeeklyAlbumChartCell(.init(image: nil, artist: "Weezer", album: "Maladroit", plays: "25"))
//                .previewLayout(.sizeThatFits)
//                .preferredColorScheme(.dark)
        }
    }
}

struct WeeklyAlbumChartEmptyCell: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("no charts this year")
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
    let action: (() -> ())?

    init(model: Model, action: (() -> ())? = nil) {
        self.model = model
        self.action = action
    }

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
//        .init(image: nil, artist: "Weezer", album: "Maladroit", plays: "20"),
//        .init(image: nil, artist: "Rufio", album: "The Comfort of Home", plays: "17"),
//        .init(image: nil, artist: "Saves The Day", album: "Sound The Alarm", plays: "2"),
    ]

let mockSections: [WeeklyAlbumChartView.Model.Section] =
    [
//        .init(label: "2019", status: .loaded(mockAlbums)),
//        .init(label: "2018", status: .empty),
//        .init(label: "2017", status: .failed),
//        .init(label: "2016", status: .loading),
//        .init(label: "2015", status: .initialized),
    ]

private struct TopBorderView: View {
    var body: some View {
        EmptyView() // TODO: did I leave this in by mistake?
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
