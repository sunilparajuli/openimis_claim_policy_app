import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Feature screens use shared inputs, actions, app bars and popup routes',
    () {
      final directWidget = RegExp(
        r'\b(TextField|TextFormField|DropdownButtonFormField|ElevatedButton|FilledButton|OutlinedButton|TextButton|AppBar|SliverAppBar|showDialog|showModalBottomSheet)(?:<[^>]+>)?(?:\.icon)?\s*\(',
      );
      final violations = <String>[];
      for (final file in Directory(
        'lib/feature',
      ).listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll('\\', '/');
        if (!path.endsWith('.dart') ||
            path.contains('/shared/widgets/') ||
            path.endsWith('.g.dart') ||
            path.endsWith('.freezed.dart')) {
          continue;
        }
        if (directWidget.hasMatch(file.readAsStringSync())) {
          violations.add(path);
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'Use app_widgets.dart components; see its README.',
      );
    },
  );
}
