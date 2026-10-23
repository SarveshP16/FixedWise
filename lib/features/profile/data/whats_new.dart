import '../domain/whats_new_entry.dart';

/// Newest first. See [WhatsNewEntry]'s doc comment for how this differs
/// from `CHANGELOG.md`.
const whatsNewEntries = [
  WhatsNewEntry(
    version: '1.1.1',
    date: 'October 2026',
    highlights: [
      'App lock now hides everything behind it from screen readers too',
      "Setting a PIN no longer locks the app on the spot",
      'Tidier text fields, tenure input and early-closure dialog',
      'Switching between light and dark theme now updates every screen right away',
    ],
  ),
  WhatsNewEntry(
    version: '1.1.0',
    date: 'October 2026',
    highlights: [
      'New Tax & TDS view: interest per financial year, TDS estimate per bank, and a DICGC ₹5 lakh cover check',
      'Tenures in months and days (e.g. 444 days), with bank-accurate interest for odd and short tenures',
      'Half-yearly compounding, tax-saver (80C) FDs, nominee and senior-citizen details',
      'Automatic daily/weekly/monthly backups to any folder you choose — no Google sign-in needed',
      'Close early now accounts for the bank\'s premature-withdrawal penalty',
      'Amounts shown the Indian way: ₹12,34,567',
      'Fully offline and open source: no ads, no trackers, no internet permission',
    ],
  ),
  WhatsNewEntry(
    version: '1.0.0',
    date: 'September 2026',
    highlights: [
      'Track every Fixed Deposit across your family in one place',
      "See what's maturing soon on a visual maturity ladder",
      'Get reminded before each FD matures',
      'Built-in interest & maturity calculator — cumulative or payout',
      'Local backup, plus optional Google Drive backup with weekly/monthly auto-backup',
      'App lock (PIN or biometric) to keep your financial data private',
    ],
  ),
];
