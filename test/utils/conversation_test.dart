import 'package:flutter_test/flutter_test.dart';

import 'package:agent_quickstart_flutter/models/conversation.dart';
import 'package:agent_quickstart_flutter/utils/conversation.dart';

void main() {
  test('normalizeTranscript remaps zero uid and cleans spacing', () {
    final transcript = [
      const TranscriptItem(
        turnId: 'turn-1',
        uid: '0',
        text: 'Hello,world!Nice to meet you.',
        status: TranscriptTurnStatus.completed,
      ),
    ];

    final normalized = normalizeTranscript(transcript, '123456');

    expect(normalized.single.uid, '123456');
    expect(normalized.single.text, 'Hello, world! Nice to meet you.');
  });

  test('getMessageList filters in-progress turns and returns current turn', () {
    final transcript = [
      const TranscriptItem(
        turnId: 'turn-1',
        uid: '123456',
        text: 'Working on it',
        status: TranscriptTurnStatus.inProgress,
      ),
      const TranscriptItem(
        turnId: 'turn-2',
        uid: 'agent',
        text: 'Done',
        status: TranscriptTurnStatus.completed,
      ),
    ];

    final messages = getMessageList(transcript);
    final current = getCurrentInProgressMessage(transcript);

    expect(messages, hasLength(1));
    expect(messages.single.turnId, 'turn-2');
    expect(current?.turnId, 'turn-1');
    expect(current?.text, 'Working on it');
  });
}
