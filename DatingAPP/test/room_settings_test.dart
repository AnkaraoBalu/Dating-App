import 'package:dating_app/features/vibes/data/vibe_room_store.dart';
import 'package:dating_app/features/vibes/data/vibe_rooms_api.dart';
import 'package:dating_app/features/vibes/models/vibe_room.dart';
import 'package:dating_app/features/vibes/presentation/screens/room_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends VibeRoomsApi {
  _Api({this.fail = false})
    : super(baseUrl: 'http://test', getSessionToken: () async => 'token');
  final bool fail;
  final deleted = <String>[];

  final updates = <Map<String, Object?>>[];

  @override
  Future<VibeRoom> updateRoom(
    String roomId, {
    String? title,
    String? description,
    String? categoryId,
    String? emoji,
    int? maxParticipants,
    bool? inviteOnly,
    bool? isLive,
  }) async {
    if (fail) throw Exception('Only the host can edit this room.');
    updates.add({'title': title, 'inviteOnly': inviteOnly, 'isLive': isLive});
    return _room(mine: true)..title = title ?? 'Coffee chats';
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    if (fail) throw Exception('Only the host can delete this room.');
    deleted.add(roomId);
  }
}

VibeRoom _room({required bool mine}) => VibeRoom(
  id: 'room-${mine ? 'mine' : 'theirs'}',
  title: 'Coffee chats',
  description: 'Talk over coffee',
  categoryId: 'coffee_chats',
  emoji: '☕',
  coverAsset: 'assets/images/vibes/coffee_chats.jpg',
  hostName: 'Asha',
  hostAvatar: '',
  participantCount: 3,
  members: const [],
  messages: const [],
  isHostedByMe: mine,
);

Future<void> _open(WidgetTester tester, VibeRoom room, VibeRoomsApi api) async {
  VibeRoomStore.instance.cacheRoom(room);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RoomSettingsScreen(room: room, api: api),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _confirmDelete(WidgetTester tester) async {
  final delete = find.text('Delete room');
  await tester.scrollUntilVisible(
    delete,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(delete);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Delete'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('people who did not create the room cannot delete it', (
    tester,
  ) async {
    await _open(tester, _room(mine: false), _Api());
    expect(find.text('Delete room'), findsNothing);
  });

  testWidgets('the host deletes the room on the server', (tester) async {
    final api = _Api();
    final room = _room(mine: true);
    await _open(tester, room, api);
    await _confirmDelete(tester);
    expect(api.deleted, [room.id]);
    expect(VibeRoomStore.instance.byId(room.id), isNull);
    expect(find.text('Room settings'), findsNothing);
  });

  testWidgets('a failed delete keeps the room and says why', (tester) async {
    final room = _room(mine: true);
    await _open(tester, room, _Api(fail: true));
    await _confirmDelete(tester);
    expect(VibeRoomStore.instance.byId(room.id), isNotNull);
    expect(find.text('Room settings'), findsOneWidget);
    expect(find.textContaining('Could not delete this room'), findsOneWidget);
  });

  testWidgets('saving settings goes to the server', (tester) async {
    final api = _Api();
    await _open(tester, _room(mine: true), api);
    expect(find.text('Moderators'), findsNothing);
    expect(find.text('Blocked users'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Sunday coffee');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.updates.single['title'], 'Sunday coffee');
    expect(VibeRoomStore.instance.byId('room-mine')?.title, 'Sunday coffee');
    expect(find.text('Room settings'), findsNothing);
  });

  testWidgets('a failed save keeps the screen open and says why', (
    tester,
  ) async {
    await _open(tester, _room(mine: true), _Api(fail: true));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Room settings'), findsOneWidget);
    expect(find.textContaining('Could not save room settings'), findsOneWidget);
  });
}
