/// A one-to-one voice call, as the API describes it to one of its members.
class VoiceCall {
  const VoiceCall({
    required this.id,
    required this.conversationId,
    required this.status,
    required this.isCaller,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
    this.serverUrl,
    this.participantToken,
  });

  factory VoiceCall.fromJson(Map<String, dynamic> json) {
    final peer = json['peer'];
    if (json['id'] is! String || peer is! Map<String, dynamic>) {
      throw const FormatException('Invalid call response.');
    }
    return VoiceCall(
      id: json['id'] as String,
      conversationId: json['conversationId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ended',
      isCaller: json['isCaller'] == true,
      peerId: peer['id']?.toString() ?? '',
      peerName: peer['name']?.toString() ?? 'Your match',
      peerAvatar: peer['avatar']?.toString() ?? '',
      serverUrl: json['serverUrl']?.toString(),
      participantToken: json['participantToken']?.toString(),
    );
  }

  final String id;
  final String conversationId;

  /// ringing, accepted, ended, declined, missed or cancelled.
  final String status;
  final bool isCaller;
  final String peerId;
  final String peerName;
  final String peerAvatar;

  /// LiveKit join details, present when starting or answering a call.
  final String? serverUrl;
  final String? participantToken;

  bool get isRinging => status == 'ringing';
  bool get isFinished => !isRinging && status != 'accepted';
}

/// A live status change for a call, from the realtime connection.
class VoiceCallUpdate {
  const VoiceCallUpdate(this.callId, this.status);

  final String callId;
  final String status;
}
