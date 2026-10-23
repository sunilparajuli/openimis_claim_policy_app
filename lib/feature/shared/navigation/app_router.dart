import 'package:auto_route/auto_route.dart';
import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(
      page: HomeWithTabsRoute.page,
      children: [AutoRoute(page: HomeRoute.page)],
    ),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: EditProfileRoute.page),
    AutoRoute(page: CommonWebviewRoute.page),
  ];
}
