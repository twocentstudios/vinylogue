# Sprint 6 – Detailed TODO Checklist (SettingsSheet + Play‑Count Filter)

> Blocks Sprint 7. Tick tasks when merged.

## 1. SettingsSheet UI

- [ ] **Present as `.sheet`** from gear icon.
- [ ] Sections:
  - [ ] Current User (tap to log‑out → clears `@Shared("currentUser")`).
  - [ ] Play‑Count Filter slider (0–100 in steps of 5).
  - [ ] Friends list “Refresh Now” button.
  - [ ] App version/build info.

## 2. Play‑Count Filter Logic

- [ ] Store value via `@Shared("playCountFilter")`.
- [ ] WeeklyAlbumsView applies filter in list.

## 3. Refresh Friends Action

- [ ] Calls `FriendsImporter.refresh()` and updates list.

## 4. Settings Access

- [ ] Show gear icon in UsersListView & WeeklyAlbumsView nav bars.

## 5. Tests & Docs

- [ ] UI test: change filter to 30 → albums below 30 hidden.
- [ ] README: document settings options.

---

*End of Sprint 6 Checklist*
