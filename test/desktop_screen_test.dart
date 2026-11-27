import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/screens/desktop_screen.dart';

class _FakeBridge implements CoreBridge {
  bool enabled = false;
  final revoked = <String>[];
  final sessions = <DesktopSession>[
    DesktopSession(
      id: 's1',
      name: 'Chrome · Windows',
      lastSeen: DateTime(2026, 11, 27, 9, 30),
    ),
  ];

  @override
  Future<DesktopStatus> desktopStatus() async => DesktopStatus(
    enabled: enabled,
    running: enabled,
    urls: enabled ? const ['https://192.168.1.23:8743'] : const [],
    sessions: [
      for (final s in sessions)
        if (!revoked.contains(s.id)) s,
    ],
  );

  @override
  Future<void> desktopSetEnabled(bool value) async => enabled = value;

  @override
  Future<void> desktopRevoke(String id) async => revoked.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('açılınca adres ve adımlar görünür, bağlantı kesilir', (
    tester,
  ) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(MaterialApp(home: DesktopScreen(bridge: bridge)));
    await tester.pumpAndSettle();

    expect(find.text('Kapalı'), findsOneWidget);
    expect(find.text('https://192.168.1.23:8743'), findsNothing);
    expect(find.text('Chrome · Windows'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(bridge.enabled, isTrue);
    expect(find.text('Açık; bilgisayar bağlanabilir'), findsOneWidget);
    expect(find.text('https://192.168.1.23:8743'), findsOneWidget);
    expect(
      find.text('Bilgisayarınız telefonla aynı Wi-Fi\'ye bağlı olsun.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.byTooltip('Bağlantıyı kes'), 200);
    await tester.tap(find.byTooltip('Bağlantıyı kes'));
    await tester.pumpAndSettle();
    expect(bridge.revoked, ['s1']);
    expect(find.text('Henüz bağlı bilgisayar yok'), findsOneWidget);
  });

  test('durum haritası okunur', () {
    final status = DesktopStatus.fromMap({
      'enabled': true,
      'running': true,
      'urls': ['https://10.0.0.5:8743'],
      'sessions': [
        {'id': 'a', 'name': 'Firefox · Linux', 'lastSeen': 1795000000000},
      ],
    });
    expect(status.enabled, isTrue);
    expect(status.urls.single, 'https://10.0.0.5:8743');
    expect(status.sessions.single.name, 'Firefox · Linux');
    expect(status.sessions.single.lastSeen.millisecondsSinceEpoch, 1795000000000);
  });
}
