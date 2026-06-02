import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/backend.dart';
import '../models/conversation.dart';

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'BackendApiException($statusCode): $message';
}

class BackendApi {
  BackendApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ??
            (() {
              const envBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');
              return envBaseUrl.isEmpty ? defaultBackendBaseUrl() : envBaseUrl;
            })();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters: queryParameters,
    );
  }

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const BackendApiException('Unexpected JSON response shape');
  }

  Future<AgoraTokenData> generateToken({
    String? uid,
    String? channel,
  }) async {
    final queryParameters = <String, String>{};
    if (uid != null) {
      queryParameters['uid'] = uid;
    }
    if (channel != null) {
      queryParameters['channel'] = channel;
    }

    final response = await _client.get(
      _uri(
        '/api/generate-agora-token',
        queryParameters,
      ),
    );
    final data = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        (data['error'] as String?) ?? 'Failed to generate Agora token',
        statusCode: response.statusCode,
      );
    }

    return AgoraTokenData.fromJson(data);
  }

  Future<AgentResponse> inviteAgent(ClientStartRequest request) async {
    final response = await _client.post(
      _uri('/api/invite-agent'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final data = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        (data['error'] as String?) ?? 'Failed to invite agent',
        statusCode: response.statusCode,
      );
    }

    return AgentResponse.fromJson(data);
  }

  Future<Map<String, Object?>> stopConversation(
    StopConversationRequest request,
  ) async {
    final response = await _client.post(
      _uri('/api/stop-conversation'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    final data = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        (data['error'] as String?) ?? 'Failed to stop conversation',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  void dispose() {
    _client.close();
  }
}
