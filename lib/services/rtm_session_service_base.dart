import '../models/conversation.dart';

class RtmSessionListener {
  const RtmSessionListener({
    required this.onConnected,
    required this.onDisconnected,
    required this.onTranscriptUpdated,
    required this.onAgentStateChanged,
    required this.onTokenWillExpire,
    required this.onError,
  });

  final void Function(String connectionState) onConnected;
  final void Function(String connectionState) onDisconnected;
  final void Function(String agentUserId, List<TranscriptItem> transcript)
      onTranscriptUpdated;
  final void Function(String agentUserId, String agentState)
      onAgentStateChanged;
  final Future<void> Function() onTokenWillExpire;
  final void Function(String message) onError;
}

abstract class RtmSessionService {
  Future<void> initialize({
    required String appId,
    required String userId,
    required String token,
    required String channelName,
    required RtmSessionListener listener,
  });

  Future<void> renewToken(String token);

  Future<void> leave();

  Future<void> dispose();
}
