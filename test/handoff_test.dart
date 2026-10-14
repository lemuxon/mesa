import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';

class _FakeBridge implements CoreBridge {
  final calls = <String>[];

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Future<List<Message>> messages(String key) async => const [];
  @override
  Future<ReplyMode> replyMode(Conversation c) async => ReplyMode.app;
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
  Future<Set<String>> shareKinds(String packageName) async => {'photo'};
  @override
  Future<bool> sendViaApp(Conversation c, String text) async {
    calls.add('app:$text');
    return true;
  }

  @override
  Future<String?> recordSentViaApp(String key, String text) async {
    calls.add('kayıt:$text');
    return 'out-1';
  }

  @override
  Future<void> deleteMessage(String key, String id) async =>
      calls.add('sil:$id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _leaveAndReturn(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'uygulamada gönderilen mesaj buraya da yazılır, geri alınabilir',
    (tester) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            bridge: bridge,
            conversation: Conversation(
              key: 'com.instagram.android|Deniz',
              packageName: 'com.instagram.android',
              title: 'Deniz',
              isGroup: false,
              lastText: '',
              lastTime: DateTime(2026, 10, 12),
              unread: 0,
              canReply: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Selam');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(bridge.calls, ['app:Selam', 'kayıt:Selam']);

      await _leaveAndReturn(tester);
      expect(find.text('Mesajınız bu sohbete de kaydedildi.'), findsOneWidget);
      await tester.tap(find.text('Gönderilmedi'));
      await tester.pumpAndSettle();
      expect(bridge.calls.last, 'sil:out-1');

      // İkinci dönüşte yeniden sorulmaz.
      await _leaveAndReturn(tester);
      expect(find.text('Mesajınız bu sohbete de kaydedildi.'), findsNothing);
    },
  );
}
