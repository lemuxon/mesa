import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge(this.current);

  AppSettings current;
  final updates = <AppSettings>[];
  int permissionRequests = 0;
  bool pinSupported = false;
  int pinRequests = 0;

  @override
  Future<bool> pinWidget() async {
    pinRequests++;
    return pinSupported;
  }

  @override
  Future<AppSettings> settings() async => current;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    updates.add(settings);
    current = settings;
  }

  @override
  Future<void> requestNotificationPermission() async => permissionRequests++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AppSettings', () {
    test('harita dönüşümü gidip gelir', () {
      const s = AppSettings(
        disabledPackages: {'com.whatsapp'},
        hideTelegramChannels: true,
        retentionDays: 30,
        importantNotifications: false,
        keepSourcePackages: {'com.whatsapp'},
      );
      final back = AppSettings.fromMap(s.toMap());
      expect(back.keepSourcePackages, {'com.whatsapp'});
      expect(back.disabledPackages, {'com.whatsapp'});
      expect(back.hideTelegramChannels, isTrue);
      expect(back.retentionDays, 30);
      expect(back.importantNotifications, isFalse);
    });

    test('eksik alanlar varsayılana düşer', () {
      final s = AppSettings.fromMap(const {});
      expect(s.disabledPackages, isEmpty);
      expect(s.retentionDays, 0);
      expect(s.importantNotifications, isTrue);
    });
  });

  group('LocalPrefs', () {
    test('hazır yanıtlar varsayılan listeyle başlar ve kaydedilir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefs.load();
      expect(prefs.quickReplies, LocalPrefs.defaultQuickReplies);
      expect(prefs.lockEnabled, isFalse);

      await prefs.setQuickReplies(['Geliyorum']);
      await prefs.setLockEnabled(true);
      final reloaded = await LocalPrefs.load();
      expect(reloaded.quickReplies, ['Geliyorum']);
      expect(reloaded.lockEnabled, isTrue);
    });
  });

  group('SettingsScreen', () {
    // Ayarlar listesi tembel oluşturulur: aşağıdaki satırlar kaydırılınca var olur.
    Future<void> reveal(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    Future<_FakeBridge> pump(
      WidgetTester tester, [
      AppSettings settings = const AppSettings(),
    ]) async {
      final bridge = _FakeBridge(settings);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(bridge: bridge)),
      );
      await tester.pumpAndSettle();
      return bridge;
    }

    testWidgets('uygulama kapatılınca tüm paketleri devre dışı kalır', (
      tester,
    ) async {
      final bridge = await pump(tester);
      final telegram = find.widgetWithText(SwitchListTile, 'Telegram');
      await reveal(tester, telegram);
      await tester.tap(telegram);
      await tester.pumpAndSettle();
      expect(
        bridge.updates.last.disabledPackages,
        containsAll(['org.telegram.messenger', 'org.telegram.messenger.web']),
      );
    });

    testWidgets(
      'kendi bildirimi kalan uygulamalar birleşik bildirimde seçilir',
      (tester) async {
        final off = await pump(tester);
        expect(find.text('Kendi bildirimi de kalsın'), findsNothing);
        expect(off.updates, isEmpty);

        // Aynı ağaç yeniden kurulursa ekranın durumu (eski ayarlar) korunur.
        await tester.pumpWidget(const SizedBox());
        final bridge = await pump(
          tester,
          const AppSettings(unifiedNotifications: true),
        );
        await tester.tap(find.text('Kendi bildirimi de kalsın'));
        await tester.pumpAndSettle();
        final whatsapp = find.widgetWithText(CheckboxListTile, 'WhatsApp');
        expect(tester.widget<CheckboxListTile>(whatsapp).value, isFalse);
        await tester.tap(whatsapp);
        await tester.pumpAndSettle();

        expect(
          bridge.updates.last.keepSourcePackages,
          contains('com.whatsapp'),
        );
        expect(bridge.updates.last.unifiedNotifications, isTrue);
        expect(tester.widget<CheckboxListTile>(whatsapp).value, isTrue);
        expect(find.widgetWithText(CheckboxListTile, 'Telegram'), findsNothing);
      },
    );

    testWidgets('ana ekran bileşeni: destek yoksa nasıl ekleneceği yazılır', (
      tester,
    ) async {
      final bridge = await pump(tester);
      final add = find.widgetWithText(FilledButton, 'Ekle');
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(bridge.pinRequests, 1);
      expect(find.textContaining('Bileşenler (Widget)'), findsOneWidget);
    });

    testWidgets('ana ekran bileşeni: destek varsa sistem penceresi açılır', (
      tester,
    ) async {
      final bridge = await pump(tester)
        ..pinSupported = true;
      final add = find.widgetWithText(FilledButton, 'Ekle');
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(bridge.pinRequests, 1);
      expect(find.textContaining('Bileşenler (Widget)'), findsNothing);
    });

    testWidgets('saklama süresini kısaltmak onay ister', (tester) async {
      final bridge = await pump(tester);
      final dropdown = find.byType(DropdownButton<int>);
      await reveal(tester, dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 gün').last);
      await tester.pumpAndSettle();
      expect(find.text('Eski mesajlar silinsin mi?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(bridge.updates, isEmpty);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 gün').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(bridge.updates.single.retentionDays, 30);
    });

    testWidgets('eski kopya başka yerden açılan ayarı geri kapatmaz', (
      tester,
    ) async {
      // 2026-10-10 hatası: ayarlar sekmesi açılışta okuduğu kopyayı tutuyor,
      // gelen kutusundaki karttan açılan birleşik bildirim burada başka bir
      // ayar değişince geri kapanıyordu.
      final bridge = await pump(tester);
      bridge.current = bridge.current.copyWith(unifiedNotifications: true);

      final tile = find.widgetWithText(
        SwitchListTile,
        'Önemli mesajlarda bildirim',
      );
      await reveal(tester, tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(bridge.updates.single.importantNotifications, isFalse);
      expect(bridge.updates.single.unifiedNotifications, isTrue);
    });

    testWidgets('önemli bildirimi açınca izin istenir', (tester) async {
      final bridge = await pump(
        tester,
        const AppSettings(importantNotifications: false),
      );
      final tile = find.widgetWithText(
        SwitchListTile,
        'Önemli mesajlarda bildirim',
      );
      await reveal(tester, tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(bridge.permissionRequests, 1);
      expect(bridge.updates.single.importantNotifications, isTrue);
    });
  });
}
