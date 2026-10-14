import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/backup_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBridge implements CoreBridge {
  final passwords = <String>[];
  bool cancelLocation = false;
  String? restoreError;

  @override
  Future<BackupResult?> createBackup(String password) async {
    passwords.add(password);
    if (cancelLocation) return null;
    return const BackupResult(messages: 12, files: 3, bytes: 2 * 1024 * 1024);
  }

  @override
  Future<String?> pickBackupFile() async => 'content://yedek/1';

  @override
  Future<BackupResult> restoreBackup(String uri, String password) async {
    passwords.add(password);
    if (restoreError != null) throw PlatformException(code: restoreError!);
    return const BackupResult(messages: 40, files: 5, bytes: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<(_FakeBridge, LocalPrefs)> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.load();
    final bridge = _FakeBridge();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BackupCard(bridge: bridge, prefs: prefs),
          ),
        ),
      ),
    );
    return (bridge, prefs);
  }

  Future<void> typePassword(
    WidgetTester tester,
    String first, [
    String? second,
  ]) async {
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, first);
    if (second != null) await tester.enterText(fields.last, second);
  }

  testWidgets('şifre kısa ya da eşleşmiyorsa yedek alınmaz', (tester) async {
    final (bridge, _) = await pump(tester);
    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('unutursanız yedek açılamaz'), findsOneWidget);

    await typePassword(tester, 'kisa', 'kisa');
    await tester.tap(find.widgetWithText(FilledButton, 'Yedekle'));
    await tester.pumpAndSettle();
    expect(find.text('En az 8 karakter olmalı.'), findsOneWidget);

    await typePassword(tester, 'uzun-sifre-1', 'uzun-sifre-2');
    await tester.tap(find.widgetWithText(FilledButton, 'Yedekle'));
    await tester.pumpAndSettle();
    expect(find.text('Şifreler aynı değil.'), findsOneWidget);
    expect(bridge.passwords, isEmpty);
  });

  testWidgets('yedek alınınca özeti ve son yedek zamanı', (tester) async {
    final (bridge, prefs) = await pump(tester);
    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();
    await typePassword(tester, 'gizli-parola-9', 'gizli-parola-9');
    await tester.tap(find.widgetWithText(FilledButton, 'Yedekle'));
    await tester.pumpAndSettle();

    expect(bridge.passwords, ['gizli-parola-9']);
    expect(
      find.text('Yedek kaydedildi: 12 mesaj, 3 fotoğraf (2,0 MB).'),
      findsOneWidget,
    );
    expect(prefs.lastBackupAt, isNotNull);
    expect(find.textContaining('Son yedek:'), findsOneWidget);
  });

  testWidgets('konum seçilmezse sessizce vazgeçilir', (tester) async {
    final (bridge, prefs) = await pump(tester);
    bridge.cancelLocation = true;
    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();
    await typePassword(tester, 'gizli-parola-9', 'gizli-parola-9');
    await tester.tap(find.widgetWithText(FilledButton, 'Yedekle'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(prefs.lastBackupAt, isNull);
  });

  testWidgets('geri yüklemede yanlış şifre açıkça söylenir', (tester) async {
    final (bridge, _) = await pump(tester);
    bridge.restoreError = 'WRONG_PASSWORD';
    await tester.tap(find.text('Yedekten geri yükle'));
    await tester.pumpAndSettle();
    expect(find.text('Yedekten geri yüklensin mi?'), findsOneWidget);
    await tester.tap(find.text('Dosya seç'));
    await tester.pumpAndSettle();
    await typePassword(tester, 'yanlis');
    await tester.tap(find.widgetWithText(FilledButton, 'Aç'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Şifre yanlış'), findsOneWidget);
  });

  testWidgets('geri yükleme başarılıysa özeti', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Yedekten geri yükle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dosya seç'));
    await tester.pumpAndSettle();
    await typePassword(tester, 'gizli-parola-9');
    await tester.tap(find.widgetWithText(FilledButton, 'Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Geri yüklendi: 40 mesaj, 5 fotoğraf.'), findsOneWidget);
  });
}
