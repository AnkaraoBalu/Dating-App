import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/adaptive_flow_column.dart';
import '../../data/profile_setup_copy.dart';
import '../../data/profile_setup_options.dart';
import '../../models/profile_setup_draft.dart';
import '../../data/profile_setup_api.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/data/discover_api.dart';
import 'profile_basics_screen.dart';

part '../widgets/profile_setup_photo_sections.dart';
part '../widgets/profile_setup_prompt_sections.dart';
part '../widgets/profile_setup_details_sections.dart';
part '../widgets/profile_setup_shared_widgets.dart';
part '../widgets/profile_setup_preview_sections.dart';

part '../controllers/profile_setup_actions.dart';
part '../controllers/profile_setup_navigation.dart';
part '../widgets/profile_setup_layout.dart';

part '../widgets/profile_setup_preview_hero.dart';

part '../widgets/profile_setup_prompt_answers.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.genderIdentity, this.api});

  final String? genderIdentity;
  final ProfileSetupApi? api;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 0;
  final _draft = ProfileSetupDraft();
  final _bio = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = true;
  bool _saving = false;
  int _uploadCurrent = 0;
  int _uploadTotal = 0;
  double _uploadProgress = 0;
  String? _saveError;
  String _activityLabel = 'Saving…';
  String? _loadError;
  final Map<String, String> _basicValues = {};
  String _displayName = 'Your profile';
  String _verificationStatus = 'not_started';
  int _previewPhotoIndex = 0;
  late final PageController _previewPageController;

  List<String> get _photoPlaceholders => switch (widget.genderIdentity) {
    'woman' => ProfileSetupOptions.womenPhotos,
    'man' => ProfileSetupOptions.menPhotos,
    _ => [
      ProfileSetupOptions.womenPhotos[0],
      ProfileSetupOptions.menPhotos[1],
      ProfileSetupOptions.womenPhotos[2],
      ProfileSetupOptions.menPhotos[3],
      ProfileSetupOptions.womenPhotos[4],
      ProfileSetupOptions.menPhotos[5],
    ],
  };

  void _refresh(VoidCallback mutation) => setState(mutation);

  @override
  void initState() {
    super.initState();
    _previewPageController = PageController();
    _loadProfile();
  }

  @override
  void dispose() {
    _bio.dispose();
    _previewPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildLayout(context);
}
