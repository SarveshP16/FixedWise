# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/), versions follow [SemVer](https://semver.org/).

## [Unreleased]

### Added
- **Real app icon** (a coin mark with the ₹ symbol and a brass growth-
  ladder line, on the app's ink-navy background) — replaces the default
  Flutter icon. Sourced from a full export package (adaptive foreground/
  background for Android 8+, a pre-rounded legacy fallback for older
  Android, and the full iOS AppIcon set), regenerated via
  `flutter_launcher_icons` from `assets/icon/`. Two adjustments from the
  package's defaults were needed: `adaptive_icon_foreground_inset: 0`
  (the supplied foreground was already inset to the safe zone; the
  tool's own default 16% inset would have shrunk it twice), and a
  separate `image_path_android` pointing at the pre-rounded legacy asset
  (the flat, unrounded iOS master would have looked wrong as Android's
  pre-8.0 fallback icon, which needs the rounding baked in).
- **A visible "Reminders need one more permission" prompt in Profile**
  when exact alarms aren't granted — since we now only auto-request that
  permission once ever (see Fixed, below), declining or missing it left
  reminders permanently and silently broken with no way back in but
  hunting through OS Settings by hand. Tapping it (or "Send test
  notification" while it's missing) re-opens the grant screen on demand;
  status re-checks automatically when the app resumes
  (`MaturityReminderService.canScheduleExactAlarms`/
  `requestExactAlarmPermissionNow`).
- **"Send test notification" in Profile** — schedules a one-off reminder
  10 seconds out through the exact same `zonedSchedule` + exact-alarm
  path a real FD maturity reminder uses, so you can verify reminders
  actually work on your device without waiting months for a real one to
  mature (`MaturityReminderService.sendTestReminder`).
- **Initial MVP build.** Flutter app scaffolded (`com.fixedwise.app`,
  Android + iOS), themed to match the supplied "Ladder" mockup exactly —
  Fraunces + IBM Plex Sans, warm paper/ink/brass/sage palette, all tokens
  in `lib/core/theme/` (light-only for now, dark mode deferred).
- **Data layer**: `Holder` and `FixedDeposit` domain models (Hive, plain
  `Map`s, no codegen), with multi-holder tracking from day one — every FD
  is tagged to a holder ("Self" auto-seeded on first launch, renamable
  but not deletable), Deposits list gets a holder filter (hidden for a
  single-holder user).
- **`MaturityCalculator`**: cumulative (compound) vs. payout (simple,
  disbursed) interest formulas, progress-toward-maturity, a growth curve
  sampler, pro-rata early-closure value, and an honest "overall growth
  since opening" figure — pinned against the mockup's own calculator
  script via a regression test.
- **Dashboard**: hero header (greeting, total value, growth pill),
  maturity-ladder bar chart, quick actions (New / Calculator /
  Statements), "Maturing soon" list.
- **Deposits**: list (summary strip, holder filter, progress bars) and
  detail (value at maturity, a hand-drawn growth-curve `CustomPainter`,
  info table, Close early / Download-certificate actions — certificate
  is a shared text summary via `share_plus` for now, real PDF deferred).
- **New Deposit + Calculator**: one shared form (Bank autocomplete,
  rate, principal, tenure slider, Compounding + Payout-type segments)
  reused by both a standalone Calculator tab (no persistence) and the
  New Deposit screen (adds Holder, Auto-renew, FD number, and a live
  `calc-out` preview that actually reacts to the Compounding selection —
  fixing a bug in the mockup's own demo script, which hardcoded
  quarterly regardless of the visible selection).
- **Holders** management screen (add/rename/delete, delete guarded while
  any FD still references that holder).
- **Profile**: display name, currency symbol (defaults from device
  locale, editable), maturity-reminder lead time, local export/import,
  Google Drive backup, About.
- **Maturity reminders**: `flutter_local_notifications` + `timezone`,
  scheduled/rescheduled/cancelled on create, edit, close-early, and
  lead-time changes.
- **Local backup**: export/import everything (holders, deposits,
  settings) to one JSON file via `file_picker` — the safeguard against
  no-cloud-sync local storage.
- **Google Drive backup** (optional, layered on top of local
  export/import): stores one JSON snapshot in the signed-in account's
  Drive `appDataFolder` via direct Drive v3 REST calls. Code-complete but
  blocked on a manual, one-time Google Cloud OAuth client setup this dev
  environment can't do — see README.

### Fixed
- **The "Alarms & reminders" toggle in OS Settings was permanently
  disabled — not just off.** `SCHEDULE_EXACT_ALARM` was never actually
  declared in `AndroidManifest.xml` (`flutter_local_notifications`'s own
  manifest only auto-declares `VIBRATE`/`POST_NOTIFICATIONS`, contrary to
  what an earlier changelog entry here implied), so Android had nothing
  to grant — every scheduled reminder threw `PlatformException(
  exact_alarms_not_permitted)` regardless of what the user tapped. Fixed
  by declaring `SCHEDULE_EXACT_ALARM`/`RECEIVE_BOOT_COMPLETED` and the
  two `ScheduledNotificationReceiver`/`ScheduledNotificationBootReceiver`
  `<receiver>` entries explicitly. Verified end-to-end on a real device.
- **Alarms & reminders permission no longer hijacks every app launch.**
  `MaturityReminderService.init()` was calling
  `requestExactAlarmsPermission()` unconditionally on every cold start —
  Android's exact-alarm grant is a full-screen Settings deep-link, not an
  in-app dialog, so the app effectively opened a system Settings page
  instead of the dashboard every single time until the user granted it.
  Now asked at most once ever per install (tracked via
  `SettingsRepository.getNotificationPermissionsRequested`); a user who
  declines can still enable it later from OS Settings and reminders will
  just start working once they do.
- **Profile's name/currency fields actually save now.** They used a
  `TextFormField` with `initialValue` (only read once at first build) and
  saved only on `onFieldSubmitted` (keyboard "done") — tapping away
  without pressing that key silently dropped the edit. `ProfileScreen` is
  now a `ConsumerStatefulWidget` owning real `TextEditingController`s,
  saving on every keystroke like every other setting on the screen.
- **Default currency is now ₹ (Indian Rupee)**, not a device-locale
  guess — FDs are predominantly an Indian banking product, and the old
  `NumberFormat.simpleCurrency(locale: ...)` detection was unreliable
  across devices/emulators regardless of actual region anyway. Still
  fully user-editable in Profile.
- **Fonts were rendering far too small on a real device.** The mockup's
  CSS px values are calibrated for its own ~296px-wide *miniature* demo
  phone frame, not a real device's ~390-430dp logical width — mapping
  them 1:1 into Flutter's logical pixels under-sized every piece of text
  app-wide. `AppTypography` now scales every mockup size up by 1.3x
  before use (`lib/core/theme/app_typography.dart`).
- **Dashboard's status bar icons were invisible**, merging into the dark
  hero header at the top of the screen. `DashboardScreen` now nests its
  own light-icon `AnnotatedRegion<SystemUiOverlayStyle>` inside the
  app-wide dark-icon default (`app.dart`), matching every other screen's
  light "paper" top.
- New Deposit's Bank field example changed from "Anchor Bank" (a
  placeholder name invented for the mockup) to "Axis Bank", a real bank.
- **New Deposit was silently unable to record an FD opened in the past**
  — `openedDate` was hardcoded to "now" with no field to change it, so
  onboarding an existing FD (the overwhelmingly common case — you're
  rarely adding one the same day it's opened) always got today's date.
  Added an "Opened date" field (`showDatePicker`, up to 20 years back,
  never in the future).
- **Dashboard's "Statements" quick action was routing to Profile** — a
  confusing dead end for anyone tapping it expecting to see their FDs.
  Now opens the Deposits list, which is what a "statement" actually is.

### Known gaps
- iOS is coded for but unverified — no Mac in this dev environment.
- Real bank "certificate" generation (PDF) not built — text-summary
  share is the MVP stand-in.
- No automated visual regression check against the mockup yet (planned:
  a headless-browser screenshot pass against a dev-only Flutter web
  build).
