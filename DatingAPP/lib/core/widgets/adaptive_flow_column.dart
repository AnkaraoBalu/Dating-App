import 'package:flutter/material.dart';

/// Keeps full-height flows readable on tablets and scrollable when vertical
/// space is reduced by landscape orientation, the keyboard, or larger text.
class AdaptiveFlowColumn extends StatelessWidget {
  const AdaptiveFlowColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxHeight < 640 ||
          MediaQuery.textScalerOf(context).scale(16) > 20;
      final bodyHeight = (constraints.maxHeight * .65).clamp(300.0, 600.0);
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: constraints.maxWidth.clamp(0.0, 640.0),
          // Keep the same ancestors when keyboard insets change. Swapping a
          // Column for a scroll view disposes focused text fields.
          child: SingleChildScrollView(
            child: SizedBox(
              height: compact
                  ? constraints.maxHeight + bodyHeight
                  : constraints.maxHeight,
              child: Column(children: children),
            ),
          ),
        ),
      );
    },
  );
}
