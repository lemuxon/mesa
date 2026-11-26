import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/language_guess.dart';

void main() {
  group('Türkçe okuyana', () {
    test('İngilizce, Almanca, Fransızca mesajlar yabancı', () {
      expect(looksForeign('Are you coming tonight?', 'tr'), isTrue);
      expect(looksForeign('Can you send me the file please', 'tr'), isTrue);
      expect(looksForeign('Hallo, wie geht es dir? Bis morgen', 'tr'), isTrue);
      expect(looksForeign('Bonjour, ça va très bien merci', 'tr'), isTrue);
      expect(looksForeign('Ich bin gleich da', 'tr'), isTrue);
    });

    test('başka alfabe yabancı', () {
      expect(looksForeign('Привет, как дела? Увидимся завтра', 'tr'), isTrue);
      expect(looksForeign('مرحبا كيف حالك اليوم', 'tr'), isTrue);
      expect(looksForeign('今日は何をしていますか', 'tr'), isTrue);
    });

    test('bilinmeyen Latin harfli dil, alfabede olmayan harflerden', () {
      expect(looksForeign('Cześć, jak się masz? Dziękuję bardzo', 'tr'), isTrue);
    });

    test('Türkçe mesajlar (aksansız yazılmış olsa da) yabancı değil', () {
      expect(looksForeign('Yarın akşam geliyorum, sen de gel', 'tr'), isFalse);
      expect(looksForeign('yarin aksam geliyorum sen de gel', 'tr'), isFalse);
      expect(looksForeign('Abi yarin musait misin', 'tr'), isFalse);
      expect(looksForeign('Bu akşam maç var mı?', 'tr'), isFalse);
      expect(
        looksForeign('Toplantı linkini attım, check eder misin? Thanks', 'tr'),
        isFalse,
      );
      expect(
        looksForeign('Siparişiniz kargoya verildi. Takip no: 123', 'tr'),
        isFalse,
      );
    });

    test('kısa mesaj, ad, numara ve bağlantı için düğme yok', () {
      expect(looksForeign('ok', 'tr'), isFalse);
      expect(looksForeign('Hello', 'tr'), isFalse);
      expect(looksForeign('👍👍', 'tr'), isFalse);
      expect(looksForeign('John Smith', 'tr'), isFalse);
      expect(looksForeign('Ahmet Yılmaz 0532 123 45 67', 'tr'), isFalse);
      expect(
        looksForeign('https://www.example.com/some/path?x=1', 'tr'),
        isFalse,
      );
    });
  });

  test('başka arayüz dillerinde', () {
    expect(looksForeign('Merhaba nasılsın, akşam ne yapıyorsun?', 'en'), isTrue);
    expect(looksForeign('Hi! How are you doing today?', 'en'), isFalse);
    expect(looksForeign('Hola, ¿cómo estás? Mañana nos vemos', 'pt'), isTrue);
    expect(looksForeign('Olá, tudo bem? Amanhã eu vou aí', 'es'), isTrue);
    expect(looksForeign('Привет, как дела?', 'ru'), isFalse);
    // Ukraynaca: Rusçada olmayan і.
    expect(looksForeign('Привіт, як справи? Дякую, все добре', 'ru'), isTrue);
    expect(looksForeign('مرحبا كيف حالك', 'ar'), isFalse);
    // Farsça: Arapçada olmayan چ.
    expect(looksForeign('سلام، حال شما چطور است؟ ممنون', 'ar'), isTrue);
    expect(looksForeign('Hello my friend, see you tomorrow', 'ar'), isTrue);
  });

  test('Latin harfli metnin dili tahmin edilir; emin değilse null', () {
    expect(guessLatinLanguage('Are you coming tonight?'), 'en');
    expect(guessLatinLanguage('Hallo, wie geht es dir? Bis morgen'), 'de');
    expect(guessLatinLanguage('Yarın akşam geliyorum'), 'tr');
    expect(guessLatinLanguage('John Smith'), isNull);
    expect(guessLatinLanguage('Привет, как дела?'), isNull);
  });
}
