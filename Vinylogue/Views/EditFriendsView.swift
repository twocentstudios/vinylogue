import Combine
import Dependencies
import Sharing
import SwiftUI

struct EditFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: EditFriendsStore

    var body: some View {
        NavigationView {
            List {
                if store.currentUsername != nil {
                    Section {
                        ImportFriendsButton(
                            isLoading: store.isImportingFriends,
                            action: {
                                Task { await store.importFriends() }
                            }
                        )
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())

                        AddFriendButton {
                            store.showAddFriend()
                        }
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    } header: {
                        SectionHeaderView("add friends", topPadding: 20)
                            .listRowInsets(EdgeInsets())
                    }
                }

                Section {
                    if store.hasEditableFriends {
                        ForEach(store.editableFriends, id: \.username) { friend in
                            FriendEditRowView(
                                friend: friend,
                                isSelected: store.isFriendSelected(friend)
                            ) { _ in
                                store.toggleFriendSelection(friend)
                            }
                            .listRowBackground(Color.primaryBackground)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                        }
                        .onMove(perform: store.moveFriends)
                        .onDelete(perform: store.deleteFriends)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2")
                                .font(.system(size: 40))
                                .foregroundColor(.accent.opacity(0.6))

                            Text("no friends in your curated list")
                                .font(.f(.medium, .headline))
                                .foregroundColor(.primaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.primaryBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                } header: {
                    SectionHeaderView("friends (hold & drag to reorder)", topPadding: 20)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .background(Color.primaryBackground)
            .navigationTitle("edit friends")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                }

                ToolbarItem(placement: .principal) {
                    Text("edit friends")
                        .foregroundStyle(Color.vinylogueBlueDark)
                        .font(.f(.regular, .headline))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        store.saveFriends()
                        dismiss()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                    .sensoryFeedback(.success, trigger: store.curatedFriends)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button("select \(store.selectAllButtonText)") {
                        store.toggleSelectAll()
                    }
                    .contentTransition(.numericText())
                    .font(.f(.medium, .body))
                    .foregroundColor(.accent)
                    .disabled(!store.hasEditableFriends)
                    .sensoryFeedback(.selection, trigger: store.selectedFriends)

                    Spacer()

                    Button("delete selected (\(store.selectedCount))") {
                        store.deleteSelectedFriends()
                    }
                    .font(.f(.medium, .body))
                    .foregroundColor(.destructive)
                    .disabled(!store.hasSelectedFriends)
                    .sensoryFeedback(.warning, trigger: store.selectedCount)
                }
            }
            .sheet(isPresented: $store.showingAddFriend) {
                AddFriendView(store: store.addFriendStore) { newFriend in
                    store.addFriend(newFriend)
                }
            }
        }
        .onAppear {
            store.loadFriends()
        }
        .onChange(of: store.friendsImporter.friendsState) { _, friendsState in
            if case let .loaded(importedFriends) = friendsState {
                store.handleImportedFriends(importedFriends)
            }
        }
    }
}

// MARK: - Friend Edit Row View

private struct FriendEditRowView: View {
    let friend: User
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void

    var body: some View {
        Button(action: { onSelectionChanged(!isSelected) }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accent : .gray)
                    .font(.system(size: 20))

                Text(friend.username)
                    .font(.f(.regular, .title2))
                    .foregroundColor(.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Import and Add Friend Buttons

private struct ImportFriendsButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    AnimatedLoadingIndicator(size: 20)
                } else {
                    Image(systemName: "square.and.arrow.down")
                }

                Text(isLoading ? "importing..." : "import friends from last.fm")
                    .font(.f(.regular, .title2))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: isLoading)
        .foregroundColor(.accent)
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AddFriendButton: View {
    let action: () -> Void
    @State private var buttonPressed = false

    var body: some View {
        Button(action: {
            buttonPressed.toggle()
            action()
        }) {
            HStack {
                Image(systemName: "person.badge.plus")

                Text("add friend manually")
                    .font(.f(.regular, .title2))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.impact, trigger: buttonPressed)
        .foregroundColor(.accent)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview {
    let store = EditFriendsStore()
    return EditFriendsView(store: store)
        .onAppear {
            store.$currentUsername.withLock { $0 = "musiclover123" }
            store.$curatedFriends.withLock { $0 = [
                User(username: "rockfan92", realName: "Alex Johnson", playCount: 15432),
                User(username: "jazzlover", realName: "Sarah Miller", playCount: 8901),
                User(username: "metalhead", realName: nil, playCount: 23456),
            ] }
            store.loadFriends()
        }
}
