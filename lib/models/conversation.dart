import 'package:flutter/foundation.dart';

enum TranscriptTurnStatus { inProgress, completed, interrupted }

extension TranscriptTurnStatusX on TranscriptTurnStatus {
  String get apiValue => switch (this) {
        TranscriptTurnStatus.inProgress => 'IN_PROGRESS',
        TranscriptTurnStatus.completed => 'COMPLETED',
        TranscriptTurnStatus.interrupted => 'INTERRUPTED',
      };
}

enum AgentVisualizerState {
  disconnected,
  joining,
  notJoined,
  listening,
  analyzing,
  talking,
  ambient,
}

extension AgentVisualizerStateX on AgentVisualizerState {
  String get apiValue => switch (this) {
        AgentVisualizerState.disconnected => 'disconnected',
        AgentVisualizerState.joining => 'joining',
        AgentVisualizerState.notJoined => 'not-joined',
        AgentVisualizerState.listening => 'listening',
        AgentVisualizerState.analyzing => 'analyzing',
        AgentVisualizerState.talking => 'talking',
        AgentVisualizerState.ambient => 'ambient',
      };
}

@immutable
class AgoraTokenData {
  const AgoraTokenData({
    required this.token,
    required this.uid,
    required this.channel,
    this.agentId,
  });

  final String token;
  final String uid;
  final String channel;
  final String? agentId;

  factory AgoraTokenData.fromJson(Map<String, Object?> json) {
    return AgoraTokenData(
      token: (json['token'] as String?) ?? '',
      uid: (json['uid'] as String?) ?? '',
      channel: (json['channel'] as String?) ?? '',
      agentId: json['agentId'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'token': token,
        'uid': uid,
        'channel': channel,
        'agentId': agentId,
      };
}

@immutable
class ClientStartRequest {
  const ClientStartRequest({
    required this.requesterId,
    required this.channelName,
  });

  final String requesterId;
  final String channelName;

  Map<String, String> toJson() => {
        'requester_id': requesterId,
        'channel_name': channelName,
      };
}

@immutable
class StopConversationRequest {
  const StopConversationRequest({required this.agentId});

  final String agentId;

  Map<String, String> toJson() => {'agent_id': agentId};
}

@immutable
class AgentResponse {
  const AgentResponse({
    required this.agentId,
    required this.createTs,
    required this.state,
  });

  final String agentId;
  final int createTs;
  final String state;

  factory AgentResponse.fromJson(Map<String, Object?> json) {
    return AgentResponse(
      agentId: (json['agent_id'] as String?) ?? '',
      createTs: (json['create_ts'] as num?)?.toInt() ?? 0,
      state: (json['state'] as String?) ?? '',
    );
  }

  Map<String, Object?> toJson() => {
        'agent_id': agentId,
        'create_ts': createTs,
        'state': state,
      };
}

@immutable
class AgoraRenewalTokens {
  const AgoraRenewalTokens({
    required this.rtcToken,
    required this.rtmToken,
  });

  final String rtcToken;
  final String rtmToken;

  factory AgoraRenewalTokens.fromJson(Map<String, Object?> json) {
    return AgoraRenewalTokens(
      rtcToken: (json['rtcToken'] as String?) ?? '',
      rtmToken: (json['rtmToken'] as String?) ?? '',
    );
  }

  Map<String, String> toJson() => {
        'rtcToken': rtcToken,
        'rtmToken': rtmToken,
      };
}

@immutable
class TranscriptItem {
  const TranscriptItem({
    required this.turnId,
    required this.uid,
    required this.text,
    required this.status,
    this.createdAtMs,
  });

  final String turnId;
  final String uid;
  final String text;
  final TranscriptTurnStatus status;
  final int? createdAtMs;

  TranscriptItem copyWith({
    String? turnId,
    String? uid,
    String? text,
    TranscriptTurnStatus? status,
    int? createdAtMs,
  }) {
    return TranscriptItem(
      turnId: turnId ?? this.turnId,
      uid: uid ?? this.uid,
      text: text ?? this.text,
      status: status ?? this.status,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}

@immutable
class TranscriptMessage {
  const TranscriptMessage({
    required this.turnId,
    required this.uid,
    required this.text,
    required this.status,
    this.createdAtMs,
  });

  final String turnId;
  final String uid;
  final String text;
  final TranscriptTurnStatus status;
  final int? createdAtMs;
}
