import 'package:intl/intl.dart';

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class AppCurrencies {
  AppCurrencies._();

  static const String defaultCode = 'USD';

  static const List<CurrencyOption> all = [
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyOption(code: 'PKR', symbol: 'Rs ', name: 'Pakistani Rupee'),
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyOption(code: 'SAR', symbol: 'SAR ', name: 'Saudi Riyal'),
    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyOption(code: 'AED', symbol: 'AED ', name: 'UAE Dirham'),
    CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyOption(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  ];

  static CurrencyOption byCode(String code) {
    for (final option in all) {
      if (option.code == code) {
        return option;
      }
    }
    return all.first;
  }

  static NumberFormat formatter([String? code]) =>
      NumberFormat.currency(symbol: byCode(code ?? defaultCode).symbol);

  static String format(double amount, [String? code]) =>
      formatter(code).format(amount);
}
