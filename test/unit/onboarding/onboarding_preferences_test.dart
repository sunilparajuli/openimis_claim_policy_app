import 'package:flutter_test/flutter_test.dart';
import 'package:openimis_claim_policy_app/core/config/onboarding_config.dart';
import 'package:openimis_claim_policy_app/data/local/onboarding_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('onboarding is incomplete on a fresh installation', () async {
    expect(await OnboardingPreferences.isCompleted(), isFalse);
  });

  test('onboarding remains completed after it is dismissed', () async {
    await OnboardingPreferences.markCompleted();

    expect(await OnboardingPreferences.isCompleted(), isTrue);
  });

  test('onboarding content is supplied by the configuration list', () {
    expect(onboardingSlides, isNotEmpty);
    expect(
      onboardingSlides.every(
        (slide) =>
            slide.imageUrl.startsWith('https://') &&
            slide.title.isNotEmpty &&
            slide.description.isNotEmpty,
      ),
      isTrue,
    );
  });
}
