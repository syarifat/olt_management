
import 'package:flutter_test/flutter_test.dart';
import 'package:olt_management/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OltMonitorApp());
    
    // Just verify the app builds
    expect(find.byType(OltMonitorApp), findsOneWidget);
  });
}
