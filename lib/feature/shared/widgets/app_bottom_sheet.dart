import 'package:flutter/material.dart';

/// Full width on phones, with small side margins on tablets.
BoxConstraints appSheetConstraints(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return BoxConstraints.tightFor(width: width >= 600 ? width - 48 : width);
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  double? heightFactor,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  constraints: appSheetConstraints(context),
  clipBehavior: Clip.antiAlias,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        (media.size.height -
                media.viewInsets.bottom -
                media.padding.vertical -
                48)
            .clamp(0.0, media.size.height);
    final sheetHeight = heightFactor == null
        ? null
        : availableHeight * heightFactor.clamp(0.0, 1.0);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight * 0.9),
        child: SizedBox(height: sheetHeight, child: builder(context)),
      ),
    );
  },
);

/// Shared layout for confirmation sheets and entry forms.
class AppSheetContent extends StatelessWidget {
  const AppSheetContent({
    super.key,
    required this.title,
    this.content,
    this.icon,
    this.actions = const [],
    this.showCloseButton = true,
  });
  final Widget title;
  final Widget? content;
  final Widget? icon;
  final List<Widget> actions;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[Center(child: icon!), const SizedBox(height: 12)],
        Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!,
                child: title,
              ),
            ),
            if (showCloseButton)
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        if (content != null) ...[const SizedBox(height: 16), content!],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ],
    ),
  );
}
