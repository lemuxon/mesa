import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/smart_actions.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';

void main() {
  // Çarşamba 25 Kasım 2026, 10:00
  final now = DateTime(2026, 11, 25, 10);

  List<SmartAction> detect(String text, {DateTime? sentAt}) =>
      findSmartActions(text, sentAt: sentAt ?? now, now: now);

  SmartAction? only(String text, SmartKind kind, {DateTime? sentAt}) {
    final found = detect(text, sentAt: sentAt).where((a) => a.kind == kind);
    return found.isEmpty ? null : found.single;
  }

  group('doğrulama kodu', () {
    test('kod sözcüğünün yanındaki sayı', () {
      expect(
        only(
          'Doğrulama kodunuz: 482913. Kimseyle paylaşmayın.',
          SmartKind.code,
        )?.value,
        '482913',
      );
      expect(
        only(
          'G-123456 is your Google verification code.',
          SmartKind.code,
        )?.value,
        '123456',
      );
      expect(only('Şifreniz 123 456', SmartKind.code)?.value, '123456');
    });

    test('kod sözcüğü yoksa ya da sayı yılsa önerilmez', () {
      expect(only('Saat 482913 gibi bir sayı', SmartKind.code), isNull);
      expect(only('Kod 2026 yılında değişti', SmartKind.code), isNull);
    });
  });

  group('telefon, IBAN, e-posta, bağlantı', () {
    test('Türkiye numaraları uluslararası biçime çevrilir', () {
      expect(
        only('Beni ara 0532 123 45 67', SmartKind.phone)?.value,
        '+905321234567',
      );
      expect(
        only('Numaram +90 555 444 33 22', SmartKind.phone)?.value,
        '+905554443322',
      );
      expect(
        only('Ofis: 0212 345 67 89', SmartKind.phone)?.value,
        '+902123456789',
      );
    });

    test('IBAN yalnızca denetim basamağı tutarsa', () {
      expect(
        only(
          'IBAN: TR33 0006 1005 1978 6457 8413 26 Ali Veli',
          SmartKind.iban,
        )?.value,
        'TR330006100519786457841326',
      );
      expect(
        only('IBAN TR12 3456 7890 1234 5678 9012 34', SmartKind.iban),
        isNull,
      );
      expect(isValidIban('TR330006100519786457841326'), isTrue);
      expect(isValidIban('TR330006100519786457841327'), isFalse);
    });

    test('e-posta ve bağlantılar', () {
      expect(
        only('mail: ali.veli@example.com', SmartKind.email)?.value,
        'ali.veli@example.com',
      );
      expect(
        only('Şuna bak www.ornek.com.tr/sayfa.', SmartKind.link)?.value,
        'https://www.ornek.com.tr/sayfa',
      );
      expect(
        only('Konum: https://maps.app.goo.gl/AbCd123', SmartKind.map)?.value,
        'https://maps.app.goo.gl/AbCd123',
      );
    });

    test('adres, alt satırdaki ilçe/il ile', () {
      expect(
        only(
          'Atatürk Mah. Gül Sok. No:5 D:3\nKadıköy/İstanbul',
          SmartKind.address,
        )?.value,
        'Atatürk Mah. Gül Sok. No:5 D:3 Kadıköy/İstanbul',
      );
      expect(only('Bu akşam sokakta yürüdük', SmartKind.address), isNull);
    });
  });

  group('tarih ve saat', () {
    DateTime? when(String text, {DateTime? sentAt}) =>
        only(text, SmartKind.when, sentAt: sentAt)?.when;

    test('göreli günler ve saatler', () {
      expect(when('Yarın 15:00 toplantı var'), DateTime(2026, 11, 26, 15));
      expect(when('akşam 8 gibi geliyorum'), DateTime(2026, 11, 25, 20));
      expect(when('haftaya salı 10:30'), DateTime(2026, 12, 1, 10, 30));
      expect(when('tomorrow at 5pm'), DateTime(2026, 11, 26, 17));
    });

    test('"yarın" mesajın gönderildiği güne göredir', () {
      // Dün yazılan "yarın 15:00" bugündür.
      expect(
        when('yarın 15:00', sentAt: DateTime(2026, 11, 24, 20)),
        DateTime(2026, 11, 25, 15),
      );
    });

    test('tarihler', () {
      expect(
        when("25 Kasım 2026 saat 14.30'da randevun var"),
        DateTime(2026, 11, 25, 14, 30),
      );
      final day = only('01.12.2026 tarihinde teslim', SmartKind.when)!;
      expect(day.when, DateTime(2026, 12, 1));
      expect(day.allDay, isTrue);
      expect(
        only('Cuma görüşürüz', SmartKind.when)?.when,
        DateTime(2026, 11, 27),
      );
    });

    test('saat sabahsa ve geçtiyse akşam sayılır', () {
      expect(when("Saat 9'da ararım"), DateTime(2026, 11, 25, 21));
    });

    test('geçmiş, belirsiz ya da başka anlamdaki ifadeler önerilmez', () {
      expect(when('Bugün 09:00 da'), isNull);
      expect(when('Pazara gidiyorum, bir şey ister misin?'), isNull);
      expect(when('Fiyat 12.50 TL'), isNull);
      expect(when('Selam nasılsın'), isNull);
      expect(
        only('Pazar günü kahvaltı?', SmartKind.when)?.when,
        DateTime(2026, 11, 29),
      );
    });
  });

  testWidgets('düğmeler: tarih için iki düğme, dokununca doğru iş', (
    tester,
  ) async {
    final taps = <String>[];
    final actions = findSmartActions(
      'Kodunuz 482913. Yarın 15:00 toplantı, ara: 0532 123 45 67',
      sentAt: now,
      now: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartChips(
            actions: actions,
            mine: false,
            onTap: (a, remind) =>
                taps.add('${a.kind.name}${remind ? '+hatırlat' : ''}'),
          ),
        ),
      ),
    );
    expect(find.text('Kodu kopyala'), findsOneWidget);
    expect(find.text('Telefonla ara'), findsOneWidget);
    expect(find.text('Takvime ekle'), findsOneWidget);
    expect(find.text('Hatırlat'), findsOneWidget);
    await tester.tap(find.text('Kodu kopyala'));
    await tester.tap(find.text('Hatırlat'));
    await tester.tap(find.text('Takvime ekle'));
    expect(taps, ['code', 'when+hatırlat', 'when']);
  });
}
