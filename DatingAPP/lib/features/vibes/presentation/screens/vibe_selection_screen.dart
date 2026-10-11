import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_categories.dart';

class VibeSelectionScreen extends StatefulWidget {
  const VibeSelectionScreen({super.key, this.initialSelection = const {}});

  final Set<String> initialSelection;

  @override
  State<VibeSelectionScreen> createState() => _VibeSelectionScreenState();
}

class _VibeSelectionScreenState extends State<VibeSelectionScreen> {
  late String _mainVibeId;
  late final Set<String> _additionalVibeIds;

  @override
  void initState() {
    super.initState();
    final validIds = widget.initialSelection
        .where((id) => VibeCategories.byId(id) != null)
        .toList();
    _mainVibeId = validIds.firstOrNull ?? VibeCategories.all.first.id;
    _additionalVibeIds = validIds.skip(1).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final mainVibe = VibeCategories.byId(_mainVibeId)!;
    final additionalVibes = VibeCategories.all
        .where((vibe) => vibe.id != _mainVibeId)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Select your vibe',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                color: mainVibe.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(mainVibe.emoji, style: const TextStyle(fontSize: 58)),
                  const SizedBox(height: 10),
                  Text(
                    mainVibe.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    mainVibe.description,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Choose your main vibe',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VibeCategories.all.map((vibe) {
                final selected = vibe.id == _mainVibeId;
                return ChoiceChip(
                  label: Text('${vibe.emoji} ${vibe.title}'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _additionalVibeIds.remove(vibe.id);
                    _mainVibeId = vibe.id;
                  }),
                  selectedColor: AppColors.coralSoft,
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.caption.copyWith(
                    color: selected
                        ? AppColors.coralPressed
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.coral : AppColors.border,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Text(
              'Add more vibes',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a few more ways you like to spend time.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: additionalVibes.map((vibe) {
                final selected = _additionalVibeIds.contains(vibe.id);
                return FilterChip(
                  label: Text('${vibe.emoji} ${vibe.title}'),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _additionalVibeIds.add(vibe.id);
                    } else {
                      _additionalVibeIds.remove(vibe.id);
                    }
                  }),
                  selectedColor: AppColors.coralSoft,
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.caption.copyWith(
                    color: selected
                        ? AppColors.coralPressed
                        : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.coral : AppColors.border,
                  ),
                  checkmarkColor: AppColors.coralPressed,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton(
            onPressed: () => Navigator.pop(context, <String>{
              _mainVibeId,
              ..._additionalVibeIds,
            }),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Set my vibe'),
          ),
        ),
      ),
    );
  }
}
