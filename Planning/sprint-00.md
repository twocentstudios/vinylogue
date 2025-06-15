## Sprint 0 – Detailed TODO Checklist (Project Scaffolding)

> All tasks are blocking for later sprints. Tick each checkbox (`[x]`) once the item is complete and merged into `main`.

### 0.1 Project & CI setup
- [ ] **Create Xcode project** “Vinylogue” (iOS 18+, SwiftUI App template, Bundle ID `com.<org>.vinylogue`).
- [ ] **Add GitHub Actions workflow** that performs: _build_, _unit-tests_, SwiftLint & SwiftFormat.
- [ ] **Integrate SwiftLint + SwiftFormat** locally via fastlane or pre-commit hook.

### 0.2 Dependencies (Swift Package Manager)
- [ ] Add **Nuke** (≥ 12.2) – product `Nuke`.
- [ ] Add **swift-sharing** (Point-Free) – product `SwiftSharing`.
- [ ] Verify packages resolve on CI.

### 0.3 Secrets handling
- [ ] Create **`Secrets.swift` placeholder** with `static let apiKey: String`.
- [ ] Add `Secrets.swift` to `.gitignore`; provide `Secrets.example.swift` for contributors.

### 0.4 Environment keys & dependency injection
- [ ] Define `struct LastFMClientKey: EnvironmentKey` + `EnvironmentValues.lastFM`.
- [ ] Define `struct ImagePipelineKey: EnvironmentKey` + `EnvironmentValues.imagePipeline`.
- [ ] Define `struct PlayCountFilterKey: EnvironmentKey` + `EnvironmentValues.playCountFilter`.
- [ ] Define `struct CurrentUserKey: EnvironmentKey` + `EnvironmentValues.currentUser` (`@Shared("currentUser")`).

### 0.5 Minimal client implementations
- [ ] Implement thin **`LastFMClient`** with async `request(_:)` that returns `Data`.
- [ ] Implement **`ImagePipeline.withTemporaryDiskCache()`** helper using Nuke `DataCache` located at `FileManager.default.temporaryDirectory/appImages`.

### 0.6 Cache utilities
- [ ] Create `ChartCache` utility: `func load(user: String, from: Date, to: Date) async throws -> Data?` & `save(_: Data, user: String, from: Date, to: Date)`; path = `{tmp}/VinylogueCache/{user}/{from}-{to}.json`.

### 0.7 App entry point
- [ ] Implement `VinylogueApp` that instantiates `LastFMClient`, `ImagePipeline`, injects them via `.environment` and sets `RootView()`.

### 0.8 Documentation
- [ ] Add **README** section “Sprint 0 checklist” with instructions to run lint + tests.

---
