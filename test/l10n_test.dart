import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:mesaj_merkezi/l10n/stored_labels.dart';

/// lib/ altındaki tr('...') çağrılarının anahtarları (bitişik dizeler birleşir).
Set<String> _keysInCode() {
  final keys = <String>{};
  final call = RegExp(r'\btr\(\s*');
  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    final name = file.uri.pathSegments.last;
    if (file.path.contains('l10n') && name != 'stored_labels.dart') continue;
    final src = file.readAsStringSync();
    for (final m in call.allMatches(src)) {
      final key = _literals(src, m.end);
      if (key != null) keys.add(key);
    }
  }
  return keys;
}

/// [i]'den başlayan bitişik dize sabitlerinin değeri; sabit değilse null.
String? _literals(String src, int i) {
  final out = StringBuffer();
  var found = false;
  while (true) {
    while (i < src.length && ' \t\r\n'.contains(src[i])) {
      i++;
    }
    if (i >= src.length || (src[i] != "'" && src[i] != '"')) break;
    final q = src[i++];
    while (src[i] != q) {
      if (src[i] == r'\') {
        final c = src[i + 1];
        out.write(switch (c) {
          'n' => '\n',
          't' => '\t',
          _ => c,
        });
        i += 2;
      } else {
        if (src[i] == r'$') return null; // ara değer: anahtar sabit değil
        out.write(src[i++]);
      }
    }
    i++;
    found = true;
  }
  return found ? out.toString() : null;
}

/// Metindeki üst düzey yer tutucu adları ({ad} ya da {ad, plural, …}).
Set<String> _placeholders(String text) {
  final names = <String>{};
  var depth = 0;
  var start = -1;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '{') {
      if (depth == 0) start = i + 1;
      depth++;
    } else if (text[i] == '}') {
      depth--;
      if (depth == 0 && start >= 0) {
        names.add(text.substring(start, i).split(',').first.trim());
      }
    }
  }
  return names;
}

void main() {
  final keys = _keysInCode();

  test('kodda çevrilecek metin bulunur', () {
    expect(keys.length, greaterThan(500));
    expect(keys, contains('Ayarlar'));
  });

  for (final MapEntry(key: language, value: map) in translations.entries) {
    test('$language: her metnin çevirisi var, fazlası yok', () {
      final missing = keys.where((k) => !map.containsKey(k)).toList()..sort();
      final extra = map.keys.where((k) => !keys.contains(k)).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason: 'eksik ${missing.length}: ${missing.take(20)}',
      );
      expect(
        extra,
        isEmpty,
        reason: 'kullanılmayan ${extra.length}: ${extra.take(20)}',
      );
    });

    test('$language: yer tutucular korunmuş', () {
      final wrong = <String>[];
      for (final MapEntry(key: turkish, value: text) in map.entries) {
        if (!_placeholders(text).containsAll(_placeholders(turkish)) ||
            !_placeholders(turkish).containsAll(_placeholders(text))) {
          wrong.add(turkish);
        }
      }
      expect(wrong, isEmpty, reason: '${wrong.take(20)}');
    });
  }

  group('biçimlendirme', () {
    tearDown(() => debugSetLanguage('tr'));

    test('yer tutucu ve çoğul', () {
      const forms =
          '{count, plural, one{# message} other{# messages}} from {name}';
      expect(
        formatMessage(forms, {'count': 1, 'name': 'Ali'}, 'en'),
        '1 message from Ali',
      );
      expect(
        formatMessage(forms, {'count': 3, 'name': 'Ali'}, 'en'),
        '3 messages from Ali',
      );
    });

    test('Rusça ve Arapça çoğul kategorileri', () {
      expect(pluralCategory('ru', 1), 'one');
      expect(pluralCategory('ru', 3), 'few');
      expect(pluralCategory('ru', 11), 'many');
      expect(pluralCategory('ru', 21), 'one');
      expect(pluralCategory('ar', 0), 'zero');
      expect(pluralCategory('ar', 2), 'two');
      expect(pluralCategory('ar', 5), 'few');
      expect(pluralCategory('ar', 15), 'many');
    });

    test('desteklenmeyen telefon dili İngilizceye düşer', () {
      expect(resolveLanguage(null, 'ja'), 'en');
      expect(resolveLanguage(null, 'de'), 'de');
      expect(resolveLanguage('fr', 'de'), 'fr');
    });

    test('kayıttaki Türkçe medya etiketi seçili dilde gösterilir', () {
      debugSetLanguage('en');
      expect(localizeStored('📷 Fotoğraf'), tr('📷 Fotoğraf'));
      expect(
        localizeStored('🎤 Sesli mesaj: selam'),
        '${tr('🎤 Sesli mesaj')}: selam',
      );
      expect(localizeStored('😀 Çıkartma'), '😀 ${tr('Çıkartma')}');
      expect(localizeStored('Merhaba'), 'Merhaba');
    });
  });
}
