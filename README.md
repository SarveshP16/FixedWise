# FixedWise

A Fixed Deposit manager for Android and iOS: track every FD across your
family, see what's maturing soon on a visual ladder, and get reminded
before each one matures. Includes a standalone interest/maturity
calculator that works before you even open a deposit.

## Stack

Flutter, `flutter_riverpod` (plain providers, no codegen), `go_router`
with a `StatefulShellRoute` for the four bottom-nav tabs (Home / Deposits
/ Calculator / Profile), and Hive for local-first storage — no backend,
no accounts. An optional Google Drive backup sits on top of a local JSON
export/import safety net (Profile → Data).

## Design

Screens are built to match a supplied mockup exactly: a warm
paper/ink/brass/sage palette, Fraunces (serif) for headings and big
figures, IBM Plex Sans for everything else — see `lib/core/theme/`. No
raw color or text style should ever be hardcoded outside that folder.

## Known setup gaps

- **Google Drive backup**: needs a one-time Google Cloud OAuth client
  (Android SHA-1 fingerprint, iOS URL scheme + client id) that this repo
  doesn't have configured. The code (`lib/core/backup/
  google_drive_backup_service.dart`) is complete and ready — it throws a
  clear "not set up yet" error until that OAuth client exists.
- **iOS**: coded for throughout (permissions, notifications), but not
  locally buildable/runnable in this dev environment (no Mac). Needs a
  real macOS machine or CI runner before it can be verified.

## Development

```
flutter analyze
flutter test
flutter build apk --debug
```

Windows note: if this repo lives on a different drive letter than your
pub cache / Android SDK, Kotlin's incremental compiler can crash
mid-build (`android/gradle.properties` already sets
`kotlin.incremental=false` to work around it).
