import 'package:intl/intl.dart';

/// Document numbering logic for Pencraft.
abstract final class DocumentNumbering {
  /// Generate the next document number.
  /// prefix: e.g. 'INV' or 'EST'
  /// year: e.g. 2026
  /// sequence: next sequential number (1-based)
  /// zeroPad: total digits for the sequence (default 3 → 001)
  static String generate({
    required String prefix,
    required int year,
    required int sequence,
    int zeroPad = 3,
  }) {
    final seq = sequence.toString().padLeft(zeroPad, '0');
    return '$prefix-$year-$seq';
  }

  /// Parse a number to extract sequence for auto-increment.
  /// Returns null if it doesn't match the expected format.
  static int? parseSequence(String number) {
    final parts = number.split('-');
    if (parts.length < 2) return null;
    return int.tryParse(parts.last);
  }

  /// Generate a due date epoch from issue date + payment terms (days).
  static int? dueDateFromTerms({
    required int issueDateEpoch,
    required int? termsDays,
  }) {
    if (termsDays == null) return null;
    final issued = DateTime.fromMillisecondsSinceEpoch(issueDateEpoch * 1000);
    return issued.add(Duration(days: termsDays)).millisecondsSinceEpoch ~/ 1000;
  }

  /// Human-readable due date label.
  static String dueDateLabel(int? dueDateEpoch) {
    if (dueDateEpoch == null) return 'On receipt';
    final due = DateTime.fromMillisecondsSinceEpoch(dueDateEpoch * 1000);
    final now = DateTime.now();
    final diff = due.difference(now).inDays;

    if (diff < 0) return 'Overdue by ${(-diff)} days';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${DateFormat('d MMM yyyy').format(due)}';
  }

  /// Common payment terms options (in days).
  static const List<Map<String, dynamic>> kTermsOptions = [
    {'label': 'On receipt', 'days': null},
    {'label': 'Net 7', 'days': 7},
    {'label': 'Net 14', 'days': 14},
    {'label': 'Net 30', 'days': 30},
    {'label': 'Net 60', 'days': 60},
    {'label': 'Net 90', 'days': 90},
  ];
}
