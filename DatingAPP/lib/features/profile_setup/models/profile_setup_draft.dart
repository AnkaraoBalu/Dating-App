class ProfileSetupPhoto {
  const ProfileSetupPhoto({required this.id, required this.url});
  final String id;
  final String url;

  factory ProfileSetupPhoto.fromJson(Map<String, dynamic> json) =>
      ProfileSetupPhoto(
        id: json['id'] as String,
        url: json['secureUrl'] as String,
      );
}

class ProfileSetupDraft {
  final photos = <ProfileSetupPhoto>[];
  final photoOrder = <int>[];
  final selectedPrompts = <String>{};
  final answers = <String, String>{};
  String filter = 'All';
  String? selectedSection;
  String? expandedSection;

  void movePhoto(int from, int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= photos.length ||
        to >= photos.length) {
      return;
    }
    final moved = photos.removeAt(from);
    photos.insert(to, moved);
  }

  void removePrompt(String prompt) {
    selectedPrompts.remove(prompt);
    answers.remove(prompt);
  }
}
