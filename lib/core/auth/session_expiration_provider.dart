import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionExpirationProvider =
    NotifierProvider<SessionExpirationNotifier, bool>(
      SessionExpirationNotifier.new,
    );

class SessionExpirationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Coalesces concurrent unauthorized responses into one UI event.
  void notifyUnauthorized() {
    if (!state) state = true;
  }

  void acknowledge() => state = false;
}
