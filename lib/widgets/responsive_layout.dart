import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder compact;
  final WidgetBuilder medium;
  final WidgetBuilder large;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    required this.medium,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return compact(context);
        } else if (constraints.maxWidth < 840) {
          return medium(context);
        } else {
          return large(context);
        }
      },
    );
  }
}
