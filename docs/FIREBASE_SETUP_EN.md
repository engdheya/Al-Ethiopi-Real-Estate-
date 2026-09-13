# Firebase Setup Guide — Al-Ethiopi Real Estate

> The full step-by-step guide is in Arabic: [FIREBASE_SETUP_AR.md](FIREBASE_SETUP_AR.md).
> This is the condensed English version. No VPS/server needed — Firebase only.

**Requirements:** a Google account + Flutter stable 3.24+.

## Steps

1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com/) (e.g. `alethiopi-real-estate`).
2. **Add an Android app** with package name (must match exactly):
   ```
   com.alethiopi.realestate
   ```
   Add your debug + release **SHA-1** fingerprints (`cd android && ./gradlew signingReport`) — required for Google Sign-In.
3. **Download `google-services.json`** into `android/app/google-services.json`. Without it the app boots into demo mode.
4. **Enable Authentication** → Email/Password (+ Google provider, recommended).
5. **Create Firestore Database** (production mode, pick one region).
6. **Enable Storage** (production mode).
7. **FCM** works out of the box (no extra keys; uses `google-services.json`).
8. **Deploy rules + indexes:**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```
9. **Deploy Cloud Functions** (counters + push; needs Blaze pay-as-you-go, free tiers apply):
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```
10. **Seed demo data** (optional):
    ```bash
    cd scripts && npm install
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_demo_data.js
    ```
11. **Create the single admin:** register in the app, then:
    ```bash
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node make_admin.js you@example.com
    ```
    Sign out/in again. The Admin Panel card appears in the Account tab.
12. **Run:**
    ```bash
    flutter pub get
    flutter run
    ```

## Security model (summary)

- Admin rights = Firebase Auth **custom claim** `admin: true` only.
- `firestore.rules` / `storage.rules` enforce everything server-side:
  public reads published content; users touch only their own comments/ratings/
  favorites/profile; only admin writes properties/lookups/settings and
  moderates comments.
- Push + counters run in `functions/` (serverless, no VPS).

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Demo mode" banner | Missing/wrong `android/app/google-services.json`; rebuild |
| `permission-denied` | Deploy rules (step 8); ensure signed in |
| No admin panel | Run `make_admin.js`, then sign out/in |
| Google sign-in fails | Add SHA-1 (debug + release) in project settings |
| `failed-precondition` | Missing composite index — deploy `firestore.indexes.json` |
| Uploads fail | Enable Storage + deploy `storage.rules` |
