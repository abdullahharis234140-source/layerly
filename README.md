# Layerly - Text Behind Image Studio

## Run on your phone (Android recommended)
1. Install Flutter, then in this folder run:  `flutter create . --org com.layerly --project-name layerly`
   (generates android/ and ios/ folders; your lib/ and pubspec.yaml stay)
2. `flutter pub get`
3. Icon: `dart run flutter_launcher_icons`
4. Android: open android/app/build.gradle(.kts) and set `minSdk = 24`.
5. Plug in phone (USB debugging on) and run `flutter run`.
The app works WITHOUT Firebase (local mode). To enable the backend:
6. `dart pub global activate flutterfire_cli` then `flutterfire configure`
   Firebase Console: enable Authentication > Anonymous, create Firestore, paste firestore.rules.
7. Subscriptions: in Play Console / App Store Connect create subscriptions with IDs
   `layerly_pro_monthly` and `layerly_pro_yearly`, test with a licensed tester account.
8. In debug builds, long-press the "Layerly" title on Home to toggle Pro for testing.

## Backend (Firebase)
- Auth: anonymous sign-in (account per device)
- Firestore `users/{uid}`: pro, plan, exports counter, updatedAt
- Before launch: verify purchases in a Cloud Function, then write `pro` server-side.
