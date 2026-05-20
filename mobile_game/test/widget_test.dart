import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders DungeonMind smoke widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('DungeonMind'))),
    );

    expect(find.text('DungeonMind'), findsOneWidget);
  });
}
