import Foundation
// import Nuke // TODO: Add Nuke package dependency

// TODO: Implement ImagePipeline extension once Nuke is added
/*
extension ImagePipeline {
    static func withTemporaryDiskCache() -> ImagePipeline {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VinylogueImages")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        
        let dataCache = try? DataCache(name: "VinylogueImages", url: temporaryDirectory)
        
        let configuration = ImagePipeline.Configuration()
        configuration.dataCache = dataCache
        
        return ImagePipeline(configuration: configuration)
    }
}
*/