# Vinylogue 2.0 – Product Requirements Document (v0.2)

**Date:** 2025‑06‑16  
**Target platform:** iOS 18 (UIKit availability, but **SwiftUI‑only implementation**)  
**Original app:** Vinylogue (2011, Objective‑C + UIKit)

---

## 1. Purpose

Rewrite the 2011 Last.fm companion app in **Swift + SwiftUI** while preserving the original user experience. The new architecture removes Objective‑C, UIKit, Combine and heavy databases, focusing on a lightweight, async/await‑driven code‑base that is easy to reason about and maintain.

---

## 2. Background

Legacy artefacts include 40+ Objective‑C source files, custom color‑extraction utilities, a non‑standard year picker, and Core Data bridging. Screenshots of the original design are available in */Planning/screenshots/*.

---

## 3. Scope

### 3.1 Must‑have functional requirements

|  ID  |  Feature                    |  Acceptance criteria |  
| ---- | --------------------------- | -------------------- |  
|  F1  | **Seamless data migration** | On first run after upgrade, migrate legacy `NSUserDefaults` keys (`currentUser`, `friendsOrder`, `playCountFilter`) and any on‑disk Core Data store into the new storage scheme (§5) with **no data-loss**. |  
|  F2  | **On‑boarding**             | Username entry view appears if no `currentUser` found. Uses `@Shared` storage to persist. |  
|  F3  | **Friend curation**         | Import full Last.fm friends list, allow editing + re‑ordering. Persist in `@Shared` under key `friends`. |  
|  F4  | **User selector**           | Root list shows current user + curated friends. Selecting a user navigates to weekly albums. |  
|  F5  | **Weekly albums**           | Display albums for the *same calendar week* N years ago. Show artwork, title, artist and play‑count. Sorted by play‑count. Uses cached JSON if available. |  
|  F6  | **Year navigation**         | Two safe‑area buttons: bottom ← Previous Year, top Next Year → (hidden if not applicable). |  
|  F7  | **Album detail**            | Full‑screen view with dominant‑colour background, description text, play‑count. Slow fade/scale animation. |  
|  F8  | **Settings**                | Standard SF Symbols "gearshape" icon. Allows: change username, refresh friends, set *play‑count filter* (persisted). |  
|  F9  | **Caching**                 | For each `user.getWeeklyAlbumChart` request, write the raw JSON response to **{tmp}/VinylogueCache/<user>/<from>-<to>.json**. The tmp container may be purged by the OS; fallback to network if missing. |  
|  F10 | **Image caching**           | All album artwork is fetched with **Nuke**, using its default in‑memory LRU plus a custom **tmp‑dir file cache** at **{tmp}/VinylogueImages/** (keyed by URL hash). |  
|  F11 | **Dynamic Type**            | Respect the user’s Dynamic Type size by using `Font.custom("<LegacyFontName>", size: style.dynamic)` and `.scaledToFit()` modifiers. Original colour palette retained; dark‑mode still out‑of‑scope. |  

### 3.2 Improvements vs legacy

1. Replace custom year slider with safe‑area buttons (§F6).
2. Use modern SF Symbols icon for settings.
3. Pure SwiftUI view hierarchy; **no ObservableObject view‑models** – state is local to each View. Shared values (e.g. current user) injected via `@Environment(\.currentUser)` with `@Shared` under the hood.
4. No Combine, Objective‑C, Core Data or SwiftData. Async/await only.
5. Flat‑file cache in system temporary directory (auto‑purge friendly).
6. iOS 18 API baseline.

### 3.3 Out‑of‑scope

- iPad, Mac Catalyst, visionOS.
- Live Activities, analytics, iCloud sync.
- Dark‑mode, RTL.

---

## 4. User experience

```
OnboardingView  ──▶  UsersListView  ──▶  WeeklyAlbumsView  ──▶  AlbumDetailView
                     ▲                             │
                     └──────── SettingsSheet ◀─────┘
```

*Year navigation buttons appear on WeeklyAlbums & AlbumDetail.*

### Dynamic Type strategy

```swift
extension Font {
  static func vinylogueTitle(_ style: UIFont.TextStyle = .title2) -> Font {
      Font.custom("HelveticaNeue-Bold", size: UIFont.preferredFont(forTextStyle: style).pointSize)
  }
}
```

---

## 5. Data & Storage

### 5.1 API endpoints

_Unchanged from v0.1: `user.getWeeklyAlbumChart`, `user.getFriends`, `album.getInfo`._

### 5.2 Storage layers

| Layer                | Tech                      | Purpose |  
| -------------------- | ------------------------- | ------- |  
| **Shared Key‑Value** | `@Shared(UserDefaults)`   | `currentUser`, curated friends array, play‑count filter. |  
| **Chart cache**      | Flat JSON per request     | Stored in `FileManager.default.temporaryDirectory` → `VinylogueCache`. Key = SHA256 of request params. |  
| **Image cache**      | **Nuke** + tmp‑file store | Auto‑pruned by OS; falls back to Nuke pipeline network fetch. |  

### 5.3 Migration plan

1. Detect presence of old Core Data store / defaults on launch.  
2. Parse entities → equivalent structs (`User`, curated friends, filter).  
3. Write to new `@Shared` keys.  
4. Delete old store to avoid double‑migrate.  

---

## 6. Architecture

- **SwiftUI view hierarchy only.** No intermediate `ObservableObject` view‑models.  
- **Dependency injection** via custom `EnvironmentKey`s: `LastFMClient`, `ImagePipeline`, `PlayCountFilter`.  
- **Stateless clients** created once in `@main` App (`VinylogueApp`).  
- **Concurrency:** `async/await` networking (`URLSession.shared.data(for:)`).  
- **Error handling:** `Task` cancellation tokens + `retry(2)` wrapper util.  

```swift
struct VinylogueApp: App {
  @State private var lastFM = LastFMClient(apiKey: Secrets.apiKey)
  @State private var imagePipeline = ImagePipeline(configuration: .withTemporaryDiskCache())
  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(\.lastFM, lastFM)
        .environment(\.imagePipeline, imagePipeline)
    }
  }
}
```

---

## 7. Non‑functional requirements

| Category      | Spec |  
| ------------- | ---- |  
| Performance   | ≤150 ms initial load on iPhone 15 Mini. |  
| Memory        | ≤150 MB after 30 min casual browsing. |  
| Offline       | Album list shows cached week if network offline. |  
| Accessibility | VoiceOver labels and Dynamic Type AA. |  
| Privacy       | Only Last.fm username stored; no analytics. |  

---

## 8. Acceptance tests

1. Upgrade from v1.x with existing user → current user & curated list persist.  
2. Force‑quit, delete tmp dir → app refetches data without crash.  
3. Dynamic Type set to XXL → text scales, layout intact.  
4. Set play‑count filter to ≥20 → lists exclude albums <20 plays.  
5. Settings gear uses SF Symbols `gearshape`.  
6. Year navigation buttons hide/show correctly at boundaries.  

---

## 9. Milestones (indicative)

| Sprint | Goal |  
| ------ | ---- |  
| 0 | Project scaffolding, EnvironmentKeys, Nuke setup |  
| 1 | Last.fm client + JSON cache |  
| 2 | Data‑migration utility + OnboardingView |  
| 3 | UsersListView + Friend curation |  
| 4 | WeeklyAlbumsView + Year navigation |  
| 5 | AlbumDetailView + colour animation |  
| 6 | SettingsSheet + play‑count filter |  
| 7 | Polish, TestFlight beta |  

---