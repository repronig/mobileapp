import 'package:intl/intl.dart';

/// Mirrors web `humanizeActivityLabel` / `humanizeActivitySubject` (Pass 6).
String humanizeActivityText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  var s = raw.replaceAll(RegExp(r'[._\-]+'), ' ');
  s = s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  if (s.isEmpty) return '—';
  return s[0].toUpperCase() + s.substring(1);
}

String formatActivityDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return DateFormat.yMMMd().add_jm().format(dt.toLocal());
  } on FormatException {
    return iso;
  }
}
