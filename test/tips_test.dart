import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/tips.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalPrefs> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return LocalPrefs.load();
  }

  test('ipuçları sırayla, günde en fazla biri', () async {
    final p = await prefs();
    final day1 = DateTime(2026, 10, 11, 9);
    expect(tipForToday(p, day1)?.text, tips[0].text);

    await p.advanceTip(day1);
    // Aynı gün ikincisi gösterilmez.
    expect(tipForToday(p, day1.add(const Duration(hours: 5))), isNull);
    // Ertesi gün sıradaki.
    expect(
      tipForToday(p, day1.add(const Duration(days: 1)))?.text,
      tips[1].text,
    );
  });

  test('hepsi görülünce ipucu kalmaz', () async {
    final p = await prefs();
    var day = DateTime(2026, 10, 11);
    for (var i = 0; i < tips.length; i++) {
      await p.advanceTip(day);
      day = day.add(const Duration(days: 1));
    }
    expect(tipForToday(p, day.add(const Duration(days: 3))), isNull);
  });

  testWidgets('"Anladım" ipucunu kapatır', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TipCard(tip: tips.first, onDone: () => done++),
        ),
      ),
    );
    expect(find.text('Günün ipucu'), findsOneWidget);
    expect(find.textContaining('basılı tutun'), findsOneWidget);
    await tester.tap(find.text('Anladım'));
    expect(done, 1);
  });
}
