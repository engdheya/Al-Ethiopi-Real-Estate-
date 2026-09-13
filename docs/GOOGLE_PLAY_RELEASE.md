# Google Play Release Guide — الأثيوبي للعقارات

## 0. Checklist before release

- [ ] Real `android/app/google-services.json` from your Firebase project
- [ ] Release SHA-1 added in Firebase Console (Project settings > Your apps)
- [ ] `flutter analyze` clean, `flutter test` green
- [ ] Tested on a real device (browse → details → call/WhatsApp → comment → admin flow)
- [ ] App content added via the admin panel (no demo/placeholder content)
- [ ] Privacy policy URL ready (Play Console requires it — you can host the text from **App settings > privacy** on any free page)

## 1. Application ID

Default placeholder:

```
com.alethiopi.realestate
```

To change it (do this **before** first Play upload — it can never change after):

1. `android/app/build.gradle.kts` → `applicationId` (+ `namespace`)
2. Rename package dir `android/app/src/main/kotlin/com/alethiopi/realestate/` + `package` line in `MainActivity.kt`
3. Register the **new** package in Firebase and download a new `google-services.json`
4. Update `AppConstants.androidApplicationId` + `playStoreUrl` in `lib/core/constants/app_constants.dart`

## 2. Create the upload keystore (once)

```bash
keytool -genkeypair -v \
  -keystore ~/alethiopi-upload-keystore.jks \
  -alias alethiopi \
  -keyalg RSA -keysize 2048 -validity 10000
```

> **Back up this file + passwords securely.** Losing it means you can never update the app.

Create `android/key.properties` (git-ignored, never commit):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=alethiopi
storeFile=/absolute/path/to/alethiopi-upload-keystore.jks
```

Get the **release SHA-1** and add it to Firebase Console + Google Sign-In will keep working:

```bash
keytool -list -v -keystore ~/alethiopi-upload-keystore.jks -alias alethiopi
```

## 3. Versioning

In `pubspec.yaml`:

```yaml
version: 1.0.0+1   # <versionName>+<versionCode>
```

- Bump `versionName` for users (`1.0.1`, `1.1.0`, ...).
- **Always** increment `versionCode` (the `+N`) for every Play upload.

## 4. Build

```bash
# Smoke-check APK (installable directly on devices)
flutter build apk --release

# Play Store upload artifact (preferred)
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 5. Play Console upload

1. Create the app in [Play Console](https://play.google.com/console) (Arabic default language).
2. Upload the `.aab` to **Production** (or Internal testing first — recommended).
3. Fill in: store listing (Arabic description + screenshots), content rating questionnaire, target audience, privacy policy URL, data safety form:
   - Data collected: name, email (account), phone (contact form), photos (avatars/property images), FCM token.
   - Purpose: app functionality + account management. No data sold to third parties.
4. Roll out.

## 6. Post-release

- Monitor **Firebase Console > Crashlytics**? (not integrated — consider adding `firebase_crashlytics` in v1.1).
- Watch Firestore/Storage usage quotas.
- Every update: bump version → `flutter build appbundle --release` → upload new `.aab`.

## 7. Regenerating branding (optional)

```bash
# Launcher icons (config in pubspec.yaml)
dart run flutter_launcher_icons

# Native splash screens
dart run flutter_native_splash:create
```
