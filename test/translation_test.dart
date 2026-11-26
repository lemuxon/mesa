import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/l10n/stored_labels.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge({this.needsPack = true});

  final bool needsPack;
  final calls = <String>[];
  final cleared = <String>[];

  final _messages = [
    Message(
      id: 'm1',
      sender: 'Deniz',
      text: 'Are you coming tonight?',
      time: DateTime(2026, 11, 27, 18),
      outgoing: false,
    ),
    Message(
      id: 'm2',
      sender: 'Deniz',
      text: 'Yarın akşam geliyorum, sen de gel',
      time: DateTime(2026, 11, 27, 18, 1),
      outgoing: false,
    ),
  ];

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Future<List<Message>> messages(String key) async => _messages;
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
  Future<TranslateResult> translate(
    String messageId,
    String target, {
    bool download = false,
    String? hint,
  }) async {
    calls.add('$messageId:$target:$download:$hint');
    if (needsPack && !download) {
      return (
        text: null,
        fromName: 'İngilizce',
        error: 'NEED_DOWNLOAD',
        missing: ['Türkçe'],
      );
    }
    return (
      text: 'Bu akşam geliyor musun?',
      fromName: 'İngilizce',
      error: null,
      missing: const <String>[],
    );
  }

  @override
  Future<void> clearTranslation(String messageId) async =>
      cleared.add(messageId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openChat(WidgetTester tester, _FakeBridge bridge) async {
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
          lastTime: DateTime(2026, 11, 27),
          unread: 0,
          canReply: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'yabancı mesajda "Çevir": dil paketi sorulur, çeviri altında görünür',
    (tester) async {
      final bridge = _FakeBridge();
      await _openChat(tester, bridge);

      // Yalnızca İngilizce mesajın altında.
      expect(find.text('Çevir'), findsOneWidget);

      await tester.tap(find.text('Çevir'));
      await tester.pumpAndSettle();
      expect(find.text('Türkçe dil paketi indirilsin mi?'), findsOneWidget);

      await tester.tap(find.text('İndir ve çevir'));
      await tester.pumpAndSettle();
      expect(bridge.calls, ['m1:tr:false:en', 'm1:tr:true:en']);
      expect(find.text('Bu akşam geliyor musun?'), findsOneWidget);
      expect(find.text('Çeviri · aslı İngilizce'), findsOneWidget);
      expect(find.text('Çevir'), findsNothing);
    },
  );

  testWidgets('dil paketi istenmezse çevrilmez', (tester) async {
    final bridge = _FakeBridge();
    await _openChat(tester, bridge);

    await tester.tap(find.text('Çevir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(bridge.calls, ['m1:tr:false:en']);
    expect(find.text('Çevir'), findsOneWidget);
  });

  testWidgets('basılı tutunca çeviri gizlenir', (tester) async {
    final bridge = _FakeBridge(needsPack: false);
    await _openChat(tester, bridge);

    await tester.tap(find.text('Çevir'));
    await tester.pumpAndSettle();
    expect(find.text('Bu akşam geliyor musun?'), findsOneWidget);

    await tester.longPress(find.text('Are you coming tonight?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çeviriyi gizle'));
    await tester.pumpAndSettle();
    expect(bridge.cleared, ['m1']);
    expect(find.text('Bu akşam geliyor musun?'), findsNothing);
    // Gizlenen mesaja yeniden "Çevir" önerilmez (menüde hâlâ var).
    expect(find.text('Çevir'), findsNothing);
  });

  testWidgets('çeviri kartı ve bekleme halleri', (tester) async {
    Future<void> pump(Widget child) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

    var taps = 0;
    await pump(
      MessageTranslation(
        text: null,
        fromName: null,
        busy: true,
        downloading: true,
        mine: false,
        onTranslate: () => taps++,
      ),
    );
    expect(find.text('Dil paketi indiriliyor…'), findsOneWidget);
    await tester.tap(find.text('Dil paketi indiriliyor…'));
    expect(taps, 0);

    await pump(
      MessageTranslation(
        text: null,
        fromName: null,
        busy: true,
        downloading: false,
        mine: false,
        onTranslate: () => taps++,
      ),
    );
    expect(find.text('Çevriliyor…'), findsOneWidget);

    await pump(
      MessageTranslation(
        text: 'Merhaba',
        fromName: null,
        busy: false,
        downloading: false,
        mine: false,
        onTranslate: () => taps++,
      ),
    );
    expect(find.text('Çeviri'), findsOneWidget);
    expect(find.text('Merhaba'), findsOneWidget);
  });

  test('mesaj haritasından çeviri okunur', () {
    final m = Message.fromMap({
      'id': '1',
      'sender': 'Deniz',
      'text': 'Hello',
      'time': 0,
      'outgoing': false,
      'translation': 'Merhaba',
      'translationTo': 'tr',
      'translationFromName': 'İngilizce',
    });
    expect(m.translation, 'Merhaba');
    expect(m.translationTo, 'tr');
    expect(m.translationFromName, 'İngilizce');
  });

  test('medya etiketi çevrilmez', () {
    expect(storedCaption('📷 Fotoğraf: Look at this'), 'Look at this');
    expect(storedCaption('📷 Fotoğraf'), '');
    expect(storedCaption('😀 Çıkartma'), '');
    expect(storedCaption('See you'), 'See you');
  });
}
