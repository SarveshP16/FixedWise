# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/), versions follow [SemVer](https://semver.org/).

## [Unreleased]

### Added
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
  lead-time changes — needed the same Android manifest additions
  (explicit scheduled/boot `<receiver>` entries, exact-alarm permission)
  that Pulse's Tasks reminders needed, or scheduled alarms silently never
  fire.
- **Local backup**: export/import everything (holders, deposits,
  settings) to one JSON file via `file_picker` — the safeguard against
  no-cloud-sync local storage.
- **Google Drive backup** (optional, layered on top of local
  export/import): stores one JSON snapshot in the signed-in account's
  Drive `appDataFolder` via direct Drive v3 REST calls. Code-complete but
  blocked on a manual, one-time Google Cloud OAuth client setup this dev
  environment can't do — see README.

### Known gaps
- No app icon yet (`flutter_launcher_icons` wired, waiting on source art).
- iOS is coded for but unverified — no Mac in this dev environment.
- Real bank "certificate" generation (PDF) not built — text-summary
  share is the MVP stand-in.
- No automated visual regression check against the mockup yet (planned:
  a headless-browser screenshot pass against a dev-only Flutter web
  build).
