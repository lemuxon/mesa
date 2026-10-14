import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';

class _FakeBridge implements CoreBridge {
  List<Message> chat = const [];
  final calls = <String>[];
  double? upload;

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Future<List<Message>> messages(String key) async => chat;
  @override
  Future<ReplyMode> replyMode(Conversation c) async => ReplyMode.direct;
  @override
  Future<List<ScheduledMessage>> scheduledMessages({String? key}) async =>
      const [];
  @override
  Future<void> markRead(String key) async {}
  @override
  Future<void> setActiveConversation(String? key) async {}
  @override
  Future<AppSettings> settings() async => const AppSettings();
  @override
  Future<void> telegramLoadHistory(String key) async {}
  @override
  Future<bool> telegramResend(String messageId) async {
    calls.add('resend:$messageId');
    return true;
  }

  @override
  Future<double?> uploadProgress(String messageId) async => upload;

  @override
  Future<void> telegramDeleteFailed(String messageId) async =>
      calls.add('delete:$messageId');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Message _out(String id, String text, {String? state, String? error}) => Message(
  id: id,
  sender: null,
  text: text,
  time: DateTime(2026, 10, 11, 12),
  outgoing: true,
  sendState: state,
  sendError: error,
);

Future<_FakeBridge> _pump(
  WidgetTester tester,
  List<Message> chat, {
  double? upload,
}) async {
  final bridge = _FakeBridge()
    ..chat = chat
    ..upload = upload;
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        bridge: bridge,
        conversation: Conversation(
          key: 'tg-42',
          packageName: 'org.telegram.messenger',
          title: 'Can',
          isGroup: false,
          lastText: '',
          lastTime: DateTime(2026, 10, 11),
          unread: 0,
          canReply: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bridge;
}

void main() {
  testWidgets('gönderiliyor saatle, gönderilemeyen kırmızı işaretle', (
    tester,
  ) async {
    await _pump(tester, [
      _out('tg-42-1', 'Yoldayım', state: 'pending'),
      _out('tg-42-2', 'Geliyorum', state: 'failed', error: 'Bağlantı yok'),
    ]);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.text('Gönderilemedi'), findsOneWidget);
  });

  testWidgets('gönderilemeyen mesaja dokununca tekrar gönderilir', (
    tester,
  ) async {
    final bridge = await _pump(tester, [
      _out('tg-42-2', 'Geliyorum', state: 'failed', error: 'Bağlantı yok'),
    ]);
    await tester.tap(find.text('Geliyorum'));
    await tester.pumpAndSettle();
    expect(find.text('Bağlantı yok'), findsOneWidget);
    await tester.tap(find.text('Tekrar gönder'));
    await tester.pumpAndSettle();
    expect(bridge.calls, ['resend:tg-42-2']);
  });

  testWidgets('gönderilemeyen mesaj silinebilir', (tester) async {
    final bridge = await _pump(tester, [
      _out('tg-42-2', 'Geliyorum', state: 'failed'),
    ]);
    await tester.tap(find.text('Geliyorum'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(bridge.calls, ['delete:tg-42-2']);
  });

  testWidgets('gönderilen fotoğraf yüklenirken yüzdesi görünür', (
    tester,
  ) async {
    final bridge = await _pump(tester, [
      _out('tg-42-3', '📷 Fotoğraf', state: 'pending'),
    ], upload: 0.42);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Yükleniyor %42'), findsOneWidget);

    bridge.upload = 0.9;
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Yükleniyor %90'), findsOneWidget);
  });

  testWidgets('yazı mesajında yükleme satırı yok', (tester) async {
    await _pump(tester, [_out('tg-42-4', 'Yoldayım', state: 'pending')]);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.textContaining('Yükleniyor'), findsNothing);
  });
}
