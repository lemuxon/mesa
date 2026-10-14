import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/lock.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/lock_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth implements Authenticator {
  bool result = true;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return result;
  }
}

void main() {
  const lockedText = 'Mesa kilitli';

  var clock = DateTime(2026, 10, 10, 12);

  Future<(_FakeAuth, LocalPrefs)> pump(
    WidgetTester tester, {
    required bool enabled,
    bool authResult = true,
    Future<bool> Function()? isNativeLocked,
    ValueChanged<bool>? onLockChanged,
  }) async {
    SharedPreferences.setMockInitialValues({'lock_enabled': enabled});
    final prefs = await LocalPrefs.load();
    final auth = _FakeAuth()..result = authResult;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => LockGate(
          prefs: prefs,
          authenticator: auth,
          relockAfter: const Duration(seconds: 30),
          now: () => clock,
          isNativeLocked: isNativeLocked,
          onLockChanged: onLockChanged,
          child: child!,
        ),
        home: const Scaffold(body: Text('gizli içerik')),
      ),
    );
    await tester.pumpAndSettle();
    return (auth, prefs);
  }

  void lifecycle(WidgetTester tester, AppLifecycleState state) =>
      tester.binding.handleAppLifecycleStateChanged(state);

  Future<void> background(WidgetTester tester, Duration duration) async {
    lifecycle(tester, AppLifecycleState.inactive);
    lifecycle(tester, AppLifecycleState.hidden);
    lifecycle(tester, AppLifecycleState.paused);
    clock = clock.add(duration);
    lifecycle(tester, AppLifecycleState.hidden);
    lifecycle(tester, AppLifecycleState.inactive);
    lifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  testWidgets('kilit kapalıysa doğrulama istenmez', (tester) async {
    final (auth, _) = await pump(tester, enabled: false);
    expect(auth.calls, 0);
    expect(find.text(lockedText), findsNothing);
  });

  testWidgets('açılışta doğrulanınca içerik görünür', (tester) async {
    final (auth, _) = await pump(tester, enabled: true);
    expect(auth.calls, 1);
    expect(find.text(lockedText), findsNothing);
  });

  testWidgets('doğrulama başarısızsa kilit ekranı kalır', (tester) async {
    final (auth, _) = await pump(tester, enabled: true, authResult: false);
    expect(find.text(lockedText), findsOneWidget);
    auth.result = true;
    await tester.tap(find.text('Kilidi aç'));
    await tester.pumpAndSettle();
    expect(find.text(lockedText), findsNothing);
  });

  testWidgets('uzun süre arka planda kalınca yeniden kilitlenir', (
    tester,
  ) async {
    final (auth, _) = await pump(tester, enabled: true);
    auth.result = false;
    await background(tester, const Duration(seconds: 31));
    expect(auth.calls, 2);
    expect(find.text(lockedText), findsOneWidget);
  });

  testWidgets('kısa süre arka planda kalınca kilitlenmez', (tester) async {
    final (auth, _) = await pump(tester, enabled: true);
    await background(tester, const Duration(seconds: 10));
    expect(auth.calls, 1);
    expect(find.text(lockedText), findsNothing);
  });

  testWidgets('web servisi ekranında açılan kilit yeniden sorulmaz', (
    tester,
  ) async {
    // Bildirimden açılan web servisi ekranında kimlik doğrulandı; gelen
    // kutusuna dönülünce ikinci kez sorulmamalı.
    final (auth, _) = await pump(
      tester,
      enabled: true,
      isNativeLocked: () async => false,
    );
    expect(auth.calls, 0);
    expect(find.text(lockedText), findsNothing);

    await background(tester, const Duration(seconds: 45));
    expect(auth.calls, 0);
    expect(find.text(lockedText), findsNothing);
  });

  testWidgets('yerel taraf kilitliyse doğrulanır ve açıldığı bildirilir', (
    tester,
  ) async {
    final changes = <bool>[];
    final (auth, _) = await pump(
      tester,
      enabled: true,
      isNativeLocked: () async => true,
      onLockChanged: changes.add,
    );
    expect(auth.calls, 1);
    expect(changes, [false]);

    auth.result = false;
    await background(tester, const Duration(seconds: 31));
    expect(auth.calls, 2);
    expect(find.text(lockedText), findsOneWidget);
    expect(changes, [false, true]);
  });
}
