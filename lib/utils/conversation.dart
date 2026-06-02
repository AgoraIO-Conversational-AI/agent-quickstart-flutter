import '../models/conversation.dart';

String normalizeTranscriptSpacing(String text) {
  return text
      .replaceAllMapped(
        RegExp(r'([.!?])([A-Za-z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAllMapped(
        RegExp(r',([A-Za-z])'),
        (match) => ', ${match.group(1)}',
      )
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

int normalizeTimestampMs(int timestamp) {
  return timestamp > 1000000000000 ? timestamp : timestamp * 1000;
}

AgentVisualizerState mapAgentVisualizerState(
  String? agentState,
  bool isAgentConnected,
  String connectionState,
) {
  if (connectionState == 'DISCONNECTED' ||
      connectionState == 'DISCONNECTING') {
    return AgentVisualizerState.disconnected;
  }

  if (connectionState == 'CONNECTING' || connectionState == 'RECONNECTING') {
    return AgentVisualizerState.joining;
  }

  if (!isAgentConnected) {
    return AgentVisualizerState.notJoined;
  }

  switch (agentState) {
    case 'listening':
      return AgentVisualizerState.listening;
    case 'thinking':
      return AgentVisualizerState.analyzing;
    case 'speaking':
      return AgentVisualizerState.talking;
    case 'idle':
    case 'silent':
    default:
      return AgentVisualizerState.ambient;
  }
}

TranscriptItem toTranscriptItem(TranscriptItem item) {
  return item.copyWith(
    text: normalizeTranscriptSpacing(item.text),
    createdAtMs: item.createdAtMs == null
        ? null
        : normalizeTimestampMs(item.createdAtMs!),
  );
}

List<TranscriptItem> normalizeTranscript(
  List<TranscriptItem> transcript,
  String localUid,
) {
  return transcript.map((item) {
    final remappedUid = item.uid == '0' ? localUid : item.uid;
    final normalizedText = normalizeTranscriptSpacing(item.text);
    return item.copyWith(uid: remappedUid, text: normalizedText);
  }).toList(growable: false);
}

List<TranscriptMessage> getMessageList(List<TranscriptItem> transcript) {
  return transcript
      .where((item) => item.status != TranscriptTurnStatus.inProgress)
      .map(
        (item) => TranscriptMessage(
          turnId: item.turnId,
          uid: item.uid,
          text: item.text,
          status: item.status,
          createdAtMs: item.createdAtMs == null
              ? null
              : normalizeTimestampMs(item.createdAtMs!),
        ),
      )
      .toList(growable: false);
}

TranscriptMessage? getCurrentInProgressMessage(List<TranscriptItem> transcript) {
  final item = transcript.cast<TranscriptItem?>().firstWhere(
        (entry) => entry?.status == TranscriptTurnStatus.inProgress,
        orElse: () => null,
      );

  if (item == null) {
    return null;
  }

  return TranscriptMessage(
    turnId: item.turnId,
    uid: item.uid,
    text: item.text,
    status: item.status,
    createdAtMs: item.createdAtMs == null
        ? null
        : normalizeTimestampMs(item.createdAtMs!),
  );
}

