import 'dart:convert';

import '../models/conversation.dart';
import 'conversation.dart';

List<TranscriptItem> parseTranscriptPayload(
  Object? payload, {
  String? fallbackUid,
}) {
  final entries = <TranscriptItem>[];

  void addEntry(Map<String, Object?> json) {
    final item = TranscriptItem.fromJson(json);
    final uid = item.uid.isEmpty ? (fallbackUid ?? 'system') : item.uid;
    final normalized = item.copyWith(
      uid: uid == '0' ? (fallbackUid ?? uid) : uid,
      text: normalizeTranscriptSpacing(item.text),
      createdAtMs: item.createdAtMs == null
          ? null
          : normalizeTimestampMs(item.createdAtMs!),
    );

    final index = entries.indexWhere((entry) => entry.turnId == normalized.turnId);
    if (index == -1) {
      entries.add(normalized);
    } else {
      entries[index] = normalized;
    }
  }

  if (payload is List) {
    for (final item in payload) {
      if (item is Map) {
        addEntry(item.map((key, value) => MapEntry(key.toString(), value)));
      }
    }
    return entries;
  }

  if (payload is Map) {
    final map = payload.map((key, value) => MapEntry(key.toString(), value));
    final transcript = map['transcript'] ?? map['items'] ?? map['messages'];
    if (transcript is List) {
      for (final item in transcript) {
        if (item is Map) {
          addEntry(item.map((key, value) => MapEntry(key.toString(), value)));
        }
      }
      return entries;
    }

    if (map.containsKey('turnId') ||
        map.containsKey('turn_id') ||
        map.containsKey('text') ||
        map.containsKey('message')) {
      addEntry(map);
      return entries;
    }

    final nested = map['data'];
    if (nested is String) {
      return parseTranscriptPayload(jsonDecode(nested), fallbackUid: fallbackUid);
    }
  }

  if (payload is String) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return entries;
    }

    try {
      return parseTranscriptPayload(jsonDecode(trimmed), fallbackUid: fallbackUid);
    } catch (_) {
      entries.add(
        TranscriptItem(
          turnId: 'turn-${DateTime.now().microsecondsSinceEpoch}',
          uid: fallbackUid ?? 'system',
          text: normalizeTranscriptSpacing(payload),
          status: TranscriptTurnStatus.completed,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return entries;
    }
  }

  return entries;
}

String? parseAgentStatePayload(Object? payload) {
  if (payload is Map) {
    final map = payload.map((key, value) => MapEntry(key.toString(), value));
    final state = map['state'] ?? map['agentState'];
    if (state != null) {
      return state.toString();
    }
  }

  if (payload is String) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return parseAgentStatePayload(jsonDecode(trimmed));
    } catch (_) {
      return trimmed;
    }
  }

  return null;
}
