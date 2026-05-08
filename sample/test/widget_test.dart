import 'package:flutter_test/flutter_test.dart';
import 'package:vialink_sample/main.dart';

void main() {
  testWidgets('ViaLink Sample 앱 렌더링', (WidgetTester tester) async {
    await tester.pumpWidget(const ViaLinkSampleApp());

    expect(find.text('ViaLink Sample'), findsOneWidget);
  });
}
