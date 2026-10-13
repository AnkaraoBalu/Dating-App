import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import 'vibe_room_profile_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';

class VibeRoomPeopleScreen extends StatefulWidget {
  const VibeRoomPeopleScreen({super.key, required this.room});

  final VibeRoom room;

  @override
  State<VibeRoomPeopleScreen> createState() => _VibeRoomPeopleScreenState();
}

class _VibeRoomPeopleScreenState extends State<VibeRoomPeopleScreen> {
  static const _tabs = ['All', 'Speakers', 'Listeners'];
  static const _extraMembers = <VibeRoomMember>[
    VibeRoomMember(
      id: 'aarav',
      name: 'Aarav',
      age: 24,
      avatar: 'assets/images/boys-images/cafe_hoodie_portrait.png',
      role: 'Speaker',
      tags: ['Music', 'Movies'],
    ),
    VibeRoomMember(
      id: 'kiara',
      name: 'Kiara',
      age: 23,
      avatar: 'assets/images/girls-images/mirror_selfie_portrait.png',
      role: 'Listener',
      tags: ['Travel', 'Coffee'],
    ),
    VibeRoomMember(
      id: 'ishaan',
      name: 'Ishaan',
      age: 26,
      avatar: 'assets/images/boys-images/daylight_sunglasses_portrait.png',
      role: 'Listener',
      tags: ['Books', 'Food'],
    ),
    VibeRoomMember(
      id: 'tara',
      name: 'Tara',
      age: 23,
      avatar: 'assets/images/girls-images/sunset_car_sunglasses.png',
      role: 'Listener',
      tags: ['Art', 'Travel'],
    ),
  ];

  final _searchController = TextEditingController();
  String _tab = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: VibeRoomStore.instance,
    builder: (context, _) {
      final query = _searchController.text.trim().toLowerCase();
      final allMembers = <VibeRoomMember>{
        ...widget.room.members,
        ..._extraMembers,
      }.toList();
      final members = allMembers.where((member) {
        final matchesTab =
            _tab == 'All' ||
            (_tab == 'Speakers' && member.role != 'Listener') ||
            (_tab == 'Listeners' && member.role == 'Listener');
        return matchesTab &&
            '${member.name} ${member.tags.join(' ')}'.toLowerCase().contains(
              query,
            );
      }).toList();

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'People in this room',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    for (final tab in _tabs)
                      ButtonSegment<String>(
                        value: tab,
                        label: Text('$tab (${_count(tab, allMembers.length)})'),
                      ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selection) =>
                      setState(() => _tab = selection.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search people…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: members.isEmpty
                    ? const VibeRoomEmptyState(
                        title: 'No one found',
                        message: 'Try another name or choose a different tab.',
                      )
                    : ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 76),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final followed = VibeRoomStore
                              .instance
                              .followingMemberIds
                              .contains(member.id);
                          return VibeRoomMemberTile(
                            member: member,
                            onTap: () => _openProfile(member),
                            trailing: member.id == 'you'
                                ? const Text('You')
                                : followed
                                ? OutlinedButton(
                                    onPressed: () => VibeRoomStore.instance
                                        .toggleFollow(member.id),
                                    child: const Text('Following'),
                                  )
                                : FilledButton(
                                    onPressed: () => VibeRoomStore.instance
                                        .toggleFollow(member.id),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.coral,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Follow'),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );

  int _count(String tab, int total) {
    if (tab == 'All') return widget.room.participantCount;
    if (tab == 'Speakers') {
      return widget.room.members
              .where((member) => member.role != 'Listener')
              .length +
          2;
    }
    return total - 4;
  }

  void _openProfile(VibeRoomMember member) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => VibeRoomProfileScreen(member: member),
    ),
  );
}
