import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge(this.kinds);

  final Set<String> kinds;

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
  Future<Set<String>> shareKinds(String packageName) async => kinds;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  String packageName,
  Set<String> kinds,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        bridge: _FakeBridge(kinds),
        conversation: Conversation(
          key: '$packageName|Deniz',
          packageName: packageName,
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
}

void main() {
  testWidgets('ses almayan uygulamada mikrofon ve dosya yok', (tester) async {
    await _pump(tester, 'com.instagram.android', {'photo', 'video'});
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Fotoğraf, video, dosya'));
    await tester.pumpAndSettle();
    expect(find.text('Galeri'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Dosya'), findsNothing);
  });

  testWidgets('her şeyi alan uygulamada mikrofon ve dosya var', (tester) async {
    await _pump(tester, 'com.whatsapp', {'photo', 'video', 'voice', 'file'});
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Fotoğraf, video, dosya'));
    await tester.pumpAndSettle();
    expect(find.text('Dosya'), findsOneWidget);
  });
}
