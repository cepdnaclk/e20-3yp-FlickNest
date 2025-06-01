import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RoomsPage dummy widget test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Text('RoomsPage'))));
    expect(find.text('RoomsPage'), findsOneWidget);
  });
} 