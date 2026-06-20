import 'package:flutter_test/flutter_test.dart';

import 'package:quijote_flutter/main.dart';

void main() {
  testWidgets('shows processing home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProcesamientoApp());

    expect(find.text('Procesamiento'), findsOneWidget);
    expect(find.text('Don Quijote de la Mancha'), findsOneWidget);
    expect(find.text('Procesar Texto'), findsOneWidget);
  });
}
