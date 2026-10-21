import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../localization/locale_provider.dart';

const currencies = {
  'USD': 'US Dollar',
  'EUR': 'Euro',
  'BTN': 'Bhutanese Ngultrum',
  'INR': 'Indian Rupee',
  'NPR': 'Nepalese Rupee',
  'TZS': 'Tanzanian Shilling',
  'KES': 'Kenyan Shilling',
  'RWF': 'Rwandan Franc',
  'UGX': 'Ugandan Shilling',
  'XAF': 'Central African CFA Franc',
  'XOF': 'West African CFA Franc',
  'CHF': 'Swiss Franc',
  'GBP': 'British Pound',
};

final currencyStorageProvider = Provider((ref) => const FlutterSecureStorage());
final currencyProvider = AsyncNotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final code = await ref
        .read(currencyStorageProvider)
        .read(key: 'display_currency');
    return currencies.containsKey(code) ? code! : 'USD';
  }

  Future<void> select(String code) async {
    if (!currencies.containsKey(code)) throw ArgumentError.value(code);
    await ref
        .read(currencyStorageProvider)
        .write(key: 'display_currency', value: code);
    state = AsyncData(code);
  }
}

final moneyFormatterProvider = Provider<MoneyFormatter>(
  (ref) => MoneyFormatter(
    ref.watch(currencyProvider).value ?? 'USD',
    ref.watch(appLocaleProvider).languageCode,
  ),
);

class MoneyFormatter {
  MoneyFormatter(String code, String locale)
    : _format = NumberFormat.currency(locale: locale, name: code, symbol: code);
  final NumberFormat _format;
  String format(Object? value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    return number == null ? 'N/A' : _format.format(number);
  }
}
