part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupNavigation on _ProfileSetupScreenState {
  Future<void> _next() async {
    if (_saving) return;
    if (_step == 8) {
      await _openBasics();
      return;
    }
    if ((_step == 1 || _step == 2) && _draft.photos.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 4 photos to continue.')),
      );
      return;
    }
    if (_step == 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile verification is coming soon.')),
      );
      return;
    }
    if (_step == 10) {
      await _finishProfileAndOpenHome();
      return;
    }
    if (_step == 6 && !await _savePrompts()) return;
    if (_step == 7 && !await _saveBio()) return;
    if (_step == 10) {
      await _finishProfile();
      return;
    }
    _refresh(() {
      _step++;
    });
  }

  Future<void> _finishProfileAndOpenHome() async {
    if (widget.api == null) return;
    _refresh(() {
      _saving = true;
      _saveError = null;
      _activityLabel = 'Finishing your profile…';
    });
    try {
      await widget.api!.complete();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(
            discoverApi: DiscoverApi(
              baseUrl: widget.api!.baseUrl,
              getSessionToken: widget.api!.getSessionToken,
            ),
            displayName: _displayName,
            location: _basicValues['location'],
            photos: _draft.photos.map((photo) => photo.url).toList(),
            bio: _bio.text.trim(),
            fieldOfStudy: _basicValues['fieldOfStudy'],
          ),
        ),
        (route) => false,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not finish your profile: $error')),
        );
      }
    } finally {
      if (mounted) _refresh(() => _saving = false);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      _refresh(() {
        if (_step == 4) _draft.selectedSection = null;
        _step--;
      });
    }
  }
}
