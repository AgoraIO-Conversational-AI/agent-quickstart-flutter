// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

import '../models/conversation.dart';
import '../utils/rtm_transcript_parser.dart';
import 'rtm_session_service_base.dart';

class AgoraRtmSessionService implements RtmSessionService {
  js.JsObject? _client;
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

    final bridge = js.context['flutterAgoraRtm'];
    if (bridge is! js.JsObject) {
      throw StateError(
        'Agora RTM web bridge is not loaded. Add web/rtm_bridge.js to web/index.html.',
      );
    }

    final client = bridge.callMethod(
      'createClient',
      <Object?>[
        appId,
        userId,
        js.JsObject.jsify(<String, Object?>{'logLevel': 'error'}),
      ],
    );
    if (client is! js.JsObject) {
      throw StateError('Failed to create Agora RTM web client.');
    }

    _client = client;

    client.callMethod('addMessageListener', [_handleMessage]);
    client.callMethod('addPresenceListener', [_handlePresence]);
    client.callMethod('addStatusListener', [_handleStatus]);

    await _invokeAsync(
      'login',
      [token],
    );

    await _invokeAsync(
      'subscribe',
      [
        channelName,
        true,
        true,
      ],
    );

    listener.onConnected('connected');
  }

  @override
  Future<void> renewToken(String token) async {
    if (_client == null) {
      return;
    }

    await _invokeAsync('renewToken', [token]);
  }

  @override
  Future<void> leave() async {
    if (_client == null || _channelName == null) {
      return;
    }

    await _invokeAsync('unsubscribe', [_channelName!]);
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

    await _invokeAsyncWithClient(client, 'logout', const []);
    await _invokeAsyncWithClient(client, 'release', const []);
  }

  Future<void> _invokeAsync(String method, List<Object?> args) {
    final client = _client;
    if (client == null) {
      return Future<void>.value();
    }

    return _invokeAsyncWithClient(client, method, args);
  }

  Future<void> _invokeAsyncWithClient(
    js.JsObject client,
    String method,
    List<Object?> args,
  ) {
    final completer = Completer<void>();
    client.callMethod(
      method,
      <Object?>[
        ...args,
        () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        (Object? error) {
          if (!completer.isCompleted) {
            completer.completeError(
              StateError(error?.toString() ?? 'Agora RTM web bridge failed'),
            );
          }
        },
      ],
    );
    return completer.future;
  }

  void _handleStatus(Object? event) {
    final listener = _listener;
    if (listener == null) {
      return;
    }

    final state = _readString(event, 'state').toUpperCase();
    if (state == 'CONNECTED') {
      listener.onConnected(state);
      return;
    }

    if (state == 'DISCONNECTED' || state == 'RECONNECTING' || state == 'FAILED') {
      listener.onDisconnected(state);
    }
  }

  void _handleMessage(Object? event) {
    final listener = _listener;
    final channelName = _channelName;
    if (listener == null || channelName == null) {
      return;
    }

    final eventChannel = _readString(event, 'channelName');
    if (eventChannel.isNotEmpty && eventChannel != channelName) {
      return;
    }

    final publisher = _readString(event, 'publisher');
    final message = _readEventMessage(event);
    final payload = _decodeJson(message);
    final agentUserId = publisher.isEmpty ? (_userId ?? 'agent') : publisher;

    final transcript = parseTranscriptPayload(
      payload ?? message,
      fallbackUid: agentUserId,
    );
    if (transcript.isNotEmpty) {
      _mergeTranscript(transcript);
      listener.onTranscriptUpdated(
        agentUserId,
        List<TranscriptItem>.unmodifiable(_transcript),
      );
      return;
    }

    final agentState = parseAgentStatePayload(payload ?? message);
    if (agentState != null) {
      listener.onAgentStateChanged(agentUserId, agentState);
    }
  }

  void _handlePresence(Object? event) {
    final listener = _listener;
    if (listener == null) {
      return;
    }

    final eventType = _readString(event, 'eventType').toUpperCase();
    if (eventType != 'STATE_CHANGED' &&
        eventType != 'JOIN' &&
        eventType != 'SNAPSHOT' &&
        eventType != 'INTERVAL') {
      return;
    }

    final publisher = _readString(event, 'publisher');
    final stateChanged = _readJsObject(event, 'stateChanged');
    final state = _readString(stateChanged, 'state');
    if (state.isNotEmpty) {
      listener.onAgentStateChanged(
        publisher.isEmpty ? (_userId ?? 'agent') : publisher,
        state,
      );
    }

    final stateItems = _readDynamic(event, 'stateItems');
    if (stateItems is List) {
      for (final item in stateItems) {
        final key = _readString(item, 'key').toLowerCase();
        final value = _readString(item, 'value');
        if (key == 'state' && value.isNotEmpty) {
          listener.onAgentStateChanged(
            publisher.isEmpty ? (_userId ?? 'agent') : publisher,
            value,
          );
          return;
        }
      }
    }
  }

  String _readEventMessage(Object? event) {
    final message = _readDynamic(event, 'message');
    if (message == null) {
      return '';
    }
    if (message is String) {
      return message;
    }
    return message.toString();
  }

  String _readString(Object? event, String key) {
    final value = _readDynamic(event, key);
    return value?.toString() ?? '';
  }

  Object? _readDynamic(Object? event, String key) {
    if (event is js.JsObject) {
      try {
        return event[key];
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  js.JsObject? _readJsObject(Object? event, String key) {
    final value = _readDynamic(event, key);
    if (value is js.JsObject) {
      return value;
    }
    return null;
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
