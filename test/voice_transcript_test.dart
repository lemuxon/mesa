import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  testWidgets('çevrilmemiş sesli mesajda "Yazıya çevir"', (tester) async {
    var taps = 0;
    await pump(
      tester,
      VoiceTranscript(
        text: null,
        busy: false,
        mine: false,
        onTranscribe: () => taps++,
      ),
    );
    await tester.tap(find.text('Yazıya çevir'));
    expect(taps, 1);
  });

  testWidgets('çevrilirken düğme bekler', (tester) async {
    var taps = 0;
    await pump(
      tester,
      VoiceTranscript(
        text: null,
        busy: true,
        mine: false,
        onTranscribe: () => taps++,
      ),
    );
    expect(find.text('Yazıya çevriliyor…'), findsOneWidget);
    await tester.tap(find.text('Yazıya çevriliyor…'));
    expect(taps, 0);
  });

  testWidgets('çevrilmiş metin gösterilir', (tester) async {
    await pump(
      tester,
      const VoiceTranscript(
        text: 'Akşam yedide buluşalım',
        busy: false,
        mine: false,
        onTranscribe: _noop,
      ),
    );
    expect(find.text('Yazıya çevrildi'), findsOneWidget);
    expect(find.text('Akşam yedide buluşalım'), findsOneWidget);
    expect(find.text('Yazıya çevir'), findsNothing);
  });

  test('mesaj haritasından yazı okunur', () {
    final m = Message.fromMap({
      'id': '1',
      'sender': 'Ayşe',
      'text': '🎤 Sesli mesaj (0:05)',
      'time': 0,
      'outgoing': false,
      'transcript': 'Geliyorum',
    });
    expect(m.isVoice, isTrue);
    expect(m.transcript, 'Geliyorum');
  });
}

void _noop() {}
