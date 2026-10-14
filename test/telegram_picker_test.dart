import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/telegram.dart';
import 'package:mesaj_merkezi/screens/telegram_picker_sheet.dart';

class _FakeBridge implements CoreBridge {
  final stickerRequests = <String>[];
  final gifQueries = <String>[];
  final sent = <String>[];
  bool sendResult = true;

  @override
  Future<List<StickerSetInfo>> telegramStickerSets() async => const [
    StickerSetInfo(id: 'recent', title: 'Son kullanılanlar'),
    StickerSetInfo(id: '42', title: 'Kediler'),
  ];

  @override
  Future<List<PickItem>> telegramStickers(String setId) async {
    stickerRequests.add(setId);
    return [PickItem(token: 's-$setId', emoji: setId == '42' ? '🐱' : '😀')];
  }

  @override
  Future<List<PickItem>> telegramGifs(String key, String query) async {
    gifQueries.add(query);
    return query.isEmpty ? const [] : const [PickItem(token: 'g1')];
  }

  @override
  Future<bool> telegramSendPick(String key, String token) async {
    sent.add(token);
    return sendResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<_FakeBridge> openSheet(WidgetTester tester) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => TelegramPickerSheet(
                  bridge: bridge,
                  conversationKey: 'tg|7',
                ),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return bridge;
  }

  testWidgets('ilk paket (son kullanılanlar) açılır', (tester) async {
    final bridge = await openSheet(tester);
    expect(bridge.stickerRequests, ['recent']);
    expect(find.text('😀'), findsOneWidget);
  });

  testWidgets('paket seçilince çıkartmaları yüklenir', (tester) async {
    final bridge = await openSheet(tester);
    await tester.tap(find.text('Kediler'));
    await tester.pumpAndSettle();
    expect(bridge.stickerRequests, ['recent', '42']);
    expect(find.text('🐱'), findsOneWidget);
  });

  testWidgets('çıkartmaya dokununca gönderir ve panel kapanır', (tester) async {
    final bridge = await openSheet(tester);
    await tester.tap(find.text('😀'));
    await tester.pumpAndSettle();
    expect(bridge.sent, ['s-recent']);
    expect(find.byType(TelegramPickerSheet), findsNothing);
  });

  testWidgets('gönderilemezse panel açık kalır ve uyarı çıkar', (tester) async {
    final bridge = await openSheet(tester);
    bridge.sendResult = false;
    await tester.tap(find.text('😀'));
    await tester.pumpAndSettle();
    expect(find.byType(TelegramPickerSheet), findsOneWidget);
    expect(find.text('Gönderilemedi.'), findsOneWidget);
  });

  testWidgets('GIF araması yazmayı bekleyip tek istek atar', (tester) async {
    final bridge = await openSheet(tester);
    await tester.tap(find.text('GIF'));
    await tester.pumpAndSettle();
    expect(bridge.gifQueries, ['']);
    expect(find.textContaining('Kaydedilmiş GIF yok'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ked');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'kedi');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(bridge.gifQueries, ['', 'kedi']);

    await tester.tap(find.text('GIF').last);
    await tester.pumpAndSettle();
    expect(bridge.sent, ['g1']);
  });
}
