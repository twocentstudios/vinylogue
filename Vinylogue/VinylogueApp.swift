import Nuke
import SwiftUI

@main
struct VinylogueApp: App {
    @State private var lastFMClient = LastFMClient()
    @State private var imagePipeline = ImagePipeline.withTemporaryDiskCache()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.lastFMClient, lastFMClient)
                .environment(\.imagePipeline, imagePipeline)
        }
    }
}
