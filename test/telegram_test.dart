import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/telegram.dart';
import 'package:mesaj_merkezi/screens/telegram_screen.dart';

class _FakeBridge implements CoreBridge {
  _FakeBridge(this.status);

  TelegramStatus status;
  final events = StreamController<TelegramStatus>.broadcast();
  final submitted = <(TelegramState, String)>[];
  String? nextError;
  int connects = 0;

  @override
  Stream<TelegramStatus> get telegramChanges => events.stream;

  @override
  Future<TelegramStatus> telegramStatus() async => status;

  @override
  Future<void> telegramConnect() async => connects++;

  @override
  Future<String?> telegramSubmit(TelegramState state, String value) async {
    submitted.add((state, value));
    return nextError;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TelegramStatus _status(
  TelegramState state, {
  bool configured = true,
  bool enabled = true,
  String? hint,
}) => TelegramStatus(
  configured: configured,
  enabled: enabled,
  state: state,
  hint: hint,
);

void main() {
  group('TelegramState.fromWire', () {
    test('Kotlin enum adlarını çevirir', () {
      expect(TelegramState.fromWire('WAIT_PHONE'), TelegramState.waitPhone);
      expect(
        TelegramState.fromWire('WAIT_EMAIL_CODE'),
        TelegramState.waitEmailCode,
      );
      expect(TelegramState.fromWire('READY'), TelegramState.ready);
      expect(TelegramState.fromWire('LOGGING_OUT'), TelegramState.loggingOut);
    });

    test('bilinmeyen durum desteklenmiyor sayılır', () {
      expect(TelegramState.fromWire('YENI_DURUM'), TelegramState.unsupported);
    });

    test('her Kotlin durumunun Dart karşılığı var', () {
      // TelegramClient.State ile aynı sırada; biri eklenirse ikisi birlikte güncellenmeli.
      const kotlin = [
        'UNCONFIGURED',
        'STOPPED',
        'STARTING',
        'WAIT_PHONE',
        'WAIT_CODE',
        'WAIT_EMAIL_CODE',
        'WAIT_PASSWORD',
        'READY',
        'LOGGING_OUT',
        'UNSUPPORTED',
      ];
      expect(kotlin.map(TelegramState.fromWire).toList(), TelegramState.values);
    });
  });

  test('isTelegramKey', () {
    expect(isTelegramKey('tg|-100123'), isTrue);
    expect(isTelegramKey('org.telegram.messenger|Ali'), isFalse);
  });

  Future<_FakeBridge> pump(WidgetTester tester, TelegramStatus status) async {
    final bridge = _FakeBridge(status);
    await tester.pumpWidget(MaterialApp(home: TelegramScreen(bridge: bridge)));
    await tester.pump();
    return bridge;
  }

  testWidgets('kimlik yoksa kurulum açıklaması gösterilir', (tester) async {
    await pump(
      tester,
      _status(TelegramState.unconfigured, configured: false, enabled: false),
    );
    expect(find.textContaining('my.telegram.org'), findsOneWidget);
    expect(find.text('Telegram\'a bağlan'), findsNothing);
  });

  testWidgets('kapalıyken bağlan düğmesi bağlantıyı açar', (tester) async {
    final bridge = await pump(
      tester,
      _status(TelegramState.stopped, enabled: false),
    );
    expect(find.textContaining('Okundu bilgisi gönderilmez'), findsOneWidget);
    await tester.tap(find.text('Telegram\'a bağlan'));
    await tester.pump();
    expect(bridge.connects, 1);
  });

  testWidgets('telefon adımı numarayı gönderir', (tester) async {
    final bridge = await pump(tester, _status(TelegramState.waitPhone));
    await tester.enterText(find.byType(TextField), ' +905551112233 ');
    await tester.tap(find.text('Devam'));
    await tester.pump();
    expect(bridge.submitted, [(TelegramState.waitPhone, '+905551112233')]);
  });

  testWidgets('hata alan altında gösterilir', (tester) async {
    final bridge = await pump(tester, _status(TelegramState.waitCode));
    bridge.nextError = 'Kod hatalı.';
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Devam'));
    await tester.pump();
    expect(find.text('Kod hatalı.'), findsOneWidget);
  });

  testWidgets('sonraki adıma geçince girdi ve hata temizlenir', (tester) async {
    final bridge = await pump(
      tester,
      _status(TelegramState.waitCode, hint: 'Kod SMS ile gönderildi.'),
    );
    expect(find.text('Kod SMS ile gönderildi.'), findsOneWidget);
    bridge.nextError = 'Kod hatalı.';
    await tester.enterText(find.byType(TextField), '111');
    await tester.tap(find.text('Devam'));
    await tester.pump();

    bridge.events.add(
      _status(TelegramState.waitPassword, hint: 'Şifre ipucu: kedi'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Kod hatalı.'), findsNothing);
    expect(find.text('Şifre ipucu: kedi'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(field.obscureText, isTrue);
  });

  testWidgets('bağlıyken çıkış düğmesi var', (tester) async {
    await pump(tester, _status(TelegramState.ready));
    expect(find.text('Çıkış yap'), findsOneWidget);
    expect(find.textContaining('hesabınız bağlı'), findsOneWidget);
  });
}
