import 'package:flutter/foundation.dart';

enum TranscriptTurnStatus { inProgress, completed, interrupted }

extension TranscriptTurnStatusX on TranscriptTurnStatus {
  String get apiValue => switch (this) {
        TranscriptTurnStatus.inProgress => 'IN_PROGRESS',
        TranscriptTurnStatus.completed => 'COMPLETED',
        TranscriptTurnStatus.interrupted => 'INTERRUPTED',
      };

  static TranscriptTurnStatus fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    return switch (normalized) {
      'in_progress' || 'inprogress' => TranscriptTurnStatus.inProgress,
      'interrupted' => TranscriptTurnStatus.interrupted,
      'completed' || 'end' || 'ended' => TranscriptTurnStatus.completed,
      _ => TranscriptTurnStatus.completed,
    };
  }
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

enum ConversationPhase {
  idle,
  preparing,
  connecting,
  connected,
  ending,
  error,
}

@immutable
class ConversationSessionState {
  const ConversationSessionState({
    required this.phase,
    required this.transcript,
    this.tokenData,
    this.agentResponse,
    this.localUid,
    this.remoteUid,
    this.connectionStatus,
    this.agentState,
    this.isMicMuted = false,
    this.errorMessage,
  });

  const ConversationSessionState.initial()
      : this(
          phase: ConversationPhase.idle,
          transcript: const <TranscriptItem>[],
        );

  final ConversationPhase phase;
  final AgoraTokenData? tokenData;
  final AgentResponse? agentResponse;
  final List<TranscriptItem> transcript;
  final int? localUid;
  final int? remoteUid;
  final String? connectionStatus;
  final String? agentState;
  final bool isMicMuted;
  final String? errorMessage;

  ConversationSessionState copyWith({
    ConversationPhase? phase,
    AgoraTokenData? tokenData,
    AgentResponse? agentResponse,
    List<TranscriptItem>? transcript,
    int? localUid,
    int? remoteUid,
    String? connectionStatus,
    String? agentState,
    bool? isMicMuted,
    String? errorMessage,
  }) {
    return ConversationSessionState(
      phase: phase ?? this.phase,
      tokenData: tokenData ?? this.tokenData,
      agentResponse: agentResponse ?? this.agentResponse,
      transcript: transcript ?? this.transcript,
      localUid: localUid ?? this.localUid,
      remoteUid: remoteUid ?? this.remoteUid,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      agentState: agentState ?? this.agentState,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
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

  AgoraTokenData copyWith({
    String? token,
    String? uid,
    String? channel,
    String? agentId,
  }) {
    return AgoraTokenData(
      token: token ?? this.token,
      uid: uid ?? this.uid,
      channel: channel ?? this.channel,
      agentId: agentId ?? this.agentId,
    );
  }

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

  factory TranscriptItem.fromJson(Map<String, Object?> json) {
    final createdAt = json['createdAtMs'] ?? json['created_at_ms'] ?? json['timestamp'];
    return TranscriptItem(
      turnId: (json['turnId'] ?? json['turn_id'] ?? json['turnID'] ?? '')
          .toString(),
      uid: (json['uid'] ?? json['publisher'] ?? json['userId'] ?? '')
          .toString(),
      text: (json['text'] ?? json['message'] ?? '').toString(),
      status: TranscriptTurnStatusX.fromRaw(json['status'] ?? json['state']),
      createdAtMs: createdAt == null
          ? null
          : (createdAt is num
              ? createdAt.toInt()
              : int.tryParse(createdAt.toString())),
    );
  }

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
