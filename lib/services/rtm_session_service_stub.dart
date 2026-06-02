import 'rtm_session_service_base.dart';

class AgoraRtmSessionService implements RtmSessionService {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize({
    required String appId,
    required String userId,
    required String token,
    required String channelName,
    required RtmSessionListener listener,
  }) async {
    listener.onConnected('unavailable');
  }

  @override
  Future<void> leave() async {}

  @override
  Future<void> renewToken(String token) async {}
}
