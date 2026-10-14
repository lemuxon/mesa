import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:mesaj_merkezi/screens/welcome_screen.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  tearDown(() => debugSetLanguage('tr'));

  testWidgets('kısıtlanmış ayar yoksa ipucu görünmez', (tester) async {
    await tester.pumpWidget(_app(WelcomeScreen(onGrant: () {})));

    // Listenin sonuna in: ipucu varsa erişim düğmesinin hemen altındadır.
    await tester.scrollUntilVisible(find.text('Bildirim erişimini aç'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('İzin verilemiyor mu?'), findsNothing);
  });

  testWidgets('mağaza dışı kurulumda ipucu uygulama bilgilerini açar', (
    tester,
  ) async {
    var appInfo = 0;
    await tester.pumpWidget(
      _app(
        WelcomeScreen(
          onGrant: () {},
          restrictedSettings: true,
          onAppInfo: () => appInfo++,
        ),
      ),
    );

    final button = find.text('Uygulama bilgileri');
    await tester.scrollUntilVisible(button, 200);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(find.text('İzin verilemiyor mu?'), findsOneWidget);
    await tester.tap(button);
    expect(appInfo, 1);
  });

  testWidgets('ipucu İngilizce de görünür', (tester) async {
    debugSetLanguage('en');
    await tester.pumpWidget(
      _app(WelcomeScreen(onGrant: () {}, restrictedSettings: true)),
    );

    final button = find.text('App info');
    await tester.scrollUntilVisible(button, 200);
    expect(find.text("Can't turn it on?"), findsOneWidget);
  });

  test('durum haritası kısıtlanmış ayarı taşır', () {
    final status = ListenerStatus.fromMap({
      'enabled': false,
      'connected': false,
      'restrictedSettings': true,
    });
    expect(status.restrictedSettings, isTrue);
    expect(status.withConnected(true).restrictedSettings, isTrue);
    expect(
      ListenerStatus.fromMap({
        'enabled': false,
        'connected': false,
      }).restrictedSettings,
      isFalse,
    );
  });
}
