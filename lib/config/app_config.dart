import '../constants/backend.dart';
import '../constants/agora.dart';
import '../services/backend_api.dart';

class AppConfig {
  const AppConfig({
    required this.agoraAppId,
    required this.backendBaseUrl,
    required this.agentUid,
    required this.agentGreeting,
  });

  static const backendBaseUrlKey = 'BACKEND_BASE_URL';

  final String agoraAppId;
  final String backendBaseUrl;
  final int agentUid;
  final String? agentGreeting;

  static Future<AppConfig> load() async {
    final backendUrl = const String.fromEnvironment(backendBaseUrlKey);
    final resolvedBackendUrl =
        backendUrl.isEmpty ? defaultBackendBaseUrl() : backendUrl;
    final backendApi = BackendApi(baseUrl: resolvedBackendUrl);

    try {
      final data = await backendApi.fetchClientConfig();
      return AppConfig(
        agoraAppId: (data['agoraAppId'] as String?) ?? '',
        backendBaseUrl: resolvedBackendUrl,
        agentUid:
            int.tryParse((data['agentUid'] ?? '').toString()) ?? defaultAgentUid,
        agentGreeting: data['agentGreeting'] as String?,
      );
    } finally {
      backendApi.dispose();
    }
  }

  bool get hasAgoraAppId => agoraAppId.isNotEmpty;
  bool get hasBackendBaseUrl => backendBaseUrl.isNotEmpty;
  bool get hasGreeting => (agentGreeting ?? '').isNotEmpty;
}
