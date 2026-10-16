import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../data/safety_api.dart';

/// Asks to confirm, then blocks [name]. Returns true when the block was saved.
Future<bool> confirmAndBlock(
  BuildContext context, {
  required SafetyApi api,
  required String userId,
  required String name,
}) => _confirmThen(
  context,
  title: 'Block $name?',
  message:
      'You won’t see each other anywhere on Just2. Your match and chat with '
      '$name will be removed. They won’t be told.',
  action: 'Block',
  run: () => api.block(userId),
  done: '$name is blocked.',
);

/// Asks to confirm, then unmatches [name]. Returns true when it was saved.
Future<bool> confirmAndUnmatch(
  BuildContext context, {
  required SafetyApi api,
  required String userId,
  required String name,
}) => _confirmThen(
  context,
  title: 'Unmatch $name?',
  message:
      'Your match and chat will be removed for both of you, and you won’t be '
      'shown to each other again.',
  action: 'Unmatch',
  run: () => api.unmatch(userId),
  done: 'You unmatched $name.',
);

/// Lets the member pick a reason and add details, then reports [name].
/// Reporting also blocks them. Returns true when the report was sent.
Future<bool> showReportFlow(
  BuildContext context, {
  required SafetyApi api,
  required String userId,
  required String name,
  required String source,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _ReportSheet(api: api, userId: userId, name: name, source: source),
  );
  if (sent == true && context.mounted) {
    _notice(
      context,
      'Thanks for telling us. $name is blocked and our team will review your '
      'report.',
    );
  }
  return sent == true;
}

Future<bool> _confirmThen(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  required Future<void> Function() run,
  required String done,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: ValueKey('safety-confirm-$action'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(action),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await run();
  } catch (error) {
    if (context.mounted) {
      _notice(context, error.toString().replaceFirst('Exception: ', ''));
    }
    return false;
  }
  if (context.mounted) _notice(context, done);
  return true;
}

void _notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.api,
    required this.userId,
    required this.name,
    required this.source,
  });

  final SafetyApi api;
  final String userId;
  final String name;
  final String source;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.api.report(
        widget.userId,
        reason: reason,
        details: _details.text,
        source: widget.source,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Report ${widget.name}', style: AppTypography.h3),
          const SizedBox(height: 6),
          Text(
            'Your report is private. ${widget.name} won’t know you reported '
            'them, and they’ll be blocked for you.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (value) => setState(() => _reason = value),
            child: Column(
              children: [
                for (final reason in ReportReason.values)
                  RadioListTile<ReportReason>(
                    key: ValueKey('report-${reason.value}'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: reason,
                    title: Text(reason.label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('report-details'),
            controller: _details,
            maxLength: 1000,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Tell us more (optional)',
            ),
          ),
          if (_error != null) ...[
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            key: const ValueKey('report-send'),
            onPressed: _reason == null || _sending ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(_sending ? 'Sending…' : 'Send report'),
          ),
        ],
      ),
    ),
  );
}
