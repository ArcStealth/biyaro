# Biyaro - Plan

**Goal:** a free, subscription-free motorcycle ride tracker with accounts, profile photos and a rider leaderboard. Open-source, released on GitHub.

## Stack
| Part | Choice | Why |
|---|---|---|
| App | Flutter (Dart), Android only for now | one codebase, real sensor access, easy to build in CI |
| Backend | Supabase (free tier) | Postgres + login + photo storage with no credit card |
| GPS | `geolocator` in an Android foreground service | keeps tracking with the screen off |
| Motion | `sensors_plus` accelerometer | peak G-force |
| Maps | route drawn offline (coloured by speed) | no API keys, no cost |
| Build | GitHub Actions | APK built in the cloud, attached to each release |

## How it fits together
```
Phone (Flutter)
  Tracker  -> GPS stream + accelerometer
  TripEngine (pure Dart) -> distance, stops, top speed, turns, lane changes,
                            brake events, max accel/decel, peak G, route
  Api -> Supabase: Auth | profiles | trips | avatars bucket | get_leaderboard()
```
Routes are private (only the owner can read them). The leaderboard only exposes totals.

## Milestones
**v0.1.0-alpha (this drop)**
- Sign up / log in, rider name, profile photo, motorcycle name
- Live ride screen with all requested stats and route
- Post-ride summary card + Share (picture) button
- My trips + lifetime totals
- Leaderboard: distance / top speed / trips, tap a rider to see photo + bike
- Offline queue: rides recorded without internet upload later

**v0.2 - accuracy and polish**
- Tune turn / lane-change / brake thresholds from real rides (all in `trip_engine.dart`)
- Street map under the route (needs a tile provider choice)
- App icon + splash, password reset, delete account

**v0.3 - community**
- Weekly / monthly leaderboards, friends or clubs, per-bike ranking
- Anti-cheat checks (impossible speeds, teleporting, phone in a car)
- Release signing key (so alpha updates install over each other) and an in-app "new version" check against GitHub Releases

## Known limits of the alpha
- Turns, lane changes and brakes are *estimated* from GPS; expect misses/false hits until tuned.
- Peak G depends on how firmly the phone is mounted.
- Supabase free projects **pause after ~7 days of no activity** (data is kept; un-pause from the dashboard).
- Free tier: 500 MB database, 1 GB photo storage - plenty for an alpha.
- Leaderboard values are reported by the app; nothing stops a modified app from cheating yet.
- CI-built APKs use a debug signing key that changes per build, so testers must uninstall before installing a newer alpha (fixed in v0.3 with a real key).
