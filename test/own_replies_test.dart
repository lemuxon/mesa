import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/own_replies.dart';
import 'package:mesaj_merkezi/screens/settings_screen.dart';

class _FakeBridge implements CoreBridge {
  bool enabled = false;
  bool throws = false;
  int opens = 0;

  @override
  Future<bool> ownRepliesEnabled() async {
    if (throws) throw UnimplementedError();
    return enabled;
  }

  @override
  Future<void> openOwnRepliesSettings() async => opens++;

  @override
  Future<AppSettings> settings() async => const AppSettings();

  @override
  Future<SystemHealth> health() async => const SystemHealth(
    listenerEnabled: true,
    listenerConnected: true,
    notificationsAllowed: true,
    batteryUnrestricted: true,
    micAllowed: true,
    xiaomi: false,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('öneri açılır ve kapatılır', (tester) async {
    var enabled = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OwnRepliesNudge(
            onEnable: () => enabled++,
            onDismiss: () => dismissed++,
          ),
        ),
      ),
    );
    expect(
      find.text(
        'WhatsApp\'tan yazdığınız yanıtlar burada görünmüyor. Görünsün mü?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Aç'));
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect((enabled, dismissed), (1, 1));
  });

  testWidgets('açıklama onaylanınca erişilebilirlik ayarı açılır', (
    tester,
  ) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => enableOwnReplies(context, bridge),
            child: const Text('başlat'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('başlat'));
    await tester.pumpAndSettle();
    expect(find.text('WhatsApp\'ta yazdıklarınız da görünsün'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(bridge.opens, 0);

    await tester.tap(find.text('başlat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayarı aç'));
    await tester.pumpAndSettle();
    expect(bridge.opens, 1);
  });

  test('durum okunamazsa açık sayılır (öneri boşuna çıkmasın)', () async {
    final bridge = _FakeBridge()..throws = true;
    expect(await ownRepliesEnabled(bridge), isTrue);
    bridge.throws = false;
    expect(await ownRepliesEnabled(bridge), isFalse);
  });

  testWidgets('Ayarlar: anahtar durumu gösterir ve ayarı açar', (tester) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(bridge: bridge)));
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(
      SwitchListTile,
      'WhatsApp\'ta yazdıklarım',
    );
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayarı aç'));
    await tester.pumpAndSettle();
    expect(bridge.opens, 1);
  });
}
