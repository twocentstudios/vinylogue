import Nuke
import SwiftUI

// MARK: - Environment Keys

private struct LastFMClientKey: EnvironmentKey {
    static let defaultValue: LastFMClientProtocol = LastFMClient()
}

private struct ImagePipelineKey: EnvironmentKey {
    static let defaultValue = ImagePipeline.shared
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    var lastFMClient: LastFMClientProtocol {
        get { self[LastFMClientKey.self] }
        set { self[LastFMClientKey.self] = newValue }
    }

    var imagePipeline: ImagePipeline {
        get { self[ImagePipelineKey.self] }
        set { self[ImagePipelineKey.self] = newValue }
    }
}
