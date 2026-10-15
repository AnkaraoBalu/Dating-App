import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/adaptive_flow_column.dart';
import '../../data/profile_basics_options.dart';
import '../../data/profile_setup_api.dart';
import '../widgets/setup_image_hero.dart';

part '../widgets/profile_basics_selection_sections.dart';
part '../widgets/profile_basics_summary_sections.dart';
part '../widgets/profile_basics_shared_widgets.dart';

class ProfileBasicsScreen extends StatefulWidget {
  const ProfileBasicsScreen({
    super.key,
    required this.api,
    required this.initialValues,
  });

  final ProfileSetupApi api;
  final Map<String, String> initialValues;

  @override
  State<ProfileBasicsScreen> createState() => _ProfileBasicsScreenState();
}

class _ProfileBasicsScreenState extends State<ProfileBasicsScreen> {
  static const _titles = [
    'Add the basics',
    'Where are you located?',
    "What's your education?",
    'What did you study?',
    "What's your job title?",
    'Where do you work?',
    "What's your height?",
    "What's your zodiac sign?",
    'Which languages do you speak?',
    'Almost there!',
    'All set!',
  ];

  static const _subtitles = [
    'Help others know you better',
    'Your location helps us find people nearby.',
    'Your education gives an idea about your background.',
    'Select your field of study.',
    'This helps people know what you do.',
    'You can search or type your company.',
    'This helps show better matches.',
    'Some people like to match by zodiac.',
    'Select all that apply.',
    "Here's a quick summary. You can edit anytime.",
    'Your basic information is saved.',
  ];

  late final Map<String, String> _values;
  late final Set<String> _languages;
  late final TextEditingController _searchController;
  // The parent profile setup already has the basics introduction screen.
  // Start here at the first actual field to avoid showing that intro twice.
  int _step = 1;
  bool _saving = false;
  bool _usingFeet = false;
  bool _heightTouched = false;
  int _heightCm = 170;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _values = Map<String, String>.from(widget.initialValues);
    _languages = (_values['languages'] ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    _heightCm = int.tryParse(_values['heightCm'] ?? '') ?? 170;
    _heightTouched = _values.containsKey('heightCm');
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _change(VoidCallback action) => setState(action);

  void _choose(String key, String value) {
    _searchController.clear();
    setState(() {
      _values[key] = value;
      _search = '';
      if (key == 'education' &&
          value != "Bachelor's degree" &&
          value != "Master's degree" &&
          value != 'PhD') {
        _values.remove('fieldOfStudy');
      }
    });
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_step < 9) {
      setState(() => _step++);
      return;
    }
    if (_step == 9) {
      await _saveBasics();
      return;
    }
    if (mounted) Navigator.of(context).pop(Map<String, String>.from(_values));
  }

  Future<void> _saveBasics() async {
    setState(() => _saving = true);
    try {
      final payload =
          <String, Object?>{
            'location': _values['location'],
            'education': _values['education'],
            'fieldOfStudy': _values['fieldOfStudy']?.isNotEmpty == true
                ? _values['fieldOfStudy']
                : null,
            'jobTitle': _values['jobTitle'],
            'company': _values['company'],
            if (_heightTouched) 'heightCm': _heightCm,
            'zodiac': _values['zodiac'],
            'languages': _languages.toList(),
          }..removeWhere(
            (key, value) =>
                (value == null && key != 'fieldOfStudy') || value == '',
          );

      final response = await widget.api.update(payload);
      if (response['heightCm'] != null) {
        _values['heightCm'] = response['heightCm'].toString();
      }
      _values['languages'] =
          ((response['languages'] as List<dynamic>?) ?? _languages.toList())
              .join(', ');
      for (final key in [
        'location',
        'education',
        'fieldOfStudy',
        'jobTitle',
        'company',
        'zodiac',
      ]) {
        final value = response[key];
        if (value != null && value.toString().isNotEmpty) {
          _values[key] = value.toString();
        } else if (key == 'fieldOfStudy') {
          _values.remove(key);
        }
      }
      if (!mounted) return;
      setState(() => _step = 10);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your basics: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _edit(int step) => setState(() => _step = step);

  String _heightLabel() => _usingFeet
      ? "${(_heightCm / 30.48).floor()}′ ${((_heightCm / 2.54).round() % 12)}″  ·  $_heightCm cm"
      : '$_heightCm cm';

  String _valueOr(String key, String fallback) =>
      (_values[key] ?? '').trim().isEmpty ? fallback : _values[key]!.trim();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: AdaptiveFlowColumn(
        children: [
          _topBar(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  _titles[_step],
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  _subtitles[_step],
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: _section(),
              ),
            ),
          ),
          _footer(),
        ],
      ),
    ),
  );

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(10, 4, 18, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () {
            if (_step <= 1) {
              Navigator.of(context).pop();
            } else {
              setState(() => _step--);
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: _progress()),
        const SizedBox(width: 16),
        Text('${_step.clamp(1, 10)}/10', style: AppTypography.caption),
      ],
    ),
  );

  Widget _progress() => Row(
    children: List.generate(5, (i) {
      final fill = (_step / 10 * 5 - i).clamp(0.0, 1.0);
      return Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.borderStrong,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: fill,
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
    }),
  );

  Widget _section() => switch (_step) {
    0 => _introSection(),
    1 => _locationSection(),
    2 => _educationSection(),
    3 => _fieldSection(),
    4 => _jobSection(),
    5 => _companySection(),
    6 => _heightSection(),
    7 => _zodiacSection(),
    8 => _languagesSection(),
    9 => _summarySection(),
    _ => _completeSection(),
  };

  Widget _footer() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
    child: SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.match,
          borderRadius: BorderRadius.circular(28),
        ),
        child: TextButton(
          key: const ValueKey('profile-basics-next'),
          onPressed: _saving ? null : _next,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_saving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Flexible(
                  child: Text(
                    switch (_step) {
                      0 => "Let's go",
                      9 => 'Save & Continue',
                      10 => 'Continue to next step',
                      _ => 'Continue',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
