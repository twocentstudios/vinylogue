import Nuke
import SwiftUI

// MARK: - Environment Keys

private struct LastFMClientKey: EnvironmentKey {
    static let defaultValue = LastFMClient()
}

private struct ImagePipelineKey: EnvironmentKey {
    static let defaultValue = ImagePipeline.shared
}

private struct PlayCountFilterKey: EnvironmentKey {
    static let defaultValue: Int = 1
}

private struct CurrentUserKey: EnvironmentKey {
    static let defaultValue: User? = nil
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    var lastFMClient: LastFMClient {
        get { self[LastFMClientKey.self] }
        set { self[LastFMClientKey.self] = newValue }
    }

    var imagePipeline: ImagePipeline {
        get { self[ImagePipelineKey.self] }
        set { self[ImagePipelineKey.self] = newValue }
    }

    var playCountFilter: Int {
        get { self[PlayCountFilterKey.self] }
        set { self[PlayCountFilterKey.self] = newValue }
    }

    var currentUser: User? {
        get { self[CurrentUserKey.self] }
        set { self[CurrentUserKey.self] = newValue }
    }
}
