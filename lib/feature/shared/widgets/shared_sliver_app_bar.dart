import 'package:flutter/material.dart';
import 'app_app_bar.dart';

class SharedSliverAppBar extends StatelessWidget {
  const SharedSliverAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppSliverAppBar(title: Text(title), actions: actions);
  }
}
