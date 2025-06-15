# Sprint 4 – Detailed TODO Checklist (WeeklyAlbumsView + Year Navigation)

> Blocks Sprint 5. Tick boxes when merged.

## 1. Date Handling

- [ ] **Extend `CalendarWeek`**: helper `shift(years:)` to compute same week N years ago.
- [ ] Provide computed properties `startDate`, `endDate`.

## 2. WeeklyAlbumsView

- [ ] **Design layout**:
  - [ ] `LazyVStack` inside `ScrollView`.
  - [ ] Large row: artwork (80×80), album title, artist, play count.
  - [ ] AsyncImage via Nuke with placeholder colour.
- [ ] **Data source**:
  - [ ] On appear, call `WeeklyAlbumLoader` (see below).
  - [ ] Supports refresh control to refetch.

## 3. Data Loader

- [ ] **Implement `WeeklyAlbumLoader`**:
  - [ ] Attempt cache lookup via `ChartCache`.
  - [ ] If miss → call `LastFMClient.weeklyAlbumChart`.
  - [ ] Decode into `[Album]` sorted by play count.
  - [ ] Save raw JSON back to cache.

## 4. Year Navigation Buttons

- [ ] **Bottom “← Previous Year”**:
  - [ ] Shifts `currentYearOffset += 1`.
  - [ ] Disabled if beyond oldest Last.fm year (2002).
- [ ] **Top “Next Year →”**:
  - [ ] Only visible when `currentYearOffset > 0`.

## 5. Dynamic Type & Accessibility

- [ ] Row heights adapt to text size.
- [ ] VoiceOver hints for navigation buttons (“Shows albums from …”).

## 6. Tests & CI

- [ ] Unit test: cache hit path returns instantly.
- [ ] UI tests:
  - [ ] Scroll performance at 60 fps on iPhone 15 Mini.
  - [ ] Year button visibility logic.

---

*End of Sprint 4 Checklist*
