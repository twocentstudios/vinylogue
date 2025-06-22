import Foundation
import Nuke

extension ImagePipeline {
    static func withTemporaryDiskCache() -> ImagePipeline {
        let dataCache = try? DataCache(name: "VinylogueImages")
        var configuration = ImagePipeline.Configuration()
        configuration.dataCache = dataCache
        return ImagePipeline(configuration: configuration)
    }
}
