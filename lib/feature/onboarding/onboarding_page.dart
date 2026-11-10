import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openimis_claim_policy_app/core/config/onboarding_config.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/data/local/onboarding_preferences.dart';
import 'package:openimis_claim_policy_app/feature/shared/navigation/app_router.gr.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_button.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  bool get _isLastPage => _currentPage == onboardingSlides.length - 1;

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    await OnboardingPreferences.markCompleted();
    if (mounted) context.router.replaceAll([const SplashRoute()]);
  }

  Future<void> _next() async {
    if (_isLastPage) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onboardingSlides.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const Scaffold(body: SizedBox.shrink());
    }

    final slide = onboardingSlides[_currentPage];
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: slide.backgroundColor,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextButton(
                    onPressed: _isFinishing ? null : _finish,
                    child: Text(context.tr('Skip')),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: onboardingSlides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _OnboardingSlide(slide: onboardingSlides[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingSlides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          width: index == _currentPage ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? CustomColors.BrandPurple
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        variant: AppButtonVariant.primary,
                        onPressed: _isFinishing ? null : _next,
                        isLoading: _isFinishing,
                        icon: Icon(
                          _isLastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          context.tr(_isLastPage ? 'Get Started' : 'Next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.slide});

  final OnboardingSlideConfig slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    slide.imageUrl,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, _) => AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: child,
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Container(
                            color: Colors.white.withValues(alpha: 0.55),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.white.withValues(alpha: 0.7),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        size: 72,
                        color: CustomColors.BrandPurple,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr(slide.title),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(slide.description),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
