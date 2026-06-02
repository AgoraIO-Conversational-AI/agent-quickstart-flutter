import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_config.dart';
import '../models/conversation.dart';
import '../utils/conversation.dart';
import 'backend_api.dart';
import 'rtc_session_service.dart';
import 'rtm_session_service.dart';

class ConversationSessionController extends ChangeNotifier {
  ConversationSessionController({
    required this._config,
    required this._backendApi,
    required this._rtcSessionService,
    required this._rtmSessionService,
    Future<void> Function()? requestMicrophonePermission,
  })  : _requestMicrophonePermissionOverride = requestMicrophonePermission,
        _state = const ConversationSessionState.initial();

  final AppConfig _config;
  final BackendApi _backendApi;
  final RtcSessionService _rtcSessionService;
  final RtmSessionService _rtmSessionService;
  final Future<void> Function()? _requestMicrophonePermissionOverride;
  final Random _random = Random();

  ConversationSessionState _state;
  bool _isStarting = false;
  bool _isEnding = false;
  bool _isRenewingToken = false;

  ConversationSessionState get state => _state;
  bool get isStarting => _isStarting;
  bool get isEnding => _isEnding;
  bool get hasSession => _state.phase != ConversationPhase.idle;

  Future<void> startConversation() async {
    if (_isStarting || hasSession) {
      return;
    }

    if (!_config.hasAgoraAppId) {
      _setState(
        _state.copyWith(
          phase: ConversationPhase.error,
          errorMessage:
              'Missing NEXT_PUBLIC_AGORA_APP_ID. Put it in the repo-root .env.local and use bash tool/run_flutter.sh chrome.',
        ),
      );
      return;
    }

    _isStarting = true;
    _setState(
      _state.copyWith(
        phase: ConversationPhase.preparing,
        errorMessage: null,
        transcript: const <TranscriptItem>[],
      ),
    );

    try {
      await (_requestMicrophonePermissionOverride ?? _requestMicrophonePermission)();

      final tokenData = await _backendApi.generateToken();
      final agentResponse = await _backendApi.inviteAgent(
        ClientStartRequest(
          requesterId: tokenData.uid,
          channelName: tokenData.channel,
        ),
      );

      final joinedUid = _parseUid(tokenData.uid);
      final sessionState = _state.copyWith(
        phase: ConversationPhase.connecting,
        tokenData: tokenData.copyWith(agentId: agentResponse.agentId),
        agentResponse: agentResponse,
        localUid: joinedUid,
        connectionStatus: 'connecting',
        transcript: _appendTranscript(
          _state.transcript,
          'Connecting to ${tokenData.channel}...',
        ),
      );
      _setState(sessionState);

      await _rtmSessionService.initialize(
        appId: _config.agoraAppId,
        userId: tokenData.uid,
        token: tokenData.token,
        channelName: tokenData.channel,
        listener: RtmSessionListener(
          onConnected: _handleRtmConnected,
          onDisconnected: _handleRtmDisconnected,
          onTranscriptUpdated: _handleRtmTranscriptUpdated,
          onAgentStateChanged: _handleRtmAgentStateChanged,
          onTokenWillExpire: _handleTokenWillExpire,
          onError: _handleRtmError,
        ),
      );

      await _rtcSessionService.initialize(
        appId: _config.agoraAppId,
        listener: RtcSessionListener(
          onJoined: _handleJoined,
          onRemoteUserJoined: _handleRemoteUserJoined,
          onRemoteUserLeft: _handleRemoteUserLeft,
          onTokenWillExpire: _handleTokenWillExpire,
          onError: _handleRtcError,
        ),
      );

      _setState(
        _state.copyWith(
          connectionStatus: 'joining',
          transcript: _appendTranscript(
            _state.transcript,
            'RTC join requested for ${tokenData.channel}.',
          ),
        ),
      );

      await _rtcSessionService.join(
        token: tokenData.token,
        channelId: tokenData.channel,
        uid: joinedUid,
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          phase: ConversationPhase.error,
          errorMessage: error.toString(),
          transcript: _appendTranscript(
            _state.transcript,
            'Start failed: $error',
          ),
        ),
      );
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> endConversation() async {
    if (_isEnding || !hasSession) {
      return;
    }

    _isEnding = true;
    _setState(
      _state.copyWith(
        phase: ConversationPhase.ending,
        connectionStatus: 'ending',
        errorMessage: null,
        transcript: _appendTranscript(_state.transcript, 'Ending conversation...'),
      ),
    );

    try {
      final agentId = _state.tokenData?.agentId;
      if (agentId != null && agentId.isNotEmpty) {
        await _backendApi.stopConversation(
          StopConversationRequest(agentId: agentId),
        );
      }
      await _rtmSessionService.leave();
      await _rtcSessionService.leave();
      await _rtmSessionService.dispose();
      await _rtcSessionService.dispose();
      _setState(const ConversationSessionState.initial());
    } catch (error) {
      _setState(
        _state.copyWith(
          phase: ConversationPhase.error,
          errorMessage: error.toString(),
          transcript: _appendTranscript(
            _state.transcript,
            'End failed: $error',
          ),
        ),
      );
    } finally {
      _isEnding = false;
      notifyListeners();
    }
  }

  Future<void> toggleMute() async {
    if (!hasSession) {
      return;
    }

    final nextMuted = !_state.isMicMuted;
    try {
      await _rtcSessionService.muteLocalAudio(nextMuted);
      _setState(
        _state.copyWith(
          isMicMuted: nextMuted,
          transcript: _appendTranscript(
            _state.transcript,
            nextMuted ? 'Microphone muted.' : 'Microphone unmuted.',
          ),
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          errorMessage: error.toString(),
          phase: ConversationPhase.error,
        ),
      );
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    if (!hasSession) {
      return;
    }

    await _rtcSessionService.setSpeakerphone(enabled);
  }

  Future<void> _requestMicrophonePermission() async {
    if (kIsWeb) {
      return;
    }

    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return;
    }

    throw StateError('Microphone permission is required to start a conversation.');
  }

  Future<void> _handleTokenWillExpire() async {
    if (_isRenewingToken) {
      return;
    }

    _isRenewingToken = true;
    final tokenData = _state.tokenData;
    if (tokenData == null) {
      _isRenewingToken = false;
      return;
    }

    try {
      final renewedToken = await _backendApi.generateToken(
        uid: tokenData.uid,
        channel: tokenData.channel,
      );
      await _rtmSessionService.renewToken(renewedToken.token);
      await _rtcSessionService.renewToken(renewedToken.token);
      _setState(
        _state.copyWith(
          tokenData: renewedToken.copyWith(agentId: tokenData.agentId),
          transcript: _appendTranscript(
            _state.transcript,
            'RTC token renewed.',
          ),
        ),
      );
    } catch (error) {
      _handleRtcError('Token renewal failed: $error');
    } finally {
      _isRenewingToken = false;
    }
  }

  void _handleJoined(int localUid) {
    _setState(
      _state.copyWith(
        phase: ConversationPhase.connected,
        localUid: localUid,
        connectionStatus: 'connected',
        transcript: _appendTranscript(
          _state.transcript,
          'Joined channel as $localUid.',
        ),
      ),
    );
  }

  void _handleRemoteUserJoined(int remoteUid) {
    _setState(
      _state.copyWith(
        remoteUid: remoteUid,
        transcript: _appendTranscript(
          _state.transcript,
          'Agent audio joined as $remoteUid.',
        ),
      ),
    );
  }

  void _handleRemoteUserLeft(int remoteUid) {
    final currentRemote = _state.remoteUid;
    _setState(
      _state.copyWith(
        remoteUid: currentRemote == remoteUid ? null : currentRemote,
        transcript: _appendTranscript(
          _state.transcript,
          'Agent audio left.',
        ),
      ),
    );
  }

  void _handleRtcError(String message) {
    _setState(
      _state.copyWith(
        phase: ConversationPhase.error,
        errorMessage: message,
        transcript: _appendTranscript(
          _state.transcript,
          'RTC error: $message',
        ),
      ),
    );
  }

  void _handleRtmConnected(String connectionState) {
    _setState(
      _state.copyWith(
        connectionStatus: 'rtm $connectionState',
        transcript: _appendTranscript(
          _state.transcript,
          'RTM connected.',
        ),
      ),
    );
  }

  void _handleRtmDisconnected(String connectionState) {
    _setState(
      _state.copyWith(
        connectionStatus: 'rtm $connectionState',
        transcript: _appendTranscript(
          _state.transcript,
          'RTM disconnected.',
        ),
      ),
    );
  }

  void _handleRtmTranscriptUpdated(
    String agentUserId,
    List<TranscriptItem> transcript,
  ) {
    _setState(
      _state.copyWith(
        agentState: _state.agentState,
        transcript: normalizeTranscript(transcript, _state.tokenData?.uid ?? agentUserId),
        connectionStatus: 'transcript updated',
      ),
    );
  }

  void _handleRtmAgentStateChanged(
    String agentUserId,
    String agentState,
  ) {
    _setState(
      _state.copyWith(
        agentState: agentState,
        transcript: _appendTranscript(
          _state.transcript,
          'Agent state: ${normalizeTranscriptSpacing(agentState)}',
        ),
      ),
    );
  }

  void _handleRtmError(String message) {
    _setState(
      _state.copyWith(
        errorMessage: message,
        phase: ConversationPhase.error,
        transcript: _appendTranscript(
          _state.transcript,
          'RTM error: $message',
        ),
      ),
    );
  }

  List<TranscriptItem> _appendTranscript(
    List<TranscriptItem> transcript,
    String text,
  ) {
    final nextTranscript = List<TranscriptItem>.from(transcript);
    nextTranscript.add(
      TranscriptItem(
        turnId: 'turn-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(9999)}',
        uid: 'system',
        text: normalizeTranscriptSpacing(text),
        status: TranscriptTurnStatus.completed,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return nextTranscript;
  }

  int _parseUid(String uid) {
    final parsed = int.tryParse(uid);
    if (parsed == null || parsed <= 0) {
      throw StateError('Invalid Agora uid returned by backend: $uid');
    }
    return parsed;
  }

  void _setState(ConversationSessionState nextState) {
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_rtmSessionService.dispose());
    unawaited(_rtcSessionService.dispose());
    super.dispose();
  }
}
