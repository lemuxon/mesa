import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'ar.dart';
import 'de.dart';
import 'en.dart';
import 'es.dart';
import 'fr.dart';
import 'pt.dart';
import 'ru.dart';

/// Desteklenen diller: kod → kendi dilindeki adı.
const languages = <String, String>{
  'tr': 'Türkçe',
  'en': 'English',
  'es': 'Español',
  'pt': 'Português',
  'de': 'Deutsch',
  'fr': 'Français',
  'ar': 'العربية',
  'ru': 'Русский',
};

/// Türkçe metin → çeviri. Türkçe metnin kendisi anahtardır; çevirisi
/// eksikse İngilizcesi, o da yoksa Türkçesi gösterilir
/// (test/l10n_test.dart eksik çeviriye izin vermez).
const translations = <String, Map<String, String>>{
  'en': en,
  'es': es,
  'pt': pt,
  'de': de,
  'fr': fr,
  'ar': ar,
  'ru': ru,
};

String _language = 'tr';

/// Uygulamanın şu anki dili ("tr", "en", …).
String get currentLanguage => _language;

Locale get currentLocale => Locale(_language);

/// MaterialApp'in dili ve yazı yönü bunu dinler.
final languageNotifier = ValueNotifier<String>('tr');

/// Seçilen dil; null: telefonun dili (desteklenmiyorsa İngilizce).
String resolveLanguage(String? chosen, String system) {
  if (chosen != null && languages.containsKey(chosen)) return chosen;
  return languages.containsKey(system) ? system : 'en';
}

/// Dili değiştirir. Uygulama çalışırken çağrılırsa bütün ekranlar yeniden
/// çizilir (durumları korunur).
void setLanguage(String? chosen) {
  final next = resolveLanguage(
    chosen,
    PlatformDispatcher.instance.locale.languageCode,
  );
  if (next == _language) return;
  _language = next;
  languageNotifier.value = next;
  _rebuildAll();
}

/// Testler ve önizlemeler için: telefona bakmadan dili ayarlar.
@visibleForTesting
void debugSetLanguage(String code) {
  _language = code;
  languageNotifier.value = code;
}

void _rebuildAll() {
  void mark(Element element) {
    element.markNeedsBuild();
    element.visitChildren(mark);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(mark);
}

/// [turkish] metnin seçili dildeki karşılığı. `{ad}` yer tutucuları
/// [args]'tan doldurulur; çeviride ICU çoğulu kullanılabilir:
/// `{count, plural, one{# message} other{# messages}}`.
String tr(String turkish, [Map<String, Object?> args = const {}]) {
  final text = _language == 'tr'
      ? turkish
      : translations[_language]?[turkish] ??
            translations['en']?[turkish] ??
            turkish;
  return formatMessage(text, args, _language);
}

/// Yer tutucuları ve çoğul biçimlerini doldurur.
String formatMessage(String text, Map<String, Object?> args, String language) {
  if (!text.contains('{')) return text;
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final open = text.indexOf('{', i);
    if (open < 0) {
      out.write(text.substring(i));
      break;
    }
    out.write(text.substring(i, open));
    final close = _matching(text, open);
    if (close < 0) {
      out.write(text.substring(open));
      break;
    }
    out.write(_placeholder(text.substring(open + 1, close), args, language));
    i = close + 1;
  }
  return out.toString();
}

int _matching(String text, int open) {
  var depth = 0;
  for (var i = open; i < text.length; i++) {
    if (text[i] == '{') depth++;
    if (text[i] == '}' && --depth == 0) return i;
  }
  return -1;
}

String _placeholder(String body, Map<String, Object?> args, String language) {
  final comma = body.indexOf(',');
  if (comma < 0) {
    final name = body.trim();
    return args.containsKey(name) ? '${args[name]}' : '{$body}';
  }
  final name = body.substring(0, comma).trim();
  final rest = body.substring(comma + 1).trimLeft();
  if (!rest.startsWith('plural,')) return '{$body}';
  final value = args[name];
  final n = value is num ? value : num.tryParse('$value') ?? 0;
  final forms = _pluralForms(rest.substring('plural,'.length));
  final form =
      forms['=$n'] ??
      forms[pluralCategory(language, n)] ??
      forms['other'] ??
      '';
  return formatMessage(form.replaceAll('#', '$n'), args, language);
}

Map<String, String> _pluralForms(String spec) {
  final forms = <String, String>{};
  var i = 0;
  while (i < spec.length) {
    final open = spec.indexOf('{', i);
    if (open < 0) break;
    final key = spec.substring(i, open).trim();
    final close = _matching(spec, open);
    if (close < 0) break;
    forms[key] = spec.substring(open + 1, close);
    i = close + 1;
  }
  return forms;
}

/// CLDR çoğul kategorisi (yalnızca tam sayılar).
String pluralCategory(String language, num value) {
  final n = value.abs().toInt();
  switch (language) {
    case 'ru':
      if (n % 10 == 1 && n % 100 != 11) return 'one';
      if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14)) {
        return 'few';
      }
      return 'many';
    case 'ar':
      if (n == 0) return 'zero';
      if (n == 1) return 'one';
      if (n == 2) return 'two';
      if (n % 100 >= 3 && n % 100 <= 10) return 'few';
      if (n % 100 >= 11) return 'many';
      return 'other';
    case 'fr':
    case 'pt':
      return n <= 1 ? 'one' : 'other';
    case 'tr':
    case 'en':
    case 'es':
    case 'de':
    default:
      return n == 1 ? 'one' : 'other';
  }
}
