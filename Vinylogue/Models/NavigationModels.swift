import Foundation

// MARK: - Navigation Value Types

/// Lightweight navigation value for user-based navigation
struct UserNavigation: Hashable {
    let user: User
}

/// Lightweight navigation value for album detail navigation
struct AlbumNavigation: Hashable {
    let album: Album
    let weekInfo: WeekInfo
}
