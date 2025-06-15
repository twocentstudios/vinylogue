import Foundation
import Nuke

extension ImagePipeline {
    static func withTemporaryDiskCache() -> ImagePipeline {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VinylogueImages")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        
        // Create data cache in temporary directory
        let dataCache = try? DataCache(name: "VinylogueImages")
        
        var configuration = ImagePipeline.Configuration()
        configuration.dataCache = dataCache
        
        return ImagePipeline(configuration: configuration)
    }
}