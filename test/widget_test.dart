import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a basic widget tree', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('agent_quickstart_flutter'),
          ),
        ),
      ),
    );

    expect(find.text('agent_quickstart_flutter'), findsOneWidget);
  });
}
