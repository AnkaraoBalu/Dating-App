part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupActions on _ProfileSetupScreenState {
  Future<void> _loadProfile() async {
    if (widget.api == null) {
      _refresh(() {
        _loading = false;
        _loadError = 'Profile services are not configured.';
      });
      return;
    }
    try {
      final data = await widget.api!.load();
      if (!mounted) return;
      final photoList = (data['photos'] as List<dynamic>? ?? []);
      _draft.photos
        ..clear()
        ..addAll(
          photoList.map(
            (photo) =>
                ProfileSetupPhoto.fromJson(photo as Map<String, dynamic>),
          ),
        );
      _draft.photoOrder.clear();
      _draft.photoOrder.addAll(
        List<int>.generate(_draft.photos.length, (i) => i),
      );
      _bio.text = data['bio'] as String? ?? '';
      _verificationStatus =
          data['verificationStatus'] as String? ?? 'not_started';
      final user = data['user'] as Map<String, dynamic>?;
      final name = (user?['username'] as String? ?? '').trim();
      if (name.isNotEmpty) _displayName = name;
      for (final key in [
        'location',
        'education',
        'fieldOfStudy',
        'jobTitle',
        'company',
        'heightCm',
        'zodiac',
      ]) {
        final value = data[key];
        if (value != null) _basicValues[key] = value.toString();
      }
      _basicValues['languages'] = (data['languages'] as List<dynamic>? ?? [])
          .join(', ');
      final promptList = (data['prompts'] as List<dynamic>? ?? []);
      for (final prompt in promptList) {
        final map = prompt as Map<String, dynamic>;
        _draft.selectedPrompts.add(map['question'] as String);
        _draft.answers[map['question'] as String] = map['answer'] as String;
      }
    } catch (error) {
      _loadError = error.toString();
    } finally {
      if (mounted) _refresh(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_saving || _draft.photos.length >= 6) return;
    final remaining = 6 - _draft.photos.length;
    final picked = await _picker.pickMultiImage(
      imageQuality: 82,
      maxWidth: 1800,
      limit: remaining,
    );
    if (picked.isEmpty || !mounted) return;
    var uploadedCount = 0;
    await _runSave(() async {
      _uploadTotal = picked.length;
      _uploadCurrent = 0;
      _uploadProgress = 0;
      for (final image in picked) {
        _uploadCurrent += 1;
        _uploadProgress = 0;
        if (mounted) _refresh(() {});
        final profile = await widget.api!.uploadPhotoWithProgress(
          File(image.path),
          onProgress: (progress) {
            _uploadProgress = (uploadedCount + progress) / picked.length;
            if (mounted) _refresh(() {});
          },
        );
        _replaceFromResponse(profile);
        uploadedCount++;
      }
    }, activityLabel: 'Uploading photos…');
    if (mounted) {
      _refresh(() {
        _uploadCurrent = 0;
        _uploadTotal = 0;
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _deletePhoto(String id) async => _runSave(() async {
    _replaceFromResponse(await widget.api!.deletePhoto(id));
  }, activityLabel: 'Deleting photo…');

  Future<void> _reorder(int from, int to) async {
    if (_saving || from == to) return;
    final previousOrder = List<ProfileSetupPhoto>.from(_draft.photos);
    _draft.movePhoto(from, to);
    _refresh(() {});
    await _runSave(() async {
      _replaceFromResponse(
        await widget.api!.reorderPhotos(
          _draft.photos.map((photo) => photo.id).toList(),
        ),
      );
    }, activityLabel: 'Reordering photos…');
    if (_saveError != null && mounted) {
      _draft.photos
        ..clear()
        ..addAll(previousOrder);
      _refresh(() {});
    }
  }

  void _replaceFromResponse(Map<String, dynamic> data) {
    final list = (data['photos'] as List<dynamic>? ?? []);
    _draft.photos
      ..clear()
      ..addAll(
        list.map(
          (item) => ProfileSetupPhoto.fromJson(item as Map<String, dynamic>),
        ),
      );
  }

  Future<void> _runSave(
    Future<void> Function() action, {
    String activityLabel = 'Saving…',
  }) async {
    if (widget.api == null) return;
    _refresh(() {
      _saving = true;
      _saveError = null;
      _activityLabel = activityLabel;
    });
    try {
      await action();
    } catch (error) {
      _saveError = error.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $error')),
        );
      }
    } finally {
      if (mounted) _refresh(() => _saving = false);
    }
  }

  Future<bool> _savePrompts() async {
    var succeeded = false;
    await _runSave(() async {
      final prompts = _draft.selectedPrompts
          .map(
            (question) => <String, String>{
              'question': question,
              'answer': (_draft.answers[question] ?? '').trim(),
            },
          )
          .toList();
      _replaceFromResponse(await widget.api!.savePrompts(prompts));
      succeeded = true;
    });
    return succeeded;
  }

  Future<bool> _saveBio() async {
    var succeeded = false;
    await _runSave(() async {
      final data = await widget.api!.update({'bio': _bio.text.trim()});
      _replaceFromResponse(data);
      succeeded = true;
    });
    return succeeded;
  }

  Future<void> _finishProfile() async => _runSave(() async {
    await widget.api!.complete();
    if (!mounted) return;
    Navigator.of(context).pop();
  });

  Future<void> _openBasics() async {
    final saved = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => ProfileBasicsScreen(
          api: widget.api!,
          initialValues: Map<String, String>.from(_basicValues),
        ),
      ),
    );
    if (saved == null || !mounted) return;
    _refresh(() {
      _basicValues
        ..clear()
        ..addAll(saved);
      _step = 9;
    });
  }
}
