import 'package:flutter/foundation.dart';

import 'rtm_session_service_base.dart';
import 'rtm_session_service_native.dart' as native;
import 'rtm_session_service_stub.dart' as stub;

RtmSessionService createRtmSessionService() {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return stub.AgoraRtmSessionService();
  }

  return native.AgoraRtmSessionService();
}
