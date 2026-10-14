import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/ui/avatars.dart';

void main() {
  Future<void> pump(WidgetTester tester, String packageName) async {
    // Önceki simgenin durumu taşınmasın.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: AppIcon(packageName: packageName, size: 28)),
      ),
    );
    await tester.pump();
  }

  testWidgets('kurulu olmayan uygulamada gömülü simge, baş harf değil', (
    tester,
  ) async {
    await pump(tester, 'com.zhiliaoapp.musically');
    expect(find.byKey(const ValueKey('bundled-tiktok')), findsOneWidget);
    expect(find.text('T'), findsNothing);
  });

  testWidgets('gömülüsü olmayanda işaret, o da yoksa baş harf', (tester) async {
    await pump(tester, 'org.telegram.messenger');
    expect(find.byIcon(Icons.telegram), findsOneWidget);

    await pump(tester, 'com.kakao.talk');
    expect(find.text('K'), findsOneWidget);
  });
}
