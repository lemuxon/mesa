import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/rules.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/inbox_screen.dart';
import 'package:mesaj_merkezi/screens/rule_edit_screen.dart';
import 'package:mesaj_merkezi/screens/search_screen.dart';

Conversation _conversation({bool pinned = false}) => Conversation(
  key: 'com.whatsapp|Ali',
  packageName: 'com.whatsapp',
  title: 'Ali',
  isGroup: false,
  lastText: 'Selam',
  lastTime: DateTime(2026, 10, 10, 12),
  unread: 2,
  pinned: pinned,
  canReply: true,
);

class _FakeBridge implements CoreBridge {
  final calls = <String>[];
  final searches = <String>[];
  final saved = <Rule>[];
  List<Conversation> inbox = [_conversation()];

  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Stream<bool> get listenerStatusChanges => const Stream.empty();

  @override
  Future<ListenerStatus> listenerStatus() async =>
      const ListenerStatus(enabled: true, connected: true);

  @override
  Future<List<Conversation>> conversations({bool archived = false}) async =>
      archived ? const [] : inbox;

  @override
  Future<int> archivedCount() async => 3;

  @override
  Stream<String> get openRequests => const Stream.empty();

  @override
  Future<String?> takeLaunchConversation() async => null;

  @override
  Future<AppSettings> settings() async =>
      const AppSettings(unifiedNotifications: true);

  @override
  Future<void> setActiveConversation(String? key) async {}

  @override
  Future<void> setPinned(String key, bool value) async =>
      calls.add('pin:$key:$value');

  @override
  Future<void> setArchived(String key, bool value) async =>
      calls.add('archive:$key:$value');

  @override
  Future<void> markAllRead() async => calls.add('markAllRead');

  @override
  Future<List<SearchHit>> search(String query) async {
    searches.add(query);
    return [
      SearchHit(
        key: 'com.whatsapp|Ali',
        packageName: 'com.whatsapp',
        title: 'Ali',
        text: 'İstanbul’a vardım',
        time: DateTime(2026, 10, 9),
        sender: 'Ali',
      ),
    ];
  }

  @override
  Future<int> saveRule(Rule rule) async {
    saved.add(rule);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('gelen kutusu', () {
    Future<_FakeBridge> pump(WidgetTester tester) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
      await tester.pumpAndSettle();
      return bridge;
    }

    testWidgets('uzun basınca sabitlenir', (tester) async {
      final bridge = await pump(tester);
      await tester.longPress(find.text('Ali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sabitle'));
      await tester.pumpAndSettle();
      expect(bridge.calls, ['pin:com.whatsapp|Ali:true']);
    });

    testWidgets('uzun basınca arşivlenir', (tester) async {
      final bridge = await pump(tester);
      await tester.longPress(find.text('Ali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arşivle'));
      await tester.pumpAndSettle();
      expect(bridge.calls, ['archive:com.whatsapp|Ali:true']);
    });

    testWidgets('sabitli sohbette "Sabitlemeyi kaldır" çıkar', (tester) async {
      final bridge = _FakeBridge()..inbox = [_conversation(pinned: true)];
      await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      await tester.longPress(find.text('Ali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sabitlemeyi kaldır'));
      await tester.pumpAndSettle();
      expect(bridge.calls, ['pin:com.whatsapp|Ali:false']);
    });

    testWidgets('menüden tümünü okundu say ve arşiv sayısı', (tester) async {
      final bridge = await pump(tester);
      await tester.tap(find.byTooltip('Diğer'));
      await tester.pumpAndSettle();
      expect(find.text('Arşiv (3)'), findsOneWidget);
      await tester.tap(find.text('Tümünü okundu say'));
      await tester.pumpAndSettle();
      expect(bridge.calls, ['markAllRead']);
    });
  });

  group('arama', () {
    testWidgets('yazmayı bekler, iki harften kısa sorguda aramaz', (
      tester,
    ) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(MaterialApp(home: SearchScreen(bridge: bridge)));
      await tester.enterText(find.byType(TextField), 'i');
      await tester.pump(const Duration(milliseconds: 400));
      expect(bridge.searches, isEmpty);

      await tester.enterText(find.byType(TextField), 'ist');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'istanbul');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(bridge.searches, ['istanbul']);
      expect(find.textContaining('vardım'), findsOneWidget);
    });
  });

  group('kural zamanı', () {
    test('zaman özeti', () {
      const always = Rule(name: 'x', action: RuleAction.mute);
      expect(describeSchedule(always), isNull);
      const night = Rule(
        name: 'x',
        action: RuleAction.autoReply,
        activeFrom: 23 * 60,
        activeTo: 8 * 60,
        activeDays: 0x1f,
      );
      expect(describeSchedule(night), 'hafta içi 23:00–08:00');
      expect(
        describeSchedule(
          const Rule(name: 'x', action: RuleAction.mute, activeDays: 0x41),
        ),
        'Pzt, Paz',
      );
    });

    test('saat alanları harita dönüşümünde korunur', () {
      const r = Rule(
        name: 'x',
        action: RuleAction.mute,
        activeFrom: 60,
        activeTo: 120,
        activeDays: 0x60,
      );
      final back = Rule.fromMap({...r.toMap(), 'id': 1});
      expect(back.activeFrom, 60);
      expect(back.activeTo, 120);
      expect(back.activeDays, 0x60);
      expect(
        Rule.fromMap({...r.toMap(), 'id': 1}..remove('activeDays')).activeDays,
        Rule.allDays,
      );
    });

    testWidgets('düzenleyicide saat aralığı ve gün seçimi kaydedilir', (
      tester,
    ) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(
        MaterialApp(home: RuleEditScreen(bridge: bridge)),
      );
      await tester.tap(find.text('Sessize al'));
      await tester.pump();

      final timed = find.text('Yalnızca belirli saatlerde');
      await tester.ensureVisible(timed);
      await tester.pumpAndSettle();
      await tester.tap(timed);
      await tester.pumpAndSettle();
      expect(find.text('Başlangıç 23:00'), findsOneWidget);
      expect(find.textContaining('Gece yarısını aşar'), findsOneWidget);

      await tester.ensureVisible(find.text('Paz'));
      await tester.tap(find.text('Paz'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      final rule = bridge.saved.single;
      expect(rule.activeFrom, 23 * 60);
      expect(rule.activeTo, 8 * 60);
      expect(rule.activeDays, 0x3f); // pazar hariç
    });

    testWidgets('hiç gün seçilmezse kaydetmez', (tester) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(
        MaterialApp(home: RuleEditScreen(bridge: bridge)),
      );
      await tester.tap(find.text('Sessize al'));
      await tester.pump();
      for (final day in weekdayShort) {
        await tester.ensureVisible(find.text(day));
        await tester.tap(find.text(day));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(bridge.saved, isEmpty);
      expect(find.text('En az bir gün seçin.'), findsOneWidget);
    });
  });
}
