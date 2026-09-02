# Android signing — the upload key

Google Play refuses any bundle signed with the Android debug certificate. The
release build is therefore signed with a dedicated **upload key**, created on
2026-09-02 and kept out of git (`.gitignore` covers `*.jks` and
`key.properties`).

## The files

| File | Purpose |
|---|---|
| `android/upload-keystore.jks` | The keystore holding the upload key. **Back this up.** |
| `android/key.properties` | The passwords + alias the Gradle build reads. Never commit. |

`android/app/build.gradle.kts` loads `key.properties` when it exists and signs
the `release` build type with it; without the file it falls back to the debug
key — installable for testing, rejected by Play.

## Credentials

```
Keystore : android/upload-keystore.jks
Alias    : upload
Password : see android/key.properties (never committed) — the same value
           is the store password and the key password
Algorithm: RSA 2048, valid 10000 days (until 2054-01-18)
Owner    : CN=Gioco del 101, OU=Gioco del 101, O=Gioco del 101,
           L=Napoli, ST=Campania, C=IT
```

**The password is deliberately absent from this file**, because this file is
committed. It is written out in full in the copy shipped to the owner
(`delivery/GiocoDel101_Final/documentation/ANDROID_SIGNING.md`) together with
the keystore itself.

Certificate fingerprints of the upload key:

```
SHA-1  : 12:D5:86:ED:20:E1:35:B0:33:03:F4:E1:85:DC:68:8E:89:7F:DA:8B
SHA-256: 80:02:7D:21:82:03:24:37:9B:A0:9C:54:87:E5:07:FE:C4:60:CD:B0:8D:CC:3B:05:C1:F4:8C:0A:C2:74:61:52
```

## Why this matters more than any other file

With **Play App Signing** (mandatory for new apps) Google holds the real app
signing key and re-signs every release; this upload key only proves an upload
came from the owner. Even so:

- **Keep the keystore and its password.** Losing both means asking Google Play
  support to reset the upload key — recoverable, but slow.
- **Never commit it or send it in the clear.** Anyone holding it can upload
  builds to the app's Play listing.
- The **same key must sign every future update**, until Play support resets it.

## Rebuilding a signed bundle

```bash
flutter build appbundle --release --dart-define-from-file=env/supabase.dev.json
# -> build/app/outputs/bundle/release/app-release.aab
```

Add the owner legal details once they are known — they render as "not yet
designated" while empty (see `lib/core/legal/legal_config.dart`):

```bash
flutter build appbundle --release \
  --dart-define-from-file=env/supabase.dev.json \
  --dart-define=LEGAL_ENTITY_NAME="..." \
  --dart-define=LEGAL_SUPPORT_EMAIL="..." \
  --dart-define=LEGAL_COUNTRY="Italia" \
  --dart-define=PRIVACY_POLICY_URL="https://..." \
  --dart-define=TERMS_URL="https://..."
```

## Verifying a bundle is correctly signed

```bash
unzip -p app-release.aab META-INF/UPLOAD.RSA | keytool -printcert
```

The owner line must read `CN=Gioco del 101`, **not** `CN=Android Debug`.

## Version numbers

`pubspec.yaml` holds `version: 1.0.0+1` → versionName `1.0.0`, versionCode `1`.
Play rejects a re-upload of an existing versionCode: bump the `+N` for every new
upload (1.0.0+2, 1.0.1+3, …).
