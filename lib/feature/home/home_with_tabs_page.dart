import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_template/feature/shared/navigation/app_router.gr.dart';

@RoutePage()
class HomeWithTabsPage extends StatelessWidget {
  const HomeWithTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(routes: [HomeRoute(title: 'Home')]);
  }
}
