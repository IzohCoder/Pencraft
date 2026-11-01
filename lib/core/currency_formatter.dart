import 'package:intl/intl.dart';

/// Currency formatting for Pencraft.
/// All amounts are stored as integer minor units.
abstract final class CurrencyFormatter {
  static final Map<String, _CurrencyMeta> _meta = {
    'KES': _CurrencyMeta(symbol: 'KES', decimalPlaces: 2, groupingSeparator: ','),
    'USD': _CurrencyMeta(symbol: '\$', decimalPlaces: 2, groupingSeparator: ','),
    'EUR': _CurrencyMeta(symbol: '€', decimalPlaces: 2, groupingSeparator: '.'),
    'GBP': _CurrencyMeta(symbol: '£', decimalPlaces: 2, groupingSeparator: ','),
    'UGX': _CurrencyMeta(symbol: 'UGX', decimalPlaces: 0, groupingSeparator: ','),
    'TZS': _CurrencyMeta(symbol: 'TZS', decimalPlaces: 0, groupingSeparator: ','),
    'RWF': _CurrencyMeta(symbol: 'RWF', decimalPlaces: 0, groupingSeparator: ','),
    'ETB': _CurrencyMeta(symbol: 'ETB', decimalPlaces: 2, groupingSeparator: ','),
    'NGN': _CurrencyMeta(symbol: '₦', decimalPlaces: 2, groupingSeparator: ','),
    'ZAR': _CurrencyMeta(symbol: 'R', decimalPlaces: 2, groupingSeparator: ','),
  };

  static _CurrencyMeta _forCode(String code) =>
      _meta[code] ?? _CurrencyMeta(symbol: code, decimalPlaces: 2, groupingSeparator: ',');

  /// Format minor units as a currency string.
  /// Example: format(150000, 'KES') → 'KES 1,500.00'
  static String format(int minorUnits, String currencyCode) {
    final m = _forCode(currencyCode);
    final divisor = _pow10(m.decimalPlaces);
    final value = minorUnits / divisor;

    final fmt = NumberFormat.currency(
      symbol: '${m.symbol} ',
      decimalDigits: m.decimalPlaces,
    );
    return fmt.format(value);
  }

  /// Format without currency symbol — for column alignment.
  static String formatAmount(int minorUnits, String currencyCode) {
    final m = _forCode(currencyCode);
    final divisor = _pow10(m.decimalPlaces);
    final value = minorUnits / divisor;

    final fmt = NumberFormat('#,##0${m.decimalPlaces > 0 ? '.${('0' * m.decimalPlaces)}' : ''}');
    return fmt.format(value);
  }

  static int decimalPlacesFor(String currencyCode) =>
      _forCode(currencyCode).decimalPlaces;

  /// Parse a display string back to minor units.
  static int parseToMinor(String input, String currencyCode) {
    final m = _forCode(currencyCode);
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(cleaned) ?? 0.0;
    return (value * _pow10(m.decimalPlaces) + 0.5).floor();
  }

  /// Format minor units as a plain number string (no symbol), for editing.
  /// Example: formatMinorToDisplay(150000, 'KES') → '1500.00'
  static String formatMinorToDisplay(int minorUnits, String currencyCode) {
    final m = _forCode(currencyCode);
    final divisor = _pow10(m.decimalPlaces);
    final value = minorUnits / divisor;
    if (m.decimalPlaces == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(m.decimalPlaces);
  }

  /// Number of minor units per display unit (e.g. KES=100, UGX=1).
  static int minorPerUnit(String currencyCode) =>
      _pow10(_forCode(currencyCode).decimalPlaces).toInt();

  static double _pow10(int n) {
    double result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}

class _CurrencyMeta {
  const _CurrencyMeta({
    required this.symbol,
    required this.decimalPlaces,
    required this.groupingSeparator,
  });

  final String symbol;
  final int decimalPlaces;
  final String groupingSeparator;
}

/// Common currency options for the currency picker.
const List<Map<String, String>> kCurrencies = [
  {'code': 'KES', 'name': 'Kenyan Shilling'},
  {'code': 'USD', 'name': 'US Dollar'},
  {'code': 'EUR', 'name': 'Euro'},
  {'code': 'GBP', 'name': 'British Pound'},
  {'code': 'UGX', 'name': 'Ugandan Shilling'},
  {'code': 'TZS', 'name': 'Tanzanian Shilling'},
  {'code': 'RWF', 'name': 'Rwandan Franc'},
  {'code': 'ETB', 'name': 'Ethiopian Birr'},
  {'code': 'NGN', 'name': 'Nigerian Naira'},
  {'code': 'ZAR', 'name': 'South African Rand'},
];
