import 'rtm_session_service_base.dart';
import 'rtm_session_service_web.dart';

RtmSessionService createRtmSessionService() {
  return AgoraRtmSessionService();
}
