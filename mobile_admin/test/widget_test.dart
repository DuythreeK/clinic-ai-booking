import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_admin/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows login screen when no local session exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MobileAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập admin'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.textContaining('API:'), findsOneWidget);
  });
}
