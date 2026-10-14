import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/screens/storage_card.dart';

class _FakeBridge implements CoreBridge {
  Map<String, int> usage = {
    'database': 12 * 1024 * 1024,
    'media': 30 * 1024 * 1024,
    'telegram': 900 * 1024 * 1024,
    'web': 200 * 1024 * 1024,
    'temporary': 5 * 1024 * 1024,
  };
  int cleans = 0;

  @override
  Future<Map<String, int>> storageUsage() async => usage;

  @override
  Future<int> cleanStorage() async {
    cleans++;
    usage = {...usage, 'telegram': 100 * 1024 * 1024, 'web': 20 * 1024 * 1024};
    return 980 * 1024 * 1024;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('kaplanan yer kategorilere göre; temizlik onayla', (
    tester,
  ) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StorageCard(bridge: bridge)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Depolama · 1,1 GB'), findsOneWidget);
    expect(find.text('900 MB'), findsOneWidget);

    await tester.tap(find.text('Önbelleği temizle'));
    await tester.pumpAndSettle();
    expect(find.text('Önbellek temizlensin mi?'), findsOneWidget);
    await tester.tap(find.text('Temizle'));
    await tester.pumpAndSettle();

    expect(bridge.cleans, 1);
    expect(find.text('980 MB yer açıldı.'), findsOneWidget);
    expect(find.text('100 MB'), findsOneWidget);
  });

  testWidgets('vazgeçilirse temizlenmez', (tester) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StorageCard(bridge: bridge)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Önbelleği temizle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(bridge.cleans, 0);
  });
}
