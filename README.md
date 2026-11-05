# Biyaro (alpha)

Free motorcycle ride tracker. No subscription, ever. Tracks distance, duration, stopped time, top speed, left/right turns, brake events, lane changes, max acceleration/deceleration and peak G-force, draws your route, and ranks riders on a leaderboard.

See `PLAN.md` for the roadmap.

## 1. Backend (Supabase) - about 10 minutes
1. Create a free project at https://supabase.com (pick a nearby region, e.g. Singapore). Save the database password.
2. Open **SQL Editor > New query**, paste all of `supabase/schema.sql`, press **Run**. It should say "Success".
3. **Authentication > Sign In / Providers > Email**: turn **off** "Confirm email" (alpha only - the free email sender is rate-limited).
4. Copy the **Project URL** (the **Connect** button) and the **publishable key** `sb_publishable_...` (**Settings > API Keys**).
5. Paste them into `lib/config.dart`. (Never use a secret / `service_role` key in the app.)

## 2. Build the app

### Option A - on your PC (best for testing on your phone)
Install Flutter (https://docs.flutter.dev/get-started/install/windows/mobile) and Android Studio, then:
```
flutter doctor --android-licenses
flutter create --platforms=android --org com.arcoco --project-name biyaro biyaro
```
Extract this zip **on top of** the new `biyaro` folder (overwrite everything), then:
```
cd biyaro
copy android_overlay\AndroidManifest.xml android\app\src\main\AndroidManifest.xml
del test\widget_test.dart
flutter pub get
flutter test
flutter run                      (phone plugged in, USB debugging on)
flutter build apk --release
```
APK: `build\app\outputs\flutter-apk\app-release.apk` - copy to your phone and install.

### Option B - GitHub builds it for you (no Flutter install)
1. Create a GitHub repo and push this folder.
2. **Actions > Build APK > Run workflow**, then download the `biyaro-apk` artifact.
3. To publish a release: `git tag v0.1.0-alpha` then `git push origin v0.1.0-alpha`. The APK is attached to a pre-release automatically.

## 3. First run checklist
- Sign up, add a photo + motorcycle name in **Profile**.
- Allow Location ("While using the app") and Notifications when asked.
- Start a ride, move around, stop, check the summary and **Share ride**.
- Open **Ranks** - you should appear after your first saved ride.

## Troubleshooting
- Build error: copy the red error text and send it back - it is usually a one-line fix.
- "Invalid API key" / network errors: re-check `lib/config.dart`.
- Photo upload fails: confirm the SQL ran fully (it creates the `avatars` bucket and policies).
- Tracking stops when the screen locks: Settings > Apps > Biyaro > Battery > **Unrestricted** (some brands kill background apps).
