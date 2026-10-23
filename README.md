# FixedWise

A private, offline Fixed Deposit manager built for India. Track every FD
across your family, see what's maturing soon on a visual ladder, get
reminded before each one matures, and see how much interest each holder
earns per financial year — with TDS and DICGC-cover checks.

No ads, no trackers, no account, and no internet permission.

## Features

- **Deposits**: cumulative or non-cumulative, monthly/quarterly/half-yearly/
  annual compounding or payout, tenures in months + days (e.g. 444 days),
  nominee, auto-renew, tax-saver (Section 80C, 5-year lock-in).
- **Bank-accurate interest** (`lib/core/calculations/maturity_calculator.dart`):
  whole compounding periods plus simple interest on the broken period;
  simple interest for tenures under 6 months; maturity dates that clamp to
  month-end (31 Jan + 1 month = 28 Feb). Early closure applies the bank's
  premature-withdrawal penalty.
- **Tax & TDS** (`lib/core/calculations/india_tax.dart`): interest per
  April–March financial year by holder and bank, Section 194A TDS estimate
  (₹50,000 / ₹1,00,000 for senior citizens from FY 2025-26), and a warning
  when a holder has more than the ₹5 lakh DICGC cover at one bank.
- **Reminders** before maturity, a dashboard maturity ladder, renewals.
- **App lock**: PIN (salted PBKDF2, escalating lockout) with optional
  biometric unlock; screenshots blocked while a PIN is set.
- **Backups**: automatic daily/weekly/monthly JSON backups to any folder
  you pick (keeps the last 5), manual export/import, and Android's own
  Auto Backup to your Google account if device backup is on.

## Install

- **F-Droid**: submission in progress — see [`fdroid/`](fdroid/).
- **Build it yourself**: see below.

## Stack

Flutter, `flutter_riverpod` (plain providers, no codegen), `go_router`
with a `StatefulShellRoute` for the four bottom-nav tabs, and Hive for
local storage. No backend. All dependencies are open source; fonts
(Fraunces, IBM Plex Sans) are bundled under the SIL Open Font License.

## Development

```
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Release builds are signed with `android/key.properties` + the keystore it
points to (both gitignored). Without them, release builds fall back to the
debug key.

Windows note: if this repo lives on a different drive letter than your
pub cache / Android SDK, Kotlin's incremental compiler can crash
mid-build (`android/gradle.properties` already sets
`kotlin.incremental=false` to work around it).

iOS code paths exist (notifications, app lock) but are untested — there
is no macOS build machine for this project yet. Folder backups are
Android-only.

## Disclaimer

Figures are estimates to help you plan; always confirm with your bank.
Tax figures are not tax advice.

## License

[GPL-3.0](LICENSE). Bundled fonts: SIL Open Font License 1.1
(`assets/fonts/*-OFL.txt`).
