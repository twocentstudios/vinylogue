import Dependencies
import Sharing
import SwiftUI

@MainActor
@Observable
final class EditFriendsStore: Identifiable {
    @ObservationIgnored @Shared(.currentUser) var currentUsername: String?
    @ObservationIgnored @Shared(.curatedFriends) var curatedFriends
    @ObservationIgnored @Dependency(\.lastFMClient) var lastFMClient

    var friendsImporter = FriendsImporter()
    var editableFriends: [User] = []
    var selectedFriends: Set<String> = []

    var addFriendStore: AddFriendStore?

    var isImportingFriends: Bool {
        if case .loading = friendsImporter.friendsState {
            return true
        }
        return false
    }

    var hasEditableFriends: Bool {
        !editableFriends.isEmpty
    }

    var hasSelectedFriends: Bool {
        !selectedFriends.isEmpty
    }

    var selectedCount: Int {
        selectedFriends.count
    }

    var allFriendsSelected: Bool {
        selectedFriends.count == editableFriends.count
    }

    var selectAllButtonText: String {
        allFriendsSelected ? "select none" : "select all"
    }

    init() {}

    func loadFriends() {
        editableFriends = curatedFriends
        selectedFriends = Set()
    }

    func importFriends() async {
        guard let username = currentUsername else { return }
        await friendsImporter.importFriends(for: username)
    }

    func handleImportedFriends(_ importedFriends: [User]) {
        let newFriends = friendsImporter.getNewFriends(excluding: editableFriends)

        if !newFriends.isEmpty {
            editableFriends.append(contentsOf: newFriends)
        }
    }

    func showAddFriend() {
        addFriendStore = withDependencies(from: self) {
            AddFriendStore { [weak self] addedUser in
                self?.addFriend(addedUser)
            }
        }
    }

    func addFriend(_ newFriend: User) {
        if !editableFriends.contains(where: { $0.username.lowercased() == newFriend.username.lowercased() }) {
            editableFriends.append(newFriend)
        }
    }

    func toggleFriendSelection(_ friend: User) {
        if selectedFriends.contains(friend.username) {
            selectedFriends.remove(friend.username)
        } else {
            selectedFriends.insert(friend.username)
        }
    }

    func isFriendSelected(_ friend: User) -> Bool {
        selectedFriends.contains(friend.username)
    }

    func moveFriends(from source: IndexSet, to destination: Int) {
        editableFriends.move(fromOffsets: source, toOffset: destination)
    }

    func deleteFriends(at offsets: IndexSet) {
        for offset in offsets {
            let deletedFriend = editableFriends[offset]
            selectedFriends.remove(deletedFriend.username)
        }

        editableFriends.remove(atOffsets: offsets)
    }

    func toggleSelectAll() {
        if allFriendsSelected {
            selectedFriends.removeAll()
        } else {
            selectedFriends = Set(editableFriends.map(\.username))
        }
    }

    func deleteSelectedFriends() {
        editableFriends.removeAll { friend in
            selectedFriends.contains(friend.username)
        }
        selectedFriends.removeAll()
    }

    func saveFriends() {
        $curatedFriends.withLock { $0 = editableFriends }
    }
}
