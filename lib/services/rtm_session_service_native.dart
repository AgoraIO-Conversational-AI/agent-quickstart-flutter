import 'dart:async';
import 'dart:convert';

import 'package:agora_rtm/agora_rtm.dart';

import '../models/conversation.dart';
import '../utils/rtm_transcript_parser.dart';
import 'rtm_session_service_base.dart';

class AgoraRtmSessionService implements RtmSessionService {
  RtmClient? _client;
  RtmSessionListener? _listener;
  String? _channelName;
  String? _userId;
  final List<TranscriptItem> _transcript = <TranscriptItem>[];

  @override
  Future<void> initialize({
    required String appId,
    required String userId,
    required String token,
    required String channelName,
    required RtmSessionListener listener,
  }) async {
    _listener = listener;
    _channelName = channelName;
    _userId = userId;
    _transcript.clear();

    final (status, client) = await RTM(
      appId,
      userId,
      config: const RtmConfig(
        useStringUserId: true,
      ),
    );
    if (status.error) {
      throw StateError('RTM init failed: ${status.reason}');
    }

    client.addListener(
      linkState: _handleLinkState,
      message: _handleMessage,
      presence: _handlePresence,
      token: _handleToken,
    );

    _client = client;

    final (loginStatus, _) = await client.login(token);
    if (loginStatus.error) {
      throw StateError('RTM login failed: ${loginStatus.reason}');
    }

    final (subscribeStatus, result) = await client.subscribe(
      channelName,
      withMessage: true,
      withPresence: true,
    );
    if (subscribeStatus.error) {
      throw StateError('RTM subscribe failed: ${subscribeStatus.reason}');
    }

    final connectedState = result?.channelName.isNotEmpty == true
        ? 'connected'
        : 'connected';
    listener.onConnected(connectedState);
  }

  @override
  Future<void> renewToken(String token) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final (status, _) = await client.renewToken(token);
    if (status.error) {
      throw StateError('RTM token renewal failed: ${status.reason}');
    }
  }

  @override
  Future<void> leave() async {
    final client = _client;
    final channelName = _channelName;
    if (client == null || channelName == null) {
      return;
    }

    await client.unsubscribe(channelName);
  }

  @override
  Future<void> dispose() async {
    final client = _client;
    _client = null;
    _listener = null;
    _channelName = null;
    _userId = null;
    _transcript.clear();

    if (client == null) {
      return;
    }

    try {
      await client.logout();
    } finally {
      await client.release();
    }
  }

  void _handleLinkState(LinkStateEvent event) {
    final listener = _listener;
    if (listener == null) {
      return;
    }

    final state = event.currentState?.name.toUpperCase() ??
        event.previousState?.name.toUpperCase() ??
        'unknown';
    if (state == 'CONNECTED') {
      listener.onConnected(state);
      return;
    }

    if (state == 'DISCONNECTED' || state == 'FAILED') {
      listener.onDisconnected(state);
    }

  }

  void _handleMessage(MessageEvent event) {
    final listener = _listener;
    final channelName = _channelName;
    if (listener == null || channelName == null) {
      return;
    }

    if (event.channelName != null && event.channelName != channelName) {
      return;
    }

    final messageText = event.message == null
        ? ''
        : utf8.decode(event.message!, allowMalformed: true);
    final payload = _decodeJson(messageText);
    final agentUserId = event.publisher ?? _userId ?? 'agent';

    final transcript = parseTranscriptPayload(
      payload ?? messageText,
      fallbackUid: agentUserId,
    );
    if (transcript.isNotEmpty) {
      _mergeTranscript(transcript);
      listener.onTranscriptUpdated(agentUserId, List<TranscriptItem>.unmodifiable(_transcript));
      return;
    }

    final agentState = parseAgentStatePayload(payload ?? messageText);
    if (agentState != null) {
      listener.onAgentStateChanged(agentUserId, agentState);
    }
  }

  void _handlePresence(PresenceEvent event) {
    final listener = _listener;
    if (listener == null) {
      return;
    }

    if (event.type != RtmPresenceEventType.remoteStateChanged) {
      return;
    }

    final agentUserId = event.publisher ?? _userId ?? 'agent';
    final stateItems = event.stateItems ?? const <StateItem>[];
    final agentState = stateItems
        .firstWhere(
          (item) => (item.key ?? '').toLowerCase() == 'state',
          orElse: () => const StateItem(),
        )
        .value;
    if (agentState != null && agentState.isNotEmpty) {
      listener.onAgentStateChanged(agentUserId, agentState);
    }
  }

  void _handleToken(TokenEvent event) {
    final listener = _listener;
    if (listener == null) {
      return;
    }

    if (event.eventType == RtmTokenEventType.willExpire) {
      unawaited(listener.onTokenWillExpire());
    }
  }

  Map<String, Object?>? _decodeJson(String text) {
    if (text.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _mergeTranscript(List<TranscriptItem> transcript) {
    if (transcript.length > 1) {
      _transcript
        ..clear()
        ..addAll(transcript);
      return;
    }

    final item = transcript.first;
    final index = _transcript.indexWhere((entry) => entry.turnId == item.turnId);
    if (index == -1) {
      _transcript.add(item);
    } else {
      _transcript[index] = item;
    }
  }
}
