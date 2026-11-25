import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/focus.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/screens/focus_screen.dart';

class _FakeBridge implements CoreBridge {
  FocusStatus focus = const FocusStatus(active: false, unified: true);
  final calls = <String>[];

  final conversations_ = [
    Conversation(
      key: 'com.whatsapp|Anne',
      packageName: 'com.whatsapp',
      title: 'Anne',
      isGroup: false,
      lastText: 'Akşam gel',
      lastTime: DateTime(2026, 11, 25, 9),
      unread: 0,
      canReply: true,
    ),
  ];

  @override
  Future<FocusStatus> focusStatus() async => focus;

  @override
  Future<List<Conversation>> conversations({bool archived = false}) async =>
      archived ? const [] : conversations_;

  @override
  Future<FocusStatus> setFocusManual(int until) async {
    calls.add('manual:${until == FocusStatus.indefinite ? 'süresiz' : until}');
    focus = FocusStatus(
      active: until != 0,
      manualUntil: until == 0 ? null : until,
      vip: focus.vip,
      unified: true,
    );
    return focus;
  }

  @override
  Future<FocusStatus> setFocusVip(List<String> keys) async {
    calls.add('vip:${keys.join(',')}');
    focus = FocusStatus(
      active: focus.active,
      manualUntil: focus.manualUntil,
      vip: keys,
      unified: true,
    );
    return focus;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('süre seçenekleri', () {
    final now = DateTime(2026, 11, 25, 22, 30);
    expect(
      focusUntil('1h', now),
      DateTime(2026, 11, 25, 23, 30).millisecondsSinceEpoch,
    );
    expect(
      focusUntil('morning', now),
      DateTime(2026, 11, 26, 8).millisecondsSinceEpoch,
    );
    expect(
      focusUntil('morning', DateTime(2026, 11, 25, 6)),
      DateTime(2026, 11, 25, 8).millisecondsSinceEpoch,
    );
    expect(focusUntil('forever', now), FocusStatus.indefinite);
  });

  test('durum haritası okunur', () {
    final s = FocusStatus.fromMap({
      'active': true,
      'manualUntil': FocusStatus.indefinite,
      'scheduleOn': true,
      'scheduleFrom': 23 * 60,
      'scheduleTo': 7 * 60,
      'vip': ['a', 'b'],
      'silenced': 4,
    });
    expect(s.indefiniteManual, isTrue);
    expect(s.scheduleFrom, 23 * 60);
    expect(s.vip, ['a', 'b']);
    expect(s.silenced, 4);
  });

  testWidgets('odak açılır ve VIP eklenir', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bridge = _FakeBridge();
    await tester.pumpWidget(MaterialApp(home: FocusScreen(bridge: bridge)));
    await tester.pumpAndSettle();
    expect(find.text('Kapalı'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ben kapatana kadar'));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('manual:süresiz'));
    expect(find.text('Açık · siz kapatana kadar'), findsOneWidget);

    await tester.tap(find.text('VIP ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anne'));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('vip:com.whatsapp|Anne'));
    expect(find.text('Anne'), findsOneWidget);
  });
}
