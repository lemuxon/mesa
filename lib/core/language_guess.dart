/// Mesajın dili için kaba, anında bir tahmin: "Çevir" düğmesi yalnızca
/// okuyanın dilinde olmadığı belli olan mesajlarda görünsün diye.
///
/// Telefonda çalışır, hiçbir yere bir şey göndermez ve çeviri kitaplığını
/// başlatmaz. Yalnızca belirgin durumlarda karar verir: başka bir alfabe
/// (Kiril, Arap, Çin…) ya da Latin harfli dillerde sık kullanılan sözcükler
/// ve dile özgü harfler. Emin değilse "yabancı değil" der (basılı tutunca
/// menüde "Çevir" hep var); asıl dil, çevirirken telefondaki dil tanıma
/// modeliyle bulunur.
library;

enum _Script {
  latin,
  cyrillic,
  greek,
  arabic,
  hebrew,
  cjk,
  hangul,
  thai,
  indic,
  other,
}

/// Arayüz dillerinin alfabesi.
const _scriptOfLanguage = {'ar': _Script.arabic, 'ru': _Script.cyrillic};

/// Bu kadar harften kısa mesajlar ("ok", "👍", "Hi!") için düğme gösterilmez.
const _minLetters = 6;

/// [text], [language] ("tr", "en"…) dışında bir dilde yazılmış gibi mi?
bool looksForeign(String text, String language) {
  final cleaned = text.replaceAll(_noise, ' ');
  final counts = <_Script, int>{};
  for (final r in cleaned.runes) {
    final script = _scriptOf(r);
    if (script != null) counts[script] = (counts[script] ?? 0) + 1;
  }
  final total = counts.values.fold(0, (a, b) => a + b);
  if (total < _minLetters) return false;
  final expected = _scriptOfLanguage[language] ?? _Script.latin;
  // Harflerin çoğu başka bir alfabede.
  if ((counts[expected] ?? 0) * 2 < total) return true;
  return switch (expected) {
    _Script.latin => _latinForeign(cleaned, language),
    // Rusçada olmayan Kiril harfleri (Ukraynaca і ї є ґ, Sırpça ђ ћ џ…).
    _Script.cyrillic => _countOf(cleaned, _nonRussianCyrillic) >= 1,
    // Arapçada olmayan Farsça/Urduca harfler (پ چ ژ گ ک ی…).
    _Script.arabic => _countOf(cleaned, _persianLetters) >= 1,
    _ => false,
  };
}

/// Latin harfli metnin tahmini dili ("en", "de"…); emin değilse null.
/// Çeviride dil tanıma model emin olamazsa ipucu olarak kullanılır.
String? guessLatinLanguage(String text) {
  final scores = _latinScores(text.replaceAll(_noise, ' '));
  final ranked = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (ranked.isEmpty || ranked.first.value < 2) return null;
  final second = ranked.length > 1 ? ranked[1].value : 0;
  return ranked.first.value >= 2 * second + 1 ? ranked.first.key : null;
}

/// Bağlantılar, e-postalar, @adlar ve #etiketler dil sayılmaz.
final _noise = RegExp(
  r'(https?://|www\.)\S+|\S+@\S+\.\S+|[@#]\w+',
  caseSensitive: false,
);

_Script? _scriptOf(int r) {
  if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) {
    return _Script.latin;
  }
  if (r < 0xC0) return null; // rakam, noktalama
  if (r <= 0x24F) return (r == 0xD7 || r == 0xF7) ? null : _Script.latin;
  if (r >= 0x1E00 && r <= 0x1EFF) return _Script.latin; // Vietnamca
  if ((r >= 0x370 && r <= 0x3FF) || (r >= 0x1F00 && r <= 0x1FFF)) {
    return _Script.greek;
  }
  if (r >= 0x400 && r <= 0x52F) return _Script.cyrillic;
  if (r >= 0x530 && r <= 0x58F) return _Script.other; // Ermeni
  if (r >= 0x590 && r <= 0x5FF) return _Script.hebrew;
  if ((r >= 0x600 && r <= 0x6FF) ||
      (r >= 0x750 && r <= 0x77F) ||
      (r >= 0x8A0 && r <= 0x8FF) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF)) {
    return _Script.arabic;
  }
  if (r >= 0x900 && r <= 0xDFF) return _Script.indic;
  if (r >= 0xE00 && r <= 0xE7F) return _Script.thai;
  if (r >= 0x10A0 && r <= 0x10FF) return _Script.other; // Gürcü
  if ((r >= 0x1100 && r <= 0x11FF) ||
      (r >= 0x3130 && r <= 0x318F) ||
      (r >= 0xAC00 && r <= 0xD7AF)) {
    return _Script.hangul;
  }
  if ((r >= 0x3040 && r <= 0x30FF) ||
      (r >= 0x3400 && r <= 0x4DBF) ||
      (r >= 0x4E00 && r <= 0x9FFF)) {
    return _Script.cjk;
  }
  return null; // emoji, simgeler
}

const _nonRussianCyrillic = 'іїєґўјљњћђџәғқңөұүһІЇЄҐЎЈЉЊЋЂЏӘҒҚҢӨҰҮҺ';
const _persianLetters = 'پچژگکیٹڈڑںےۂۃ';

int _countOf(String text, String letters) {
  var n = 0;
  for (final r in text.runes) {
    if (letters.contains(String.fromCharCode(r))) n++;
  }
  return n;
}

/// Latin harfli bir metin [language] dışında bir dilde mi? Başka bir dilin
/// izi açıkça ağır basmalı; bilinmeyen dillerde (Lehçe, İsveççe…) okuyanın
/// alfabesinde olmayan harfler sayılır.
bool _latinForeign(String text, String language) {
  final scores = _latinScores(text);
  final own = scores[language] ?? 0;
  var best = 0;
  scores.forEach((lang, score) {
    if (lang != language && score > best) best = score;
  });
  if (best >= 2 && best >= 2 * own + 1) return true;
  return own == 0 && _strangeLetters(_lower(text), language) >= 3;
}

/// Dillere göre puan: sık kullanılan sözcükler (1'er) ve dile özgü harfler.
Map<String, int> _latinScores(String text) {
  final lower = _lower(text);
  final scores = <String, int>{};
  void add(String lang, int points) =>
      scores[lang] = (scores[lang] ?? 0) + points;
  // Türkçenin büyük İ'si küçültülünce noktası kaybolur; aslına bakılır.
  if (text.contains('İ')) add('tr', 2);
  for (final hint in _letterHints) {
    if (hint.letters.split('').any(lower.contains)) {
      add(hint.language, hint.points);
    }
  }
  for (final match in _word.allMatches(lower)) {
    final word = _fold(match.group(0)!.replaceAll('’', "'"));
    if (word.length < 2) continue;
    _stopwords.forEach((lang, words) {
      if (words.contains(word)) add(lang, 1);
    });
  }
  return scores;
}

final _word = RegExp(r"[\p{L}'’]+", unicode: true);

String _lower(String text) =>
    text.replaceAll('İ', 'i').toLowerCase().replaceAll('̇', '');

/// Okuyanın alfabesinde olmayan Latin harfleri (ör. Türkçe okuyana ñ, ł, å).
int _strangeLetters(String lower, String language) {
  final own = _alphabets[language] ?? '';
  var n = 0;
  for (final r in lower.runes) {
    if (r < 0xC0 || _scriptOf(r) != _Script.latin) continue;
    if (!own.contains(String.fromCharCode(r))) n++;
  }
  return n;
}

const _alphabets = {
  'tr': 'çğıöşüâîû',
  'en': '',
  'de': 'äöüß',
  'fr': 'àâæçéèêëîïôœùûüÿ',
  'es': 'áéíñóúü',
  'pt': 'áâãàçéêíóôõú',
};

typedef _LetterHint = ({String language, String letters, int points});

const List<_LetterHint> _letterHints = [
  (language: 'tr', letters: 'ğış', points: 2),
  (language: 'de', letters: 'ß', points: 2),
  (language: 'de', letters: 'ä', points: 1),
  (language: 'es', letters: 'ñ¿¡', points: 2),
  (language: 'pt', letters: 'ãõ', points: 2),
  (language: 'fr', letters: 'œ', points: 2),
  (language: 'fr', letters: 'êèë', points: 1),
  (language: 'it', letters: 'òì', points: 1),
];

/// Aksanlar atılır: eksik harfle yazılmış mesajlar da tanınsın
/// ("yarin aksam" = "yarın akşam").
String _fold(String word) {
  final out = StringBuffer();
  for (final c in word.split('')) {
    out.write(_folds[c] ?? c);
  }
  return out.toString();
}

const _folds = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ı': 'i', 'ñ': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ğ': 'g', 'ş': 's', //
  'ß': 'ss', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
};

/// Her dilin en sık sözcükleri (sohbet dili dahil); aksansız karşılaştırılır.
final Map<String, Set<String>> _stopwords = {
  for (final e in _rawStopwords.entries)
    e.key: e.value.split(RegExp(r'\s+')).map(_fold).toSet(),
};

const _rawStopwords = {
  'tr':
      've bir bi bu şu da de ki mi mı mu mü ne ben sen biz siz onlar için '
      'ile çok daha ama fakat gibi var yok evet hayır tamam değil nasıl neden '
      'niye şimdi sonra önce bugün yarın dün merhaba selam teşekkürler '
      'teşekkür sağol sağolun iyi güzel olur oldu olsun geliyorum geldim gel '
      'gelir misin musun değilim abi abla kanka hocam efendim lütfen tabi '
      'tabii hadi bak bende sende şey artık hiç hep kadar bana sana beni '
      'seni onu ona neyse aslında belki zaten yani peki günaydın iyiyim '
      'nasılsın akşam sabah saat geç erken burada orada nerede nereye zaman '
      'kim hangi şöyle böyle öyle sadece bile naber napıyorsun',
  'en':
      "the and you your are is was were have has had will would can could "
      "should what when where why how who this that there here with for from "
      "not but just about i'm i'll i've i'd don't dont doesn't didn't can't "
      "cant won't isn't it's that's you're we're they're let's hello hi hey "
      "thanks thank please yes yeah yep okay sure sorry good morning night "
      "tonight today tomorrow yesterday see know think want need going gonna "
      "wanna come coming call me my we our they them it of to in on at be do "
      "did does so if or all some any more very really well now then still "
      "also much many love miss lol omg btw happy great day birthday nice "
      "wish congrats time home work",
  'de':
      'der die das und ist nicht ich du wir ihr sie es ein eine einen einem '
      'mit auf für von zu den dem des auch aber noch schon wie was wo wann '
      'warum ja nein bitte danke hallo gut morgen heute bin bist sind hast '
      'habe haben kann kannst wird mal doch dann jetzt hier mich dich mir dir '
      'uns euch sehr viel alles nichts gerne genau oder wenn weil dass sich '
      'im zum zur ins vom gleich komme bald nur immer wieder schön liebe mein '
      'dein kein keine etwas machen gehen',
  'fr':
      "le la les et est je tu il elle nous vous ils elles une des du pas que "
      "qui pour avec dans sur mais ou où oui non merci bonjour salut bonsoir "
      "c'est j'ai ça ce cette mon ton son mes tes ses très bien aussi au aux "
      "suis es sont avez avons fait faire demain aujourd'hui quand comment "
      "pourquoi quoi rien tout tous peut veux vais va ai as on",
  'es':
      'el la los las es en que de no por para con una uno un lo al del se su '
      'sus mi tu yo pero muy más hola gracias sí si bien está estas estás '
      'estoy qué cómo cuando cuándo dónde donde porque también hoy mañana '
      'ahora bueno buena nada todo eso esto hay tengo tienes quiero puedo '
      'vamos usted ustedes nosotros',
  'pt':
      'os não que de do da dos das em no na nos nas um uma com para por mais '
      'mas eu você vocês ele ela nós isso isto esse essa está estou tá '
      'obrigado obrigada olá oi tudo bem sim muito também hoje amanhã agora '
      'então quando onde porque já ainda aqui tem vou vai fazer pra pro',
  'it':
      'il lo la gli le di che non per con una sono sei io lui lei noi voi '
      'loro ma anche come cosa perché quando dove ciao grazie buongiorno '
      'buonasera sì bene molto oggi domani adesso ancora questo questa ho hai '
      'ha abbiamo del della dei delle nel nella alla tutto niente',
  'nl':
      'de het een en is niet ik je jij we wij ze zij met op voor van dat die '
      'maar ook nog wel geen ja nee dank bedankt hallo hoi goed morgen '
      'vandaag zijn heb hebt heeft kan wil waar wanneer waarom hoe wat',
  'id':
      'yang dan di ini itu dengan untuk tidak ada saya kamu aku apa sudah '
      'akan bisa juga dari ke mau lagi belum sama terima kasih',
};
