# Sprint 3 – Detailed TODO Checklist (UsersListView + Friend Curation)

> Blocks Sprint 4. Tick `[x]` when PRs merge.

## 1. UsersListView

- [ ] **Build `UsersListView`**:
  - [ ] `List` showing `currentUser` first, then curated friends.
  - [ ] Row contains display name.
  - [ ] Navigation link to WeeklyAlbumsView (placeholder).
- [ ] **Dynamic Type**: use `.font(.title3)` scaling.

## 2. Friend Import & Curation

- [ ] **Implement `FriendsImporter`**:
  - [ ] Fetch friends via `LastFMClient.friendsList`.
  - [ ] Store raw list in memory.
- [ ] **Curation UI**:
  - [ ] “Edit Friends” button → sheet with `List` + `.onMove` & checkmarks.
  - [ ] Persist selection & order to `@Shared("friends")`.
  - [ ] Tapping `import friends` adds only friends not present in current list.
  - [ ] Tapping `add friend` presents sheet with `EditUserView`.

## 3. State Handling

- [ ] Inject `@Environment(\.currentUser)` and `@Shared("friends")`.
- [ ] Ensure view refreshes when friends list changes.

## 4. Tests

- [ ] Unit tests for `FriendsImporter` network & mapping.
- [ ] UI test: reorder friends and relaunch → order persists.

## 5. Docs & CI

- [ ] Update README: friend curation usage.
- [ ] Ensure CI scales for additional UI tests.

---

*End of Sprint 3 Checklist*
