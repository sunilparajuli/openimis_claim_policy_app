import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.flexibleSpace,
  });
  final Widget? title, leading, flexibleSpace;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor, foregroundColor;
  final double? elevation;
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    actions: actions,
    leading: leading,
    bottom: bottom,
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    elevation: elevation,
    flexibleSpace: flexibleSpace,
  );
}

class AppSliverAppBar extends StatelessWidget {
  const AppSliverAppBar({super.key, required this.title, this.actions});
  final Widget title;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) =>
      SliverAppBar(title: title, actions: actions, floating: true);
}
