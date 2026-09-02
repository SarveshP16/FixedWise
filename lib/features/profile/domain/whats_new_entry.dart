/// One release's worth of user-facing highlights for About's "What's new"
/// screen — deliberately separate from `CHANGELOG.md`, which is written
/// for a developer audience (implementation detail, gotchas hit, why a
/// fix works) rather than something to show an end user. Add a new entry
/// here (newest first in `whatsNewEntries`) whenever a user-visible
/// feature ships, in plain language.
class WhatsNewEntry {
  const WhatsNewEntry({required this.version, required this.date, required this.highlights});

  final String version;

  /// Human-readable, e.g. "September 2026" — not parsed, just displayed.
  final String date;

  final List<String> highlights;
}
