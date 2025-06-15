import SwiftUI
// import Nuke // TODO: Add Nuke package dependency

// MARK: - Environment Keys

private struct LastFMClientKey: EnvironmentKey {
    static let defaultValue = LastFMClient()
}

private struct ImagePipelineKey: EnvironmentKey {
    static let defaultValue: String = "placeholder" // TODO: Replace with ImagePipeline.shared
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
    
    var imagePipeline: String {
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