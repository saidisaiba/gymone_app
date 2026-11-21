# CrossFit 1000 Hills — mobile app

Flutter app for members, coaches and admins of CrossFit 1000 Hills (Kigali).
It talks to the gym's existing API: `https://crossfit1000hills.com/calendar/api.php`.

## Features

| Who | Feature | Where the data lives |
|---|---|---|
| Everyone | Sign in, session kept between launches, auto sign-out when the session expires | Server (token on phone) |
| Everyone | Works offline: last schedule, bookings, WOD and announcements are shown from the phone | Phone (cache) |
| Everyone | **Step tracking** with the phone's motion sensor, daily goal ring, distance, calories, streak, 7/30-day charts | Phone; 1 summary row/day optionally backed up |
| Everyone | Water tracking with daily goal | Phone; included in the daily summary |
| Everyone | WOD timer: For Time, AMRAP (round counter), EMOM, Tabata | Phone only |
| Member | Membership status, days left, MoMo payment submission | Server |
| Member | Today's WOD, class schedule with spots left, book / cancel classes | Server |
| Member | Training log (WOD scores, Rx/scaled) and personal records with progress chart | **Phone only** |
| Member | Announcements, birthdays, coaches list, gym website | Server |
| Coach | My classes, attendance list for my classes | Server |
| Admin | Create/edit/delete accounts, renew memberships, proof-of-payment receipt, approve/reject MoMo payments, attendance for all classes | Server |

### Local vs. server storage

To save server storage, anything personal or high-volume stays on the phone (SQLite, `lib/services/local_db.dart`):

- full step/water history, the training log and PRs, cached server lists.

The server only keeps what must be shared or authoritative: accounts, memberships, payments, classes, bookings, announcements, and **one small row per member per day** in `health_metrics` (steps + water). The daily backup can be switched off on the Activity screen ("Back up daily totals to the gym"), in which case nothing activity-related is uploaded. When it is on, history is restored automatically on a new phone.

### How step counting works

- **Android**: reads the hardware step counter, which keeps counting while the app is closed. Steps since the last reading are added when the app is next opened. The first time, Android asks for *Physical activity* permission.
- **iPhone**: uses Core Motion while the app is open. Steps taken while the app is closed are not counted (a future HealthKit integration can add this).
- Phones without a sensor: members can enter steps manually (long-press the ring on the Activity screen).

## Project layout

```
lib/
  main.dart                 app start, session restore
  app_session.dart          sign-in / sign-out navigation
  theme.dart                colours and shared styles
  models/user_model.dart
  services/
    api_service.dart        HTTP client (token, fallbacks, offline cache)
    local_db.dart           on-device SQLite (activity, workouts, PRs, cache)
    step_tracker.dart       pedometer -> daily steps
    sync_service.dart       uploads daily activity summary
    storage_service.dart    token, goals, settings
  screens/                  one file per screen
  widgets/
archive/                    old review packages and unused code (not built, safe to delete)
```

## Server compatibility

The live API reports version 2.0; the oldest source kept here (archive/Documents/crossfit_1000_hills_mobile_api_package) is 1.0.
Some action names differ between versions (for example `get_classes` and `schedule`). The app tries the newer name first and only falls back when the server answers `Unknown API action`, so it works with both.

Check these on the server once, signed in as a real member:

1. Members are stored with role `user` (`users.role` is `ENUM('user','coach','admin')`). The app maps its "Member" role to `user` when it creates or edits accounts.
2. `save_health_metrics` (or a POST to `health_metrics`) saves today's steps. The `health_metrics` table already has the unique key `(user_id, record_date)` that this needs.
3. `payment_requests`, `approve_payment` and `reject_payment` are used by the admin "Payment requests" screen. The `payment_requests` table exists in the database.
4. The schedule only shows classes that exist in the `classes` table, so new weeks must be generated on the website. The app has no "create classes" endpoint.
5. Personal records stay on the phone. The server's `member_progress` table is not used, which saves server storage.

## Build and release

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release        # or: flutter build appbundle --release (Google Play)
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

**Android signing (required for Google Play).** Without a key, release builds are signed with debug keys. Those are fine for installing on test phones, but Google Play rejects them.

1. `keytool -genkey -v -keystore %USERPROFILE%\cf1000-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` (already git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=C:/Users/<you>/cf1000-upload.jks
   ```
3. Back up the `.jks` file and the passwords. Without them you cannot publish updates.

The application ID is `com.crossfit1000hills.app`. Change it before the first Play Store upload if you prefer another one, because it cannot change afterwards.

**iOS** (needs a Mac with Xcode): run `flutter build ios` once to generate `ios/Podfile`. Then add the following inside its `post_install` block, so the motion-permission code is compiled in:

```ruby
target.build_configurations.each do |config|
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_SENSORS=1']
end
```

**Windows build note.** `android/gradle.properties` sets `kotlin.incremental=false`, because the project (D:) and the Flutter package cache (C:) are on different drives. `permission_handler` is pinned to 12.0.1, because 13.x requires Android SDK 37.
