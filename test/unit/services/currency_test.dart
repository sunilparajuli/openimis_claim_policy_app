import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod_template/core/config/currency_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Currency is restored after recreating the provider container',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = ProviderContainer();
      expect(await first.read(currencyProvider.future), 'USD');
      await first.read(currencyProvider.notifier).select('BTN');
      first.dispose();
      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(await second.read(currencyProvider.future), 'BTN');
    },
  );
  test(
    'Currency formatting preserves values and handles unavailable amounts',
    () {
      final formatter = MoneyFormatter('BTN', 'en');
      expect(formatter.format(1250.5), contains('BTN'));
      expect(formatter.format(1250.5), contains('1,250.50'));
      expect(formatter.format(null), 'N/A');
      expect(MoneyFormatter('RWF', 'en').format(1250), contains('1,250'));
    },
  );
}
