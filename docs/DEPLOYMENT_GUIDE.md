# SoundScore Deployment Guide

Step-by-step instructions for deploying the SoundScore Edge Function API and
submitting iOS/Android builds to their respective stores.

---

## Prerequisites

- Supabase CLI installed (`npm i -g supabase`)
- Supabase project created at [supabase.com](https://supabase.com)
- Xcode 15+ (for iOS Archive)
- Android Studio / Gradle (for Android AAB)
- Apple Developer account and Google Play Console access

---

## 1. Get Upstash REST Credentials

1. Sign up or log in at [console.upstash.com](https://console.upstash.com).
2. Create a new Redis database (select the region closest to your Supabase project).
3. Copy the **REST URL** and **REST Token** from the database details page.
   - These will look like:
     - `UPSTASH_REDIS_REST_URL=https://your-redis-xxxx.upstash.io`
     - `UPSTASH_REDIS_REST_TOKEN=AXxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## 2. Set Supabase Secrets

Set all required environment variables as Supabase Edge Function secrets:

```bash
supabase secrets set SUPABASE_DB_URL="postgresql://postgres.[ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
supabase secrets set UPSTASH_REDIS_REST_URL="https://your-redis.upstash.io"
supabase secrets set UPSTASH_REDIS_REST_TOKEN="your-upstash-token"
supabase secrets set SPOTIFY_CLIENT_ID="your-spotify-client-id"
supabase secrets set SPOTIFY_CLIENT_SECRET="your-spotify-client-secret"
supabase secrets set AUTH_SALT_ROUNDS="12"
```

Notes:
- Use the **Session mode** pooler URL from Supabase (port 6543), not the direct connection.
- `AUTH_SALT_ROUNDS` controls bcrypt cost factor. 12 is recommended for production.
- Spotify credentials come from [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard).

Verify secrets are set:

```bash
supabase secrets list
```

---

## 3. Deploy Edge Function

Deploy the API edge function from the project root:

```bash
supabase functions deploy api --project-ref YOUR_PROJECT_REF
```

The function is located at `supabase/functions/api/` and exposes all routes
under the `/api/v1/` path prefix.

---

## 4. Test Health Endpoint

Verify the deployment is live and services are connected:

```bash
curl https://YOUR_PROJECT_REF.supabase.co/functions/v1/api/health
```

Expected response:

```json
{
  "status": "ok",
  "service": "soundscore-api",
  "checks": {
    "postgres": "up",
    "redis": "up"
  }
}
```

If either check returns `"down"`, verify the corresponding secret is set correctly.

---

## 5. Update iOS AppConfig.swift

Edit `ios/SoundScore/SoundScore/Config/AppConfig.swift` to point the release
build at your Supabase Edge Function URL:

```swift
enum AppConfig {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8080"
    #else
    static let apiBaseURL = "https://YOUR_PROJECT_REF.supabase.co/functions/v1/api"
    #endif
}
```

Replace `YOUR_PROJECT_REF` with your actual Supabase project reference.

---

## 6. Update Android build.gradle.kts API URL

Edit `app/build.gradle.kts` and update the release `API_BASE_URL`:

```kotlin
release {
    signingConfig = signingConfigs.getByName("release")
    buildConfigField("String", "API_BASE_URL",
        "\"https://YOUR_PROJECT_REF.supabase.co/functions/v1/api\"")
    isMinifyEnabled = false
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

Replace `YOUR_PROJECT_REF` with your actual Supabase project reference.

---

## 7. Build iOS Archive

1. Open `ios/SoundScore/SoundScore.xcodeproj` in Xcode.
2. Select the **SoundScore** scheme and **Any iOS Device** as the destination.
3. Set the version and build number in the target's General tab.
4. Go to **Product > Archive**.
5. Once archiving completes, the Organizer window opens.
6. Click **Distribute App** and follow the prompts for App Store Connect.

Alternatively, build from the command line:

```bash
cd ios/SoundScore
xcodebuild -scheme SoundScore \
  -configuration Release \
  -archivePath build/SoundScore.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath build/SoundScore.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

---

## 8. Build Android AAB

Ensure the signing environment variables are set:

```bash
export KEYSTORE_FILE=/path/to/soundscore-upload.keystore
export KEYSTORE_PASSWORD=your-keystore-password
export KEY_ALIAS=soundscore
export KEY_PASSWORD=your-key-password
```

Then build the release AAB:

```bash
cd /path/to/SoundScorev0.1
./gradlew :app:bundleRelease
```

The signed AAB will be at:

```
app/build/outputs/bundle/release/app-release.aab
```

---

## 9. Submit to Stores

### App Store (iOS)

1. Open [App Store Connect](https://appstoreconnect.apple.com).
2. Navigate to your app and create a new version.
3. Upload the archive from Xcode Organizer or Transporter.
4. Fill in release notes and submit for review.

### Google Play Store (Android)

1. Open [Google Play Console](https://play.google.com/console).
2. Navigate to your app > **Release** > **Production**.
3. Create a new release and upload the AAB file.
4. Fill in release notes and submit for review.

---

## Environment Variable Reference

| Variable                    | Required | Description                                |
|-----------------------------|----------|--------------------------------------------|
| `SUPABASE_DB_URL`           | Yes      | Postgres connection string (session pooler) |
| `UPSTASH_REDIS_REST_URL`    | Yes      | Upstash Redis REST endpoint                 |
| `UPSTASH_REDIS_REST_TOKEN`  | Yes      | Upstash Redis REST auth token               |
| `SPOTIFY_CLIENT_ID`         | Yes      | Spotify app client ID                       |
| `SPOTIFY_CLIENT_SECRET`     | Yes      | Spotify app client secret                   |
| `AUTH_SALT_ROUNDS`          | No       | bcrypt salt rounds (default: 10)            |

---

## Troubleshooting

| Symptom                           | Likely Cause                              | Fix                                        |
|-----------------------------------|-------------------------------------------|--------------------------------------------|
| Health returns postgres: "down"   | Bad `SUPABASE_DB_URL`                     | Verify URL, password, and port (6543)      |
| Health returns redis: "down"      | Bad Upstash credentials                   | Re-check REST URL and token                |
| 401 on all authenticated routes   | Missing or expired session token          | Re-authenticate via `/api/v1/auth/login`   |
| 429 Too Many Requests             | Rate limit exceeded                       | Wait and retry; check rate limit headers   |
| Spotify search returns empty      | Missing or invalid Spotify credentials    | Verify client ID and secret in secrets     |
| Android build unsigned            | Missing keystore env vars                 | Set KEYSTORE_FILE, KEYSTORE_PASSWORD, etc. |
