import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/inbox_screen.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge(this.status);

  ListenerStatus status;
  final statusEvents = StreamController<bool>.broadcast();
  int rebinds = 0;
  int autostartOpens = 0;

  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Stream<bool> get listenerStatusChanges => statusEvents.stream;

  @override
  Future<ListenerStatus> listenerStatus() async => status;

  @override
  Future<List<Conversation>> conversations({bool archived = false}) async =>
      const [];

  @override
  Future<int> archivedCount() async => 0;

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
  Future<void> rebindListener() async => rebinds++;

  @override
  Future<void> openAutostartSettings() async => autostartOpens++;

  @override
  Future<void> openAppSettings() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _title = 'Bildirim servisi çalışmıyor';

void main() {
  Future<_FakeBridge> pump(WidgetTester tester, ListenerStatus status) async {
    final bridge = _FakeBridge(status);
    await tester.pumpWidget(MaterialApp(home: InboxScreen(bridge: bridge)));
    await tester.pump();
    return bridge;
  }

  testWidgets('servis bağlıysa uyarı yok', (tester) async {
    await pump(tester, const ListenerStatus(enabled: true, connected: true));
    await tester.pump(serviceWarningDelay * 2);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('bağlı değilse uyarı gecikmeyle çıkar', (tester) async {
    await pump(
      tester,
      const ListenerStatus(enabled: true, connected: false, xiaomi: true),
    );
    expect(find.text(_title), findsNothing);
    await tester.pump(serviceWarningDelay);
    expect(find.text(_title), findsOneWidget);
    expect(find.text('Otomatik başlatma'), findsOneWidget);
  });

  testWidgets('gecikme içinde bağlanırsa uyarı hiç çıkmaz', (tester) async {
    final bridge = await pump(
      tester,
      const ListenerStatus(enabled: true, connected: false),
    );
    bridge.statusEvents.add(true);
    await tester.pump(serviceWarningDelay * 2);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('uyarı varken servis bağlanınca kalkar', (tester) async {
    final bridge = await pump(
      tester,
      const ListenerStatus(enabled: true, connected: false),
    );
    await tester.pump(serviceWarningDelay);
    expect(find.text(_title), findsOneWidget);
    bridge.statusEvents.add(true);
    await tester.pump(); // olay teslim edilir
    await tester.pump(); // setState karesi
    expect(find.text(_title), findsNothing);
  });

  testWidgets('düğmeler doğru eylemleri çağırır', (tester) async {
    final bridge = await pump(
      tester,
      const ListenerStatus(enabled: true, connected: false, xiaomi: true),
    );
    await tester.pump(serviceWarningDelay);
    await tester.tap(find.text('Otomatik başlatma'));
    await tester.tap(find.text('Yeniden bağla'));
    await tester.pump(const Duration(seconds: 3));
    expect(bridge.autostartOpens, 1);
    expect(bridge.rebinds, 1);
  });

  testWidgets('Xiaomi değilse otomatik başlatma düğmesi yok', (tester) async {
    await pump(tester, const ListenerStatus(enabled: true, connected: false));
    await tester.pump(serviceWarningDelay);
    expect(find.text(_title), findsOneWidget);
    expect(find.text('Otomatik başlatma'), findsNothing);
  });

  testWidgets('izin yoksa izin ekranı gösterilir, uyarı değil', (tester) async {
    await pump(tester, const ListenerStatus(enabled: false, connected: false));
    await tester.pump(serviceWarningDelay * 2);
    expect(find.text('Tüm mesajların tek yerde'), findsOneWidget);
    expect(find.text(_title), findsNothing);
  });
}
