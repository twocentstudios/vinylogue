# Sprint 2 – Detailed TODO Checklist (Data Migration Utility + OnboardingView)

> Blocks Sprint 3. Check `[x]` once merged into `main`.

## 1. Legacy Data Migration

- [ ] **Locate legacy store**: Detect Core Data sqlite files & `NSUserDefaults` keys (`currentUser`, `friends*`, `playCountFilter`).
- [ ] **Design migration structs** mirroring legacy entities: `LegacyUser`, `LegacyFriend`, `LegacySettings`.
- [ ] **Implement `LegacyMigrator`** with async `migrateIfNeeded()`:
  - [ ] Load legacy data.
  - [ ] Map to new `@Shared` keys.
  - [ ] Remove legacy sqlite & prefs on success.
- [ ] **Unit tests** with temp directories simulating legacy store.
- [ ] **Telemetry**: Log `migrationComplete` message; no external analytics.

## 2. OnboardingView

- [ ] **Create `OnboardingView`**:
  - [ ] Single `TextField` for Last.fm username.
  - [ ] `Submit` button validates by calling `LastFMClient.friendsList`.
  - [ ] Persist username via `@Shared("currentUser")`.
- [ ] **Add basic styling** matching legacy palette; support Dynamic Type.
- [ ] **Error states**: invalid username, network failure.
- [ ] **Accessibility**: VoiceOver labels & keyboard focus order.

## 3. RootView Logic

- [ ] **Implement `RootView`** flow:
  - [ ] If `currentUser` exists → show `UsersListView` placeholder.
  - [ ] Else → present `OnboardingView`.
- [ ] **Hook migration** in `VinylogueApp` `init` before state is read.

## 4. Tests & CI

- [ ] **UI test**: First‑launch with clean prefs shows Onboarding.
- [ ] **UI test**: After entering valid user, app launches to UsersListView.
- [ ] Ensure GitHub Actions passes all new unit & UI tests.

## 5. Documentation

- [ ] Update README “Migration & Onboarding” section with instructions.
- [ ] Add GIF demo of onboarding flow (optional).

---

*End of Sprint 2 Checklist*
