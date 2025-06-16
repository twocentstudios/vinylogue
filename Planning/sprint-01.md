# Sprint 1 – Detailed TODO Checklist (Last.fm Client + JSON Cache)

> Each task is blocking for Sprint 2. Tick each box `[x]` after the PR is merged into `main`.

## 1. Last.fm Networking Layer

- [✅] **Define API endpoints** as `enum LastFMEndpoint` with cases: `.weeklyAlbumChart`, `.friendsList`, `.albumInfo`, `.userInfo`, `.weeklyChartList`.
- [✅] **Implement `LastFMRequest`** builder to produce `URLRequest` with signed query parameters (`api_key`, `format=json`).
- [✅] **Create `LastFMClient`** with async function `func fetch(_ endpoint: LastFMEndpoint) async throws -> Data`.
- [✅] **Add typed decode helpers**: `func weeklyAlbumChart(...) -> WeeklyAlbumChart`, `func friendsList(...) -> [User]`, `func albumInfo(...) -> Album`.
- [✅] **Define `LastFMError` enum** (networkFailure, decodingError, rateLimited, apiError).
- [✅] **Unit tests** for `LastFMClient` using custom `URLProtocol` stubs (success & error paths).

## 2. Date Utilities

- [✅] **Implement `CalendarWeek` struct** that can:
  - [✅] Convert `(Date)` → `(start, end)` for ISO-8601 week.
  - [✅] Shift week by `-n` years maintaining week number.
- [✅] **Unit tests** for edge cases (leap years, week 1 vs week 52/53).

## 3. JSON Chart Cache

- [✅] **Finalize `ChartCache`** (declared in Sprint 0) with:
  - [✅] SHA-256 key generator from `(user, startDate, endDate)`.
  - [✅] `load` & `save` methods (async) using `Data(contentsOf:)` & `write` with `.atomic`.
  - [✅] Automatic folder creation `{tmp}/VinylogueCache/<user>/`.
- [✅] **Concurrency safety**: guard with `NSLock` or serial `DispatchQueue` to avoid race conditions.
- [✅] **Unit tests** verifying hit/miss logic and tmp-dir purge tolerance.

## 4. Image Pipeline Configuration (Nuke)

- [✅] **Provide `ImagePipeline.withTemporaryDiskCache()`** returning `ImagePipeline` with `DataCache(name: "VinylogueImages", directory: .temporaryDirectory)`.
- [✅] **Integration test** fetching a dummy image and reading it back from cache.

## 5. Environment Injection

- [✅] **Add `EnvironmentKeys`** defined in Sprint 0 to the code-base.
- [✅] **Extend `VinylogueApp`** to initialise `LastFMClient` & `ImagePipeline` and inject via `.environment`.
- [✅] **Smoke test** in a placeholder `RootView` calling `LastFMClient` and logging result to console.

## 6. Documentation & CI

- [✅] **Update README** with steps to configure `Secrets.swift` and run unit tests.
- [✅] **Add coverage badge** to README once CI passes.
- [✅] **Ensure GitHub Actions** runs unit tests for `LastFMClient`, `ChartCache`, `CalendarWeek`.

---

*End of Sprint 1 Checklist*
