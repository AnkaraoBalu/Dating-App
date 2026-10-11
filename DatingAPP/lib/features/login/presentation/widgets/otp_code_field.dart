import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';

/// Six visual slots backed by one native input for paste, editing, and autofill.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: i == controller.text.length && enabled
                            ? AppColors.forest
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      i < controller.text.length ? controller.text[i] : '',
                      style: AppTypography.h3,
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Semantics(
          label: '6-digit verification code',
          child: TextFormField(
            key: const ValueKey('verification-code'),
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            showCursor: false,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              semanticCounterText: '6-digit verification code',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
