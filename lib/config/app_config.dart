import '../constants/agora.dart';

class AppConfig {
  const AppConfig({
    required this.agoraAppId,
    required this.agentUid,
    required this.agentGreeting,
  });

  static const agoraAppIdKey = 'AGORA_APP_ID';
  static const agoraAppCertificateKey = 'AGORA_APP_CERTIFICATE';
  static const agentUidKey = 'AGENT_UID';
  static const agentGreetingKey = 'AGENT_GREETING';

  final String? agoraAppId;
  final int agentUid;
  final String? agentGreeting;

  factory AppConfig.fromEnvironment() {
    final agentUidRaw = const String.fromEnvironment(agentUidKey);
    return AppConfig(
      agoraAppId: const String.fromEnvironment(agoraAppIdKey),
      agentUid: int.tryParse(agentUidRaw) ?? defaultAgentUid,
      agentGreeting: const String.fromEnvironment(agentGreetingKey),
    );
  }

  bool get hasAgoraAppId => (agoraAppId ?? '').isNotEmpty;
  bool get hasGreeting => (agentGreeting ?? '').isNotEmpty;
}

