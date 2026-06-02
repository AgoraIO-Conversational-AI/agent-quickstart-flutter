import '../constants/agora.dart';
import '../constants/backend.dart';

class AppConfig {
  const AppConfig({
    required this.backendBaseUrl,
    required this.agentUid,
    required this.agentGreeting,
  });

  static const backendBaseUrlKey = 'BACKEND_BASE_URL';
  static const agentUidKey = 'NEXT_PUBLIC_AGENT_UID';
  static const agentGreetingKey = 'NEXT_AGENT_GREETING';

  final String backendBaseUrl;
  final int agentUid;
  final String? agentGreeting;

  factory AppConfig.fromEnvironment() {
    final agentUidRaw = const String.fromEnvironment(agentUidKey);
    final backendUrl = const String.fromEnvironment(backendBaseUrlKey);
    return AppConfig(
      backendBaseUrl:
          backendUrl.isEmpty ? defaultBackendBaseUrl() : backendUrl,
      agentUid: int.tryParse(agentUidRaw) ?? defaultAgentUid,
      agentGreeting: const String.fromEnvironment(agentGreetingKey),
    );
  }

  bool get hasBackendBaseUrl => backendBaseUrl.isNotEmpty;
  bool get hasGreeting => (agentGreeting ?? '').isNotEmpty;
}
