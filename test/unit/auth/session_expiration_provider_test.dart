import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/core/auth/session_expiration_provider.dart';

void main() {
  test('coalesces unauthorized responses until acknowledged', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(sessionExpirationProvider), isFalse);

    final notifier = container.read(sessionExpirationProvider.notifier);
    notifier.notifyUnauthorized();
    notifier.notifyUnauthorized();

    expect(container.read(sessionExpirationProvider), isTrue);

    notifier.acknowledge();
    expect(container.read(sessionExpirationProvider), isFalse);
  });
}
