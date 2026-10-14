import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/rules.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/rules_screen.dart';
import 'package:mesaj_merkezi/screens/settings_screen.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge({this.healthState});

  final SystemHealth? healthState;
  final saved = <Rule>[];
  int batteryOpened = 0;

  @override
  Future<SystemHealth> health() async => healthState!;
  @override
  Future<void> openBatterySettings() async => batteryOpened++;
  @override
  Future<AppSettings> settings() async => const AppSettings();
  @override
  Future<List<Rule>> rules() async => const [];
  @override
  Future<int> saveRule(Rule rule) async {
    saved.add(rule);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('sistem durumu eksik ayarı gösterir ve düzeltir', (tester) async {
    final bridge = _FakeBridge(
      healthState: const SystemHealth(
        listenerEnabled: true,
        listenerConnected: true,
        notificationsAllowed: true,
        batteryUnrestricted: false,
        micAllowed: false,
        xiaomi: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(bridge: bridge)));
    await tester.pumpAndSettle();

    expect(find.text('Sistem durumu · 1 ayar eksik'), findsOneWidget);
    expect(find.text('Mesajlar yakalanıyor'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Kaldır'));
    await tester.pumpAndSettle();
    expect(bridge.batteryOpened, 1);
  });

  testWidgets(
    'hazır kural düzenleyicide dolu açılır ve yeni kural olarak kaydedilir',
    (tester) async {
      final bridge = _FakeBridge();
      await tester.pumpWidget(MaterialApp(home: RulesScreen(bridge: bridge)));
      await tester.pumpAndSettle();

      expect(find.text('Hazır kurallar'), findsOneWidget);
      await tester.tap(find.text('Gece modu'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni kural'), findsOneWidget);
      expect(find.text('Gece otomatik yanıt'), findsOneWidget);
      await tester.ensureVisible(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final rule = bridge.saved.single;
      expect(rule.id, isNull);
      expect(rule.action, RuleAction.autoReply);
      expect(rule.activeFrom, 23 * 60);
      expect(rule.activeTo, 8 * 60);
    },
  );
}
