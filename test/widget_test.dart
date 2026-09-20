import 'package:flutter_test/flutter_test.dart';
import 'package:mca_aptitude_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const McaAptitudeApp());
    expect(find.byType(McaAptitudeApp), findsOneWidget);
  });
}
