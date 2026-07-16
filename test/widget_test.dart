import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quacky/widgets/typing_text.dart';

void main() {
  testWidgets('TypingText eventually reveals the full string', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TypingText('quack'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('quack'), findsOneWidget);
  });
}
