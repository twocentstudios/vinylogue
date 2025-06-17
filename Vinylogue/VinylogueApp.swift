import Nuke
import Sharing
import SwiftUI

@main
struct VinylogueApp: App {
    @State private var lastFMClient = LastFMClient()
    @State private var imagePipeline = ImagePipeline.withTemporaryDiskCache()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.lastFMClient, lastFMClient)
                .environment(\.imagePipeline, imagePipeline)
        }
    }
}
