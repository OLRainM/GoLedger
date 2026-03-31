import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goledger/app.dart';

void main() {
  testWidgets('GoLedgerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GoLedgerApp()),
    );
    // 应用启动后应该能看到 GoLedger 标题或登录页面
    await tester.pumpAndSettle();
    expect(find.textContaining('GoLedger'), findsAny);
  });
}
