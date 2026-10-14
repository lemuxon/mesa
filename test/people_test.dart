import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/people.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:mesaj_merkezi/screens/inbox_screen.dart';

Conversation _c(
  String key,
  String package,
  String title, {
  int minute = 0,
  int unread = 0,
  int? person,
  String? personName,
  bool pinned = false,
  bool canReply = false,
}) => Conversation(
  key: key,
  packageName: package,
  title: title,
  isGroup: false,
  lastText: 'son mesaj $key',
  lastTime: DateTime(2026, 10, 11, 12, minute),
  unread: unread,
  pinned: pinned,
  canReply: canReply,
  personId: person,
  personName: personName,
);

final _waYagiz = _c(
  'com.whatsapp|Yağız Arda',
  'com.whatsapp',
  'Yağız Arda',
  minute: 10,
  unread: 2,
  person: 7,
  personName: 'Yağız Arda',
  canReply: true,
);
final _igYagiz = _c(
  'com.instagram.android|yagiz.arda',
  'com.instagram.android',
  'yagiz.arda',
  minute: 30,
  unread: 1,
  person: 7,
  personName: 'Yağız Arda',
);
final _waAyse = _c(
  'com.whatsapp|Ayşe',
  'com.whatsapp',
  'Ayşe Kaya',
  minute: 20,
);

class _FakeBridge implements CoreBridge {
  List<Conversation> inbox = [];
  List<PersonSuggestion> suggestions = const [];
  final calls = <String>[];
  final Map<String, List<Message>> messagesByKey = {};

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Stream<bool> get listenerStatusChanges => const Stream.empty();
  @override
  Stream<String> get openRequests => const Stream.empty();
  @override
  Future<ListenerStatus> listenerStatus() async =>
      const ListenerStatus(enabled: true, connected: true);
  @override
  Future<List<Conversation>> conversations({bool archived = false}) async =>
      archived ? const [] : inbox;
  @override
  Future<int> archivedCount() async => 0;
  @override
  Future<String?> takeLaunchConversation() async => null;
  @override
  Future<AppSettings> settings() async =>
      const AppSettings(unifiedNotifications: true);
  @override
  Future<List<PersonSuggestion>> personSuggestions() async => suggestions;
  @override
  Future<int> mergePeople(List<String> keys, {String? name}) async {
    calls.add('merge:${keys.join('+')}:$name');
    return 1;
  }

  @override
  Future<void> dismissPersonSuggestion(String a, String b) async {
    calls.add('dismiss:$a+$b');
    suggestions = const [];
  }

  // Sohbet ekranı.
  @override
  Future<List<Message>> messages(String key) async =>
      messagesByKey[key] ?? const [];
  @override
  Future<ReplyMode> replyMode(Conversation c) async =>
      c.canReply ? ReplyMode.direct : ReplyMode.app;
  @override
  Future<List<ScheduledMessage>> scheduledMessages({String? key}) async =>
      const [];
  @override
  Future<void> markRead(String key) async => calls.add('read:$key');
  @override
  Future<void> setActiveConversation(String? key) async =>
      calls.add('active:$key');
  @override
  Future<void> setActiveConversations(List<String> keys) async =>
      calls.add('activeAll:${keys.length}');
  @override
  Future<void> sendReply(String key, String text, {bool auto = false}) async =>
      calls.add('reply:$key:$text');
  @override
  Future<bool> sendViaApp(Conversation c, String text) async {
    calls.add('viaApp:${c.key}:$text');
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('kişiye göre toplama', () {
    test('aynı kişinin sohbetleri tek satır, sıra korunur', () {
      final entries = groupByPerson([_igYagiz, _waAyse, _waYagiz]);
      expect(entries, hasLength(2));
      final person = entries.first;
      expect(person.isPerson, isTrue);
      expect(person.summary.title, 'Yağız Arda');
      expect(person.summary.unread, 3);
      // En son yazışılan (Instagram) önce.
      expect(person.packages, ['com.instagram.android', 'com.whatsapp']);
      expect(person.summary.lastText, _igYagiz.lastText);
      expect(entries.last.summary.key, _waAyse.key);
    });

    test('tek üyesi görünen kişi normal sohbet olarak kalır', () {
      final entries = groupByPerson([_waYagiz, _waAyse]);
      expect(entries.every((e) => !e.isPerson), isTrue);
    });

    test('ad karşılaştırması Türkçe harf ve işaretlerden bağımsız', () {
      expect(nameKey('Yağız Arda'), nameKey('yagiz.arda'));
      expect(nameKey('İREM_ÇELİK'), 'iremcelik');
    });

    test('birleşen kişiye gerçek ada benzeyen başlık verilir', () {
      final ig = _c('ig|yagiz.arda', 'com.instagram.android', 'yagiz.arda');
      final wa = _c('wa|Yağız Arda', 'com.whatsapp', 'Yağız Arda');
      expect(personNameFor(ig, wa), 'Yağız Arda');
    });
  });

  group('gelen kutusu', () {
    Future<_FakeBridge> pumpInbox(
      WidgetTester tester,
      List<Conversation> inbox, {
      List<PersonSuggestion> suggestions = const [],
    }) async {
      final bridge = _FakeBridge()
        ..inbox = inbox
        ..suggestions = suggestions;
      await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
      await tester.pumpAndSettle();
      return bridge;
    }

    testWidgets('kişi tek satırda, toplam okunmamışla', (tester) async {
      await pumpInbox(tester, [_igYagiz, _waAyse, _waYagiz]);
      expect(find.text('Yağız Arda'), findsOneWidget);
      expect(find.text('yagiz.arda'), findsNothing);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('"Aynı kişi mi?" önerisi birleştirilir', (tester) async {
      final ig = _c('ig|yagiz.arda', 'com.instagram.android', 'yagiz.arda');
      final wa = _c('wa|Yağız Arda', 'com.whatsapp', 'Yağız Arda');
      final bridge = await pumpInbox(
        tester,
        [ig, wa],
        suggestions: [PersonSuggestion(a: ig.key, b: wa.key, reason: 'name')],
      );
      expect(find.text('Aynı kişi mi?'), findsOneWidget);
      await tester.tap(find.text('Birleştir'));
      await tester.pumpAndSettle();
      expect(bridge.calls, contains('merge:${ig.key}+${wa.key}:Yağız Arda'));
    });

    testWidgets('"Farklı kişiler" öneriyi kaldırır', (tester) async {
      final ig = _c('ig|yagiz.arda', 'com.instagram.android', 'yagiz.arda');
      final wa = _c('wa|Yağız Arda', 'com.whatsapp', 'Yağız Arda');
      final bridge = await pumpInbox(
        tester,
        [ig, wa],
        suggestions: [PersonSuggestion(a: ig.key, b: wa.key, reason: 'name')],
      );
      await tester.tap(find.text('Farklı kişiler'));
      await tester.pumpAndSettle();
      expect(bridge.calls, contains('dismiss:${ig.key}+${wa.key}'));
      expect(find.text('Aynı kişi mi?'), findsNothing);
    });
  });

  group('kişi ekranı', () {
    Future<_FakeBridge> pumpPerson(WidgetTester tester) async {
      final bridge = _FakeBridge()
        ..messagesByKey[_waYagiz.key] = [
          Message(
            id: 'w1',
            sender: 'Yağız Arda',
            text: 'WhatsApp mesajı',
            time: DateTime(2026, 10, 11, 12, 10),
            outgoing: false,
          ),
        ]
        ..messagesByKey[_igYagiz.key] = [
          Message(
            id: 'i1',
            sender: 'yagiz.arda',
            text: 'Instagram mesajı',
            time: DateTime(2026, 10, 11, 12, 30),
            outgoing: false,
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            bridge: bridge,
            conversation: _igYagiz,
            members: [_igYagiz, _waYagiz],
          ),
        ),
      );
      await tester.pumpAndSettle();
      return bridge;
    }

    testWidgets('iki uygulamanın mesajları tek zaman çizgisinde', (
      tester,
    ) async {
      final bridge = await pumpPerson(tester);
      expect(find.text('Yağız Arda'), findsWidgets);
      expect(find.text('WhatsApp mesajı'), findsOneWidget);
      expect(find.text('Instagram mesajı'), findsOneWidget);
      // Eski mesaj ekranda yukarıda.
      expect(
        tester.getTopLeft(find.text('WhatsApp mesajı')).dy,
        lessThan(tester.getTopLeft(find.text('Instagram mesajı')).dy),
      );
      expect(bridge.calls, contains('read:${_waYagiz.key}'));
      expect(bridge.calls, contains('read:${_igYagiz.key}'));
      expect(bridge.calls, contains('activeAll:2'));
    });

    testWidgets('yanıt seçilen uygulamadan gider', (tester) async {
      final bridge = await pumpPerson(tester);
      // Varsayılan: Instagram (yanıt yolu yok → uygulamada açılır).
      await tester.enterText(find.byType(TextField), 'Selam');
      await tester.pump();
      await tester.tap(find.byTooltip('Gönder (basılı tutun: zamanla)'));
      await tester.pumpAndSettle();
      expect(bridge.calls, contains('viaApp:${_igYagiz.key}:Selam'));

      // WhatsApp seçilince doğrudan yanıt.
      await tester.tap(find.widgetWithText(ChoiceChip, 'WhatsApp'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Naber');
      await tester.pump();
      await tester.tap(find.byTooltip('Gönder (basılı tutun: zamanla)'));
      await tester.pumpAndSettle();
      expect(bridge.calls, contains('reply:${_waYagiz.key}:Naber'));
    });
  });
}
