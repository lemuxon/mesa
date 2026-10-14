import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/format.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:mesaj_merkezi/screens/inbox_screen.dart';
import 'package:mesaj_merkezi/screens/summary_screen.dart';

final _now = DateTime.now();

final _ali = Conversation(
  key: 'com.whatsapp|Ali',
  packageName: 'com.whatsapp',
  title: 'Ali Veli',
  isGroup: false,
  lastText: 'Akşam geliyor musun?',
  lastTime: _now.subtract(const Duration(hours: 4)),
  unread: 1,
  canReply: true,
);

class _FakeBridge implements CoreBridge {
  final dismissed = <String>[];
  final starredIds = <String, bool>{};
  final scheduledTexts = <(String, DateTime)>[];
  ReplyMode mode = ReplyMode.direct;
  List<WaitingPerson> waitingList = [
    WaitingPerson(
      key: 'com.whatsapp|Ali',
      title: 'Ali Veli',
      packageName: 'com.whatsapp',
      lastTime: _now.subtract(const Duration(hours: 4)),
      lastText: 'Akşam geliyor musun?',
    ),
  ];

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Stream<bool> get listenerStatusChanges => const Stream.empty();
  @override
  Stream<String> get openRequests => const Stream.empty();
  @override
  Future<String?> takeLaunchConversation() async => null;
  @override
  Future<ListenerStatus> listenerStatus() async =>
      const ListenerStatus(enabled: true, connected: true);
  @override
  Future<List<Conversation>> conversations({bool archived = false}) async =>
      archived ? const [] : [_ali];
  @override
  Future<int> archivedCount() async => 0;
  @override
  Future<AppSettings> settings() async =>
      const AppSettings(unifiedNotifications: true);
  @override
  Future<List<WaitingPerson>> waiting() async => waitingList;
  @override
  Future<List<SnoozedConversation>> snoozed() async => const [];
  @override
  Future<void> dismissWaiting(String key) async {
    dismissed.add(key);
    waitingList = const [];
  }

  @override
  Future<List<Message>> messages(String key) async => [
    Message(
      id: 'm1',
      sender: 'Ali Veli',
      text: 'Toplantı kodu 4821',
      time: _now,
      outgoing: false,
      starred: starredIds['m1'] ?? false,
    ),
    Message(
      id: 'm2',
      sender: 'Ali Veli',
      text: 'Gizli plan',
      time: _now,
      outgoing: false,
      deleted: true,
    ),
  ];
  @override
  Future<ReplyMode> replyMode(Conversation c) async => mode;
  @override
  Future<bool> canReply(String key) async => mode == ReplyMode.direct;
  @override
  Future<void> markRead(String key) async {}
  @override
  Future<void> setActiveConversation(String? key) async {}
  @override
  Future<List<ScheduledMessage>> scheduledMessages({String? key}) async => [
    for (final (i, (text, at)) in scheduledTexts.indexed)
      ScheduledMessage(id: i, key: _ali.key, text: text, at: at),
  ];
  @override
  Future<void> starMessage(String id, bool value) async =>
      starredIds[id] = value;
  @override
  Future<void> scheduleMessage(String key, String text, DateTime at) async =>
      scheduledTexts.add((text, at));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpChat(WidgetTester tester, _FakeBridge bridge) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(bridge: bridge, conversation: _ali),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('bekleme süresi ve gelecek zaman biçimi', () {
    final now = DateTime(2026, 10, 11, 14, 0);
    expect(
      formatWaiting(now.subtract(const Duration(minutes: 5)), now),
      '5 dk',
    );
    expect(formatWaiting(now.subtract(const Duration(hours: 3)), now), '3 sa');
    expect(formatWaiting(now.subtract(const Duration(days: 2)), now), '2 g');
    expect(formatWhen(DateTime(2026, 10, 11, 20), now), 'bugün 20:00');
    expect(formatWhen(DateTime(2026, 10, 12, 9), now), 'yarın 09:00');
    expect(formatWhen(DateTime(2026, 11, 1, 9), now), '1 Kasım 09:00');
  });

  testWidgets('yanıt bekleyenler şeridi görünür, "yanıt gerekmez" kaldırır', (
    tester,
  ) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
    await tester.pumpAndSettle();

    expect(find.text('Yanıt bekliyor · 1'), findsOneWidget);
    expect(find.text('4 sa'), findsOneWidget);
    await tester.longPress(find.text('Ali'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yanıt gerekmez'));
    await tester.pumpAndSettle();
    expect(bridge.dismissed, ['com.whatsapp|Ali']);
    expect(find.textContaining('Yanıt bekliyor'), findsNothing);
  });

  testWidgets('mesaja basılı tutunca kaydedilir; silinen mesaj etiketlenir', (
    tester,
  ) async {
    final bridge = _FakeBridge();
    await _pumpChat(tester, bridge);

    // Silinen mesajın metni kalır, "silindi" etiketi görünür.
    expect(find.text('Gizli plan'), findsOneWidget);
    expect(find.text('silindi · '), findsOneWidget);

    await tester.longPress(find.text('Toplantı kodu 4821'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(bridge.starredIds['m1'], isTrue);
  });

  testWidgets('gönder düğmesine basılı tutunca mesaj zamanlanır', (
    tester,
  ) async {
    final bridge = _FakeBridge();
    await _pumpChat(tester, bridge);

    await tester.enterText(find.byType(TextField), 'Doğum günün kutlu olsun');
    await tester.pump();
    await tester.longPress(find.byTooltip('Gönder (basılı tutun: zamanla)'));
    await tester.pumpAndSettle();
    expect(find.text('Ne zaman gönderilsin?'), findsOneWidget);
    await tester.tap(find.text('1 saat sonra'));
    await tester.pumpAndSettle();

    final (text, at) = bridge.scheduledTexts.single;
    expect(text, 'Doğum günün kutlu olsun');
    expect(at.difference(DateTime.now()).inMinutes, inInclusiveRange(58, 60));
    expect(find.textContaining('1 planlı mesaj'), findsOneWidget);
    expect(find.textContaining('kendiliğinden gönderilecek'), findsOneWidget);
  });

  testWidgets('yanıt yolu yokken planlama dokun-gönder olacağını söyler', (
    tester,
  ) async {
    final bridge = _FakeBridge()..mode = ReplyMode.app;
    await _pumpChat(tester, bridge);

    await tester.enterText(find.byType(TextField), 'Akşam görüşelim');
    await tester.pump();
    await tester.tap(find.byTooltip('Zamanla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 saat sonra'));
    await tester.pumpAndSettle();

    expect(bridge.scheduledTexts.single.$1, 'Akşam görüşelim');
    expect(find.textContaining('bildirim gelecek'), findsOneWidget);
    expect(find.textContaining('kendiliğinden gönderilecek'), findsNothing);
  });

  testWidgets('yazmaya başlayınca görünen Zamanla düğmesi', (tester) async {
    final bridge = _FakeBridge();
    await _pumpChat(tester, bridge);
    expect(find.byTooltip('Zamanla'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Toplantı hatırlatması');
    await tester.pump();
    await tester.tap(find.byTooltip('Zamanla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 saat sonra'));
    await tester.pumpAndSettle();
    expect(bridge.scheduledTexts.single.$1, 'Toplantı hatırlatması');
  });

  testWidgets('ek menüsünden Zamanla: önce mesaj sorulur', (tester) async {
    final bridge = _FakeBridge();
    await _pumpChat(tester, bridge);

    await tester.tap(find.byTooltip('Fotoğraf, video, dosya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zamanla'));
    await tester.pumpAndSettle();
    expect(find.text('Planlı mesaj'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Günaydın',
    );
    await tester.tap(find.text('Zaman seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 saat sonra'));
    await tester.pumpAndSettle();
    expect(bridge.scheduledTexts.single.$1, 'Günaydın');
  });

  testWidgets('haftalık özet toplamı ve en çok yazışılanı gösterir', (
    tester,
  ) async {
    final bridge = _StatsBridge();
    await tester.pumpWidget(MaterialApp(home: SummaryScreen(bridge: bridge)));
    await tester.pumpAndSettle();

    expect(find.text('42 mesaj'), findsOneWidget);
    expect(find.text('Ali Veli'), findsOneWidget);
    expect(find.text('🥇'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('En yoğun saatin 21:00'), 200);
    expect(find.text('En yoğun saatin 21:00'), findsOneWidget);
    expect(find.text('Gönderenin silip sende kalan 2 mesaj'), findsOneWidget);
  });
}

class _StatsBridge implements CoreBridge {
  @override
  Future<WeeklyStats> stats({int days = 7}) async => WeeklyStats.fromMap({
    'perDay': [
      {'day': '2026-10-11', 'count': 12},
    ],
    'perApp': [
      {'package': 'com.whatsapp', 'count': 30},
      {'package': 'org.telegram.messenger', 'count': 12},
    ],
    'top': [
      {
        'key': 'com.whatsapp|Ali',
        'title': 'Ali Veli',
        'package': 'com.whatsapp',
        'isGroup': false,
        'count': 20,
      },
    ],
    'busiestHour': 21,
    'incoming': 30,
    'outgoing': 12,
    'people': 5,
    'deleted': 2,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
