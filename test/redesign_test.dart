import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/format.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:mesaj_merkezi/screens/inbox_screen.dart';
import 'package:mesaj_merkezi/screens/settings_screen.dart';
import 'package:mesaj_merkezi/ui/avatars.dart';

final _now = DateTime.now();

Message _msg(
  String id,
  String text, {
  DateTime? time,
  bool outgoing = false,
  String? sender = 'Ali',
  String? mediaPath,
  String? mediaKind,
  bool downloadable = false,
}) => Message(
  id: id,
  sender: outgoing ? null : sender,
  text: text,
  time: time ?? _now,
  outgoing: outgoing,
  mediaPath: mediaPath,
  mediaKind: mediaKind,
  downloadable: downloadable,
);

class _FakeBridge implements CoreBridge {
  _FakeBridge({
    this.messageList = const [],
    this.unified = false,
    this.mode = ReplyMode.direct,
  });

  final List<Message> messageList;
  bool unified;
  final ReplyMode mode;
  final opened = <String>[];
  final sentViaApp = <String>[];
  final replies = <String>[];
  final updates = <AppSettings>[];
  int permissionRequests = 0;

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
      const [];
  @override
  Future<int> archivedCount() async => 0;
  @override
  Future<AppSettings> settings() async =>
      AppSettings(unifiedNotifications: unified);
  @override
  Future<void> updateSettings(AppSettings settings) async {
    updates.add(settings);
    unified = settings.unifiedNotifications;
  }

  @override
  Future<void> requestNotificationPermission() async => permissionRequests++;
  @override
  Future<List<Message>> messages(String key) async => messageList;
  @override
  Future<bool> canReply(String key) async => mode == ReplyMode.direct;
  @override
  Future<ReplyMode> replyMode(Conversation c) async => mode;
  @override
  Future<bool> sendViaApp(Conversation c, String text) async {
    sentViaApp.add(text);
    return true;
  }

  @override
  Future<void> sendReply(String key, String text) async => replies.add(text);
  @override
  Future<void> markRead(String key) async {}
  @override
  Future<void> setActiveConversation(String? key) async {}
  @override
  Future<bool> openInSourceApp(Conversation c) async {
    opened.add(c.key);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('biçimlendirme', () {
    final now = DateTime(2026, 10, 10, 15); // cumartesi

    test('gün ayracı', () {
      expect(formatDayLabel(DateTime(2026, 10, 10, 1), now), 'Bugün');
      expect(formatDayLabel(DateTime(2026, 10, 9, 23), now), 'Dün');
      expect(formatDayLabel(DateTime(2026, 10, 6, 12), now), 'Salı');
      expect(formatDayLabel(DateTime(2026, 9, 1), now), '1 Eylül');
      expect(formatDayLabel(DateTime(2025, 12, 31), now), '31 Aralık 2025');
    });

    test('baş harfler', () {
      expect(initialsOf('Ali Veli'), 'AV');
      expect(initialsOf('aile'), 'A');
      expect(initialsOf('  çelik  hat  grubu '), 'ÇH');
      expect(initialsOf(''), '?');
    });
  });

  group('medya kararları', () {
    test('video ve GIF oynatılır', () {
      expect(_msg('1', '🎥 Video', mediaKind: 'video').isVideo, isTrue);
      expect(_msg('2', 'GIF', mediaKind: 'animation').isVideo, isTrue);
      expect(_msg('3', '📷 Fotoğraf', mediaKind: 'photo').isVideo, isFalse);
    });

    test('görseli gelmeyen medya kaynak uygulamada açılır', () {
      expect(_msg('1', '🎥 Video').mediaOnlyInSourceApp, isTrue);
      expect(
        _msg('2', '📷 Fotoğraf', mediaPath: '/x.jpg').mediaOnlyInSourceApp,
        isFalse,
      );
      expect(
        _msg('3', '🎥 Video', downloadable: true).mediaOnlyInSourceApp,
        isFalse,
      );
      expect(_msg('4', 'merhaba').mediaOnlyInSourceApp, isFalse);
    });

    test('indirilen medya türü', () {
      expect(const MediaFile(path: '/a', kind: 'video').isVideo, isTrue);
      expect(const MediaFile(path: '/a', kind: 'photo').isVideo, isFalse);
    });
  });

  group('sohbet ekranı', () {
    Future<_FakeBridge> pump(
      WidgetTester tester,
      List<Message> messages, {
      ReplyMode mode = ReplyMode.direct,
    }) async {
      final bridge = _FakeBridge(messageList: messages, mode: mode);
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            bridge: bridge,
            conversation: Conversation(
              key: 'com.whatsapp|Ali',
              packageName: 'com.whatsapp',
              title: 'Ali',
              isGroup: false,
              lastText: '',
              lastTime: _now,
              unread: 0,
              canReply: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return bridge;
    }

    testWidgets('gün ayraçları gösterilir', (tester) async {
      await pump(tester, [
        _msg('1', 'dünkü', time: _now.subtract(const Duration(days: 1))),
        _msg('2', 'bugünkü'),
      ]);
      expect(find.text('Dün'), findsOneWidget);
      expect(find.text('Bugün'), findsOneWidget);
    });

    testWidgets('WhatsApp videosu için kaynakta aç kartı', (tester) async {
      final bridge = await pump(tester, [_msg('1', '🎥 Video')]);
      final link = find.text("WhatsApp'ta aç");
      expect(link, findsOneWidget);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(bridge.opened, ['com.whatsapp|Ali']);
    });

    testWidgets('boş metinde mikrofon, yazınca gönder', (tester) async {
      final bridge = await pump(tester, [_msg('1', 'selam')]);
      expect(
        find.byTooltip('Sesli mesaj: dokunun ya da basılı tutun'),
        findsOneWidget,
      );
      expect(find.byTooltip('Fotoğraf, video, dosya'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'merhaba');
      await tester.pump();
      expect(
        find.byTooltip('Sesli mesaj: dokunun ya da basılı tutun'),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Gönder (basılı tutun: zamanla)'));
      await tester.pumpAndSettle();
      expect(bridge.replies, ['merhaba']);
    });

    testWidgets(
      'yanıt yolu yokken mesaj uygulamada hazır açılır (karşı taraf yazmadan)',
      (tester) async {
        final bridge = await pump(tester, [
          _msg('1', 'selam'),
        ], mode: ReplyMode.app);
        expect(find.textContaining('hazır açılır'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'nasılsın');
        await tester.pump();
        await tester.tap(find.byTooltip('Gönder (basılı tutun: zamanla)'));
        await tester.pumpAndSettle();
        expect(bridge.sentViaApp, ['nasılsın']);
        expect(bridge.replies, isEmpty);
      },
    );

    testWidgets('web servisinde yazma alanı yerine servis sayfası', (
      tester,
    ) async {
      await pump(tester, [_msg('1', 'selam')], mode: ReplyMode.web);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('sayfasında yanıtla'), findsOneWidget);
    });
  });

  group('birleşik bildirimler', () {
    testWidgets('gelen kutusundaki öneriden açılır', (tester) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
      await tester.pumpAndSettle();
      expect(find.text('Bildirimleri birleştir'), findsOneWidget);
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(bridge.permissionRequests, 1);
      expect(bridge.updates.single.unifiedNotifications, isTrue);
      expect(find.text('Bildirimleri birleştir'), findsNothing);
    });

    testWidgets('açıksa öneri gösterilmez', (tester) async {
      final bridge = _FakeBridge(unified: true);
      await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
      await tester.pumpAndSettle();
      expect(find.text('Bildirimleri birleştir'), findsNothing);
    });

    testWidgets('ayarlardaki anahtar izin ister ve kaydeder', (tester) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(bridge: bridge)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Birleşik bildirimler'),
      );
      await tester.pumpAndSettle();
      expect(bridge.permissionRequests, 1);
      expect(bridge.updates.single.unifiedNotifications, isTrue);
    });
  });
}
