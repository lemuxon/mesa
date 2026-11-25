import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/screens/backup_card.dart';

class _FakeBridge implements CoreBridge {
  AutoBackupStatus status = AutoBackupStatus(
    enabled: true,
    days: 7,
    folder: 'Mesa yedekleri',
    lastTime: DateTime.now().subtract(const Duration(hours: 1)),
    lastError: 'WRITE',
  );
  int runs = 0;
  int disables = 0;

  @override
  Future<AutoBackupStatus> autoBackupStatus() async => status;

  @override
  Future<void> runAutoBackupNow() async => runs++;

  @override
  Future<AutoBackupStatus> disableAutoBackup() async {
    disables++;
    return status = const AutoBackupStatus();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> pump(WidgetTester tester, _FakeBridge bridge) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: BackupCard(bridge: bridge)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('otomatik yedek durumu ve hatası görünür', (tester) async {
    final bridge = _FakeBridge();
    await pump(tester, bridge);
    expect(find.text('Otomatik yedek'), findsOneWidget);
    expect(find.textContaining('Her hafta · Mesa yedekleri'), findsOneWidget);
    expect(
      find.textContaining('Yedek yazılamadı; yer kalmamış olabilir.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Şimdi yedekle'));
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(bridge.runs, 1);
  });

  testWidgets('otomatik yedek kapatılır', (tester) async {
    final bridge = _FakeBridge();
    await pump(tester, bridge);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(bridge.disables, 1);
    expect(find.text('Şimdi yedekle'), findsNothing);
  });
}
