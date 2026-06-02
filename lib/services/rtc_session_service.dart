import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcSessionListener {
  const RtcSessionListener({
    required this.onJoined,
    required this.onRemoteUserJoined,
    required this.onRemoteUserLeft,
    required this.onTokenWillExpire,
    required this.onError,
  });

  final void Function(int localUid) onJoined;
  final void Function(int remoteUid) onRemoteUserJoined;
  final void Function(int remoteUid) onRemoteUserLeft;
  final Future<void> Function() onTokenWillExpire;
  final void Function(String message) onError;
}

abstract class RtcSessionService {
  Future<void> initialize({
    required String appId,
    required RtcSessionListener listener,
  });

  Future<void> join({
    required String token,
    required String channelId,
    required int uid,
  });

  Future<void> renewToken(String token);

  Future<void> muteLocalAudio(bool muted);

  Future<void> setSpeakerphone(bool enabled);

  Future<void> leave();

  Future<void> dispose();
}

class AgoraRtcSessionService implements RtcSessionService {
  RtcEngine? _engine;
  RtcSessionListener? _listener;

  RtcEngine get _requireEngine {
    final engine = _engine;
    if (engine == null) {
      throw StateError('RTC engine is not initialized');
    }
    return engine;
  }

  @override
  Future<void> initialize({
    required String appId,
    required RtcSessionListener listener,
  }) async {
    _listener = listener;
    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    await engine.enableAudio();

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _listener?.onJoined(connection.localUid ?? 0);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _listener?.onRemoteUserJoined(remoteUid);
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          _listener?.onRemoteUserLeft(remoteUid);
        },
        onTokenPrivilegeWillExpire: (
          RtcConnection connection,
          String token,
        ) async {
          await _listener?.onTokenWillExpire();
        },
        onError: (ErrorCodeType err, String msg) {
          _listener?.onError('$err $msg'.trim());
        },
      ),
    );

    _engine = engine;
  }

  @override
  Future<void> join({
    required String token,
    required String channelId,
    required int uid,
  }) async {
    await _requireEngine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );
  }

  @override
  Future<void> renewToken(String token) async {
    await _requireEngine.renewToken(token);
  }

  @override
  Future<void> muteLocalAudio(bool muted) async {
    await _requireEngine.muteLocalAudioStream(muted);
  }

  @override
  Future<void> setSpeakerphone(bool enabled) async {
    await _requireEngine.setEnableSpeakerphone(enabled);
  }

  @override
  Future<void> leave() async {
    final engine = _engine;
    if (engine == null) {
      return;
    }
    await engine.leaveChannel();
  }

  @override
  Future<void> dispose() async {
    final engine = _engine;
    _engine = null;
    if (engine == null) {
      return;
    }
    try {
      await engine.leaveChannel();
    } finally {
      engine.release();
    }
  }
}
