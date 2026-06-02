import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:agent_quickstart_flutter/config/app_config.dart';
import 'package:agent_quickstart_flutter/models/conversation.dart';
import 'package:agent_quickstart_flutter/services/backend_api.dart';
import 'package:agent_quickstart_flutter/services/conversation_session_controller.dart';
import 'package:agent_quickstart_flutter/services/rtc_session_service.dart';

class FakeBackendApi extends BackendApi {
  FakeBackendApi()
      : super(
          client: http.Client(),
          baseUrl: 'http://localhost:3001',
        );

  int generateTokenCalls = 0;
  int inviteAgentCalls = 0;
  int stopConversationCalls = 0;
  String? stoppedAgentId;

  @override
  Future<AgoraTokenData> generateToken({String? uid, String? channel}) async {
    generateTokenCalls += 1;
    return AgoraTokenData(
      token: 'token-$generateTokenCalls',
      uid: uid ?? '123456',
      channel: channel ?? 'ai-conversation-test',
    );
  }

  @override
  Future<AgentResponse> inviteAgent(ClientStartRequest request) async {
    inviteAgentCalls += 1;
    return const AgentResponse(
      agentId: 'agent-123',
      createTs: 1234567890,
      state: 'RUNNING',
    );
  }

  @override
  Future<Map<String, Object?>> stopConversation(
    StopConversationRequest request,
  ) async {
    stopConversationCalls += 1;
    stoppedAgentId = request.agentId;
    return const {'success': true};
  }
}

class FakeRtcSessionService implements RtcSessionService {
  RtcSessionListener? listener;
  bool initialized = false;
  bool joined = false;
  bool left = false;
  bool disposed = false;
  bool muted = false;
  String? renewedToken;
  int? localUid;
  int? remoteUid;

  @override
  Future<void> initialize({
    required String appId,
    required RtcSessionListener listener,
  }) async {
    initialized = true;
    this.listener = listener;
  }

  @override
  Future<void> join({
    required String token,
    required String channelId,
    required int uid,
  }) async {
    joined = true;
    localUid = uid;
    listener?.onJoined(uid);
  }

  @override
  Future<void> leave() async {
    left = true;
  }

  @override
  Future<void> muteLocalAudio(bool muted) async {
    this.muted = muted;
  }

  @override
  Future<void> renewToken(String token) async {
    renewedToken = token;
  }

  @override
  Future<void> setSpeakerphone(bool enabled) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void emitRemoteJoin([int uid = 987654]) {
    remoteUid = uid;
    listener?.onRemoteUserJoined(uid);
  }

  void emitRemoteLeave([int uid = 987654]) {
    listener?.onRemoteUserLeft(uid);
  }
}

void main() {
  test('startConversation joins rtc and endConversation clears state', () async {
    final backendApi = FakeBackendApi();
    final rtcService = FakeRtcSessionService();
    final controller = ConversationSessionController(
      config: const AppConfig(
        agoraAppId: 'test-app-id',
        backendBaseUrl: 'http://localhost:3001',
        agentUid: 123456,
        agentGreeting: null,
      ),
      backendApi: backendApi,
      rtcSessionService: rtcService,
      requestMicrophonePermission: () async {},
    );

    await controller.startConversation();

    expect(controller.state.phase, ConversationPhase.connected);
    expect(controller.state.tokenData?.token, 'token-1');
    expect(controller.state.tokenData?.agentId, 'agent-123');
    expect(controller.state.agentResponse?.state, 'RUNNING');
    expect(backendApi.generateTokenCalls, 1);
    expect(backendApi.inviteAgentCalls, 1);
    expect(rtcService.initialized, isTrue);
    expect(rtcService.joined, isTrue);
    expect(rtcService.localUid, 123456);

    rtcService.emitRemoteJoin();
    expect(controller.state.remoteUid, 987654);
    expect(controller.state.transcript, isNotEmpty);

    await controller.endConversation();

    expect(controller.state.phase, ConversationPhase.idle);
    expect(controller.state.transcript, isEmpty);
    expect(backendApi.stopConversationCalls, 1);
    expect(backendApi.stoppedAgentId, 'agent-123');
    expect(rtcService.left, isTrue);
    expect(rtcService.disposed, isTrue);

    controller.dispose();
  });
}
