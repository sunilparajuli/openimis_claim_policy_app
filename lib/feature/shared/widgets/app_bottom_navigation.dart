import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';

class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isAction = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isAction;
}

/// Application navigation built on the curved labeled navigation component.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return CurvedNavigationBar(
      index: currentIndex,
      height: 72,
      color: colors.surface,
      buttonBackgroundColor: colors.primary,
      backgroundColor: theme.scaffoldBackgroundColor,
      animationCurve: Curves.easeOutCubic,
      animationDuration: const Duration(milliseconds: 360),
      iconPadding: 12,
      letIndexChange: (index) {
        if (!items[index].isAction) return true;
        onTap(index);
        return false;
      },
      onTap: onTap,
      items: List.generate(items.length, (index) {
        final item = items[index];
        final selected = index == currentIndex;
        return CurvedNavigationBarItem(
          child: Semantics(
            selected: selected,
            button: true,
            label: item.label,
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              size: 25,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
          label: item.label,
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: selected ? colors.primary : colors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }),
    );
  }
}
