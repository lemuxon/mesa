import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/app_scope.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/lock.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:mesaj_merkezi/screens/setup_checklist.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge(this.current);

  AppSettings current;
  final calls = <String>[];

  @override
  Future<AppSettings> settings() async => current;
  @override
  Future<void> updateSettings(AppSettings settings) async {
    calls.add('update');
    current = settings;
  }

  @override
  Future<void> requestNotificationPermission() async => calls.add('permission');
  @override
  Future<void> openBatterySettings() async => calls.add('battery');
  @override
  Future<void> openAutostartSettings() async => calls.add('autostart');

  // Sohbet ekranı.
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoAuth implements Authenticator {
  @override
  Future<bool> authenticate(String reason) async => true;
  @override
  Future<bool> isAvailable() async => true;
}

const _allGood = SystemHealth(
  listenerEnabled: true,
  listenerConnected: true,
  notificationsAllowed: true,
  batteryUnrestricted: true,
  micAllowed: true,
  xiaomi: false,
);

SystemHealth _health({bool battery = true, bool xiaomi = false}) =>
    SystemHealth(
      listenerEnabled: true,
      listenerConnected: true,
      notificationsAllowed: true,
      batteryUnrestricted: battery,
      micAllowed: true,
      xiaomi: xiaomi,
    );

Future<LocalPrefs> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return LocalPrefs.load();
}

void main() {
  Future<(_FakeBridge, LocalPrefs)> pump(
    WidgetTester tester, {
    required SystemHealth health,
    required AppSettings settings,
    bool usesWhatsApp = false,
  }) async {
    final prefs = await _prefs();
    final bridge = _FakeBridge(settings);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SetupChecklist(
              bridge: bridge,
              prefs: prefs,
              health: health,
              settings: settings,
              usesWhatsApp: usesWhatsApp,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (bridge, prefs);
  }

  testWidgets('eksik adımlar ilerlemeyle; birleşik bildirim tek dokunuşla', (
    tester,
  ) async {
    final (bridge, _) = await pump(
      tester,
      health: _health(battery: false),
      settings: const AppSettings(),
    );
    expect(find.text('Kurulumu tamamla · 1/3'), findsOneWidget);
    // Yalnızca sıradaki adım; diğerleri "1 adım daha" ile açılır.
    expect(find.text('Birleşik bildirimler'), findsOneWidget);
    expect(find.text('Pil kısıtlamasını kaldır'), findsNothing);
    await tester.tap(find.text('1 adım daha'));
    await tester.pumpAndSettle();
    expect(find.text('Pil kısıtlamasını kaldır'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Aç').first);
    await tester.pumpAndSettle();
    expect(bridge.current.unifiedNotifications, isTrue);
    expect(bridge.calls, contains('permission'));
  });

  testWidgets('Xiaomi\'de otomatik başlatma ve son uygulamalarda kilit', (
    tester,
  ) async {
    final (_, prefs) = await pump(
      tester,
      health: _health(xiaomi: true),
      settings: const AppSettings(unifiedNotifications: true),
    );
    expect(find.text('Otomatik başlatma'), findsOneWidget);
    await tester.tap(find.text('1 adım daha'));
    await tester.pumpAndSettle();
    expect(find.text('Son uygulamalarda kilitle'), findsOneWidget);
    await tester.tap(find.text('Yaptım'));
    await tester.pumpAndSettle();
    expect(prefs.recentsLockConfirmed, isTrue);
  });

  testWidgets('WhatsApp kullanılıyorsa doğrudan yanıt adımı', (tester) async {
    final (bridge, _) = await pump(
      tester,
      health: _allGood,
      settings: const AppSettings(unifiedNotifications: true),
      usesWhatsApp: true,
    );
    expect(find.text('WhatsApp\'a geçmeden yanıt'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Aç'));
    await tester.pumpAndSettle();
    expect(bridge.current.keepSourcePackages, contains('com.whatsapp'));
  });

  test('her şey tamamsa ya da ertelendiyse gösterilmez', () async {
    final prefs = await _prefs();
    SetupChecklist make(SystemHealth h) => SetupChecklist(
      bridge: _FakeBridge(const AppSettings()),
      prefs: prefs,
      health: h,
      settings: const AppSettings(unifiedNotifications: true),
      usesWhatsApp: false,
      onChanged: () {},
    );
    final now = DateTime(2026, 10, 11, 21);
    expect(make(_allGood).visible(now), isFalse);
    expect(make(_health(battery: false)).visible(now), isTrue);
    await prefs.snoozeSetup(now.add(const Duration(days: 3)));
    expect(make(_health(battery: false)).visible(now), isFalse);
    expect(
      make(_health(battery: false)).visible(now.add(const Duration(days: 4))),
      isTrue,
    );
  });

  testWidgets(
    'sohbette WhatsApp açılacakken "doğrudan gitsin" önerisi tek dokunuşla',
    (tester) async {
      final prefs = await _prefs();
      final bridge = _FakeBridge(const AppSettings(unifiedNotifications: true));
      await tester.pumpWidget(
        AppScope(
          prefs: prefs,
          authenticator: _NoAuth(),
          child: MaterialApp(
            home: ChatScreen(
              bridge: bridge,
              conversation: Conversation(
                key: 'com.whatsapp|Ayşe',
                packageName: 'com.whatsapp',
                title: 'Ayşe',
                isGroup: false,
                lastText: '',
                lastTime: DateTime(2026, 10, 11),
                unread: 0,
                canReply: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Şu an gönderince WhatsApp'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Aç'));
      await tester.pumpAndSettle();
      expect(bridge.current.keepSourcePackages, contains('com.whatsapp'));
      expect(find.textContaining('Şu an gönderince WhatsApp'), findsNothing);
    },
  );
}
