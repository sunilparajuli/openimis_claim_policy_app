import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openimis_claim_policy_app/feature/shared/navigation/app_router.gr.dart';
import 'package:openimis_claim_policy_app/feature/shared/providers/user_session_provider.dart';
import 'package:openimis_claim_policy_app/feature/shared/utils/styles/app_color.dart';
import 'package:openimis_claim_policy_app/core/auth/biometric_auth_service.dart';

@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final results = await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1400)),
      ref.read(userSessionProvider.future),
    ]);
    if (!mounted) return;
    final session = results[1] as UserSession?;
    final ready = session?.isAuthenticated == true;
    if (ready) {
      final biometricEnabled = await ref.read(biometricEnabledProvider.future);
      if (!mounted) return;
      context.router.replaceAll([
        if (biometricEnabled)
          LoginRoute(title: 'Login')
        else
          const HomeWithTabsRoute(),
      ]);
    } else {
      context.router.replace(LoginRoute(title: 'Login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // openIMIS brand palette gradient sequence
          final top = _sequenceLerp(t, const [
            CustomColors.BrandPurple,
            Color(0xFF5A1E86),
            CustomColors.BrandPurple,
            Color(0xFF381056),
          ]);
          final bottom = _sequenceLerp((t + 0.33) % 1.0, const [
            Color(0xFF48176C),
            CustomColors.BrandGreen,
            Color(0xFF297F8D),
            CustomColors.BrandPurple,
          ]);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Animated gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [top, bottom],
                  ),
                ),
              ),
              // Floating icons with subtle motion
              _AnimatedIconBurst(controller: _controller),
              // Center logo mark
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/openimis-logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _sequenceLerp(double t, List<Color> colors) {
    final seg = 1 / colors.length;
    final i = (t ~/ seg).clamp(0, colors.length - 1);
    final j = (i + 1) % colors.length;
    final localT = (t - i * seg) / seg;
    return Color.lerp(
      colors[i],
      colors[j],
      localT,
    )!.withValues(alpha: 1.0); // ensure opaque
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AnimatedIconBurst extends StatelessWidget {
  const _AnimatedIconBurst({required this.controller});
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            _floatingIcon(
              alignment: Alignment(
                _lerp(-0.8, 0.8, (t + 0.10) % 1.0),
                _lerp(-0.9, -0.3, (t + 0.25) % 1.0),
              ),
              icon: Icons.bolt_rounded,
            ),
            _floatingIcon(
              alignment: Alignment(
                _lerp(-0.6, 0.7, (t + 0.45) % 1.0),
                _lerp(0.2, -0.6, (t + 0.70) % 1.0),
              ),
              icon: Icons.star_rounded,
            ),
            _floatingIcon(
              alignment: Alignment(
                _lerp(0.9, -0.8, (t + 0.75) % 1.0),
                _lerp(0.7, -0.1, (t + 0.15) % 1.0),
              ),
              icon: Icons.favorite_rounded,
            ),
          ],
        );
      },
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Widget _floatingIcon({required Alignment alignment, required IconData icon}) {
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: 0.5,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
