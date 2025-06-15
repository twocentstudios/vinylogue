# Sprint 5 – Detailed TODO Checklist (AlbumDetailView + Colour Animation)

> Blocks Sprint 6. Tick when merged.

## 1. Colour Extraction Utility

- [ ] **Port dominant‑colour algorithm** using Core Image `CIAreaAverage`.
- [ ] Provide extension `Album.dominantColor` (lazy cached).

## 2. AlbumDetailView

- [ ] **Layout**:
  - [ ] Full‑screen `ZStack` gradient background (dominant colour → black opacity 0.8).
  - [ ] VStack: artwork (max 240×240), title, artist, play count, description scroll.
- [ ] **Navigation**: uses system back button.

## 3. Transition Animation

- [ ] Implement `matchedGeometryEffect` for artwork size + fade.
- [ ] Background colour fades with `.easeInOut(duration: 0.6)`.

## 4. Description Fetch

- [ ] Lazy load album description via `LastFMClient.albumInfo`.
- [ ] Cache description inside `ChartCache` companion file `<hash>.info.json`.

## 5. Dynamic Type / Accessibility

- [ ] Support larger accessibility text sizes.
- [ ] VoiceOver reads description on focus.

## 6. Tests

- [ ] Snapshot tests for light colour vs dark colour backgrounds.
- [ ] Performance test: detail push < 16 ms frame time.

---

*End of Sprint 5 Checklist*
