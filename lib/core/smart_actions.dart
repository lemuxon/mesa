/// "Mesajdan işe tek dokunuş": mesaj metnindeki işe yarar parçaları bulur
/// (doğrulama kodu, telefon, IBAN, e-posta, bağlantı, adres, tarih/saat).
/// Telefonda çalışır; metin hiçbir yere gönderilmez. Yanlış öneri, eksik
/// öneriden kötüdür: her kural temkinlidir (ör. kod yalnızca "kod", "şifre"
/// gibi bir sözcüğün yanında, IBAN yalnızca denetim basamağı tutarsa).
library;

enum SmartKind { code, phone, iban, email, link, map, address, when }

class SmartAction {
  const SmartAction(this.kind, this.value, {this.when, this.allDay = false});

  final SmartKind kind;

  /// Kopyalanacak ya da açılacak değer (kod, numara, IBAN, adres, bağlantı).
  final String value;

  /// [SmartKind.when]: mesajdaki an; [allDay] ise yalnızca gün belli.
  final DateTime? when;
  final bool allDay;

  @override
  String toString() =>
      'SmartAction($kind, $value${when != null ? ', $when${allDay ? ' (gün)' : ''}' : ''})';
}

/// Mesajdaki işe yarar parçalar. Göreli günler ("yarın") mesajın gönderildiği
/// güne göre hesaplanır ([sentAt]); geçmişte kalan tarih önerilmez ([now]).
List<SmartAction> findSmartActions(
  String text, {
  required DateTime sentAt,
  required DateTime now,
}) {
  if (text.trim().isEmpty) return const [];
  final taken = <(int, int)>[];
  bool free(Match m) => taken.every((t) => m.end <= t.$1 || m.start >= t.$2);
  void take(Match m) => taken.add((m.start, m.end));
  final found = <SmartAction>[];

  // Bağlantılar (harita bağlantısı haritada açılır).
  for (final m in _link.allMatches(text)) {
    var url = m.group(0)!;
    while (url.isNotEmpty && '.,;:!?)»"\''.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isEmpty) continue;
    take(m);
    final full = url.startsWith('http') ? url : 'https://$url';
    found.add(
      SmartAction(_isMapLink(full) ? SmartKind.map : SmartKind.link, full),
    );
  }

  // E-posta.
  for (final m in _email.allMatches(text)) {
    if (!free(m)) continue;
    take(m);
    found.add(SmartAction(SmartKind.email, m.group(0)!));
  }

  // IBAN (denetim basamağı tutmalı).
  for (final m in _iban.allMatches(text.toUpperCase())) {
    final iban = m.group(0)!.replaceAll(' ', '');
    if (!isValidIban(iban)) continue;
    take(m);
    found.add(SmartAction(SmartKind.iban, iban));
  }

  // Telefon numaraları.
  for (final pattern in _phones) {
    for (final m in pattern.allMatches(text)) {
      if (!free(m)) continue;
      final raw = m.group(0)!.trim();
      final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
      final count = digits.replaceAll('+', '').length;
      if (count < 10 || count > 15) continue;
      take(m);
      found.add(SmartAction(SmartKind.phone, _telNumber(digits)));
    }
  }

  final lower = _trLower(text);

  // Tarih ve saat (en fazla bir tane).
  final when = _findWhen(lower, sentAt: sentAt, now: now, taken: taken);
  if (when != null) found.add(when);

  // Doğrulama kodu: yalnızca "kod", "şifre" gibi bir sözcük varsa.
  if (_codeWord.hasMatch(lower)) {
    for (final m in _code.allMatches(text)) {
      if (!free(m)) continue;
      // "2026 yılında" gibi yıllar kod değildir.
      final digits = m.group(1)!;
      if (RegExp(r'^(19|20)\d\d$').hasMatch(digits) &&
          RegExp(
            r"^\s*['’]?\s*(yıl|sene|de|da|te|ta)",
            unicode: true,
          ).hasMatch(_trLower(text.substring(m.end)))) {
        continue;
      }
      take(m);
      final code = m
          .group(1)!
          .replaceFirst('G-', '')
          .replaceAll(RegExp(r'[ -]'), '');
      found.insert(0, SmartAction(SmartKind.code, code));
      break;
    }
  }

  // Adres: sokak/cadde/mahalle işareti ve kapı numarası ya da ikinci bir işaret.
  final address = _findAddress(text);
  if (address != null) found.add(SmartAction(SmartKind.address, address));

  return found;
}

/// IBAN denetimi (ISO 13616, mod 97). Türkiye IBAN'ı 26 karakterdir.
bool isValidIban(String value) {
  final s = value.replaceAll(' ', '').toUpperCase();
  if (!RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$').hasMatch(s)) return false;
  if (s.startsWith('TR') && s.length != 26) return false;
  final rearranged = s.substring(4) + s.substring(0, 4);
  var mod = 0;
  for (final unit in rearranged.codeUnits) {
    final v = unit >= 65 ? unit - 55 : unit - 48;
    mod = v >= 10 ? (mod * 100 + v) % 97 : (mod * 10 + v) % 97;
  }
  return mod == 1;
}

// ---- Kalıplar ----

final _link = RegExp(r'(?:https?://|www\.)[^\s<>]+', caseSensitive: false);
final _email = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+');
final _iban = RegExp(
  r'(?<![A-Z0-9])[A-Z]{2}\d{2}(?: ?[A-Z0-9]{4}){2,7}(?: ?[A-Z0-9]{1,4})?(?![A-Z0-9])',
);

final _phones = [
  // Türkiye cep: 05xx xxx xx xx, +90 5xx…, (5xx) xxx xx xx
  RegExp(
    r'(?<![\d+])(?:\+90|0090|0)?\s?\(?5\d{2}\)?[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}(?!\d)',
  ),
  // Türkiye sabit hat: başında 0 ya da +90 olmalı.
  RegExp(
    r'(?<![\d+])(?:\+90|0090|0)\s?\(?[2-4]\d{2}\)?[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}(?!\d)',
  ),
  // Uluslararası: + ile başlar.
  RegExp(r'(?<![\d+])\+\d{1,3}(?:[\s-]?\d{2,4}){2,5}(?!\d)'),
];

final _codeWord = RegExp(
  r'(?<![\p{L}\p{N}])(kod|kodu|kodunuz|code|doğrulama|onay|şifre|şifreniz|parola|otp|pin|verification|tek kullanımlık)',
  unicode: true,
);
final _code = RegExp(
  r'(?<![\d,.])((?:G-)?\d{3}[ -]?\d{3}|\d{4,8})(?![\d,.]\d)',
);

String _telNumber(String digits) {
  if (digits.startsWith('+')) return digits;
  if (digits.startsWith('0090')) return '+${digits.substring(2)}';
  if (digits.startsWith('0')) return '+90${digits.substring(1)}';
  if (digits.length == 10 && digits.startsWith('5')) return '+90$digits';
  return digits;
}

bool _isMapLink(String url) {
  final u = url.toLowerCase();
  return u.contains('maps.google.') ||
      u.contains('google.com/maps') ||
      u.contains('goo.gl/maps') ||
      u.contains('maps.app.goo.gl') ||
      u.contains('yandex.com.tr/maps') ||
      u.contains('yandex.ru/maps') ||
      u.contains('maps.apple.com');
}

/// Türkçe küçük harf: "İ" → "i", "I" → "ı".
String _trLower(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

// ---- Adres ----

final _streetMark = RegExp(
  r'(?<![\p{L}])(mah\.|mahallesi|mh\.|cad\.|caddesi|cd\.|sok\.|sokağı|sokak|sk\.|bulvarı|blv\.|bulv\.)',
  unicode: true,
  caseSensitive: false,
);
final _otherMark = RegExp(
  r'(?<![\p{L}])(no\s*[:.]?\s*\d+|kat\s*[:.]?\s*\d+|daire\s*[:.]?\s*\d+|d\s*[:.]\s*\d+|apt\.?|apartmanı|sitesi)',
  unicode: true,
  caseSensitive: false,
);

String? _findAddress(String text) {
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    final streets = _streetMark.allMatches(line).length;
    final others = _otherMark.allMatches(line).length;
    if (streets == 0 || streets + others < 2) continue;
    var address = line;
    // Alt satırdaki "Kadıköy/İstanbul" gibi ilçe/il de adrese katılır.
    if (i + 1 < lines.length) {
      final next = lines[i + 1].trim();
      if (next.contains('/') && next.length <= 40 && !next.contains('http')) {
        address = '$address $next';
      }
    }
    return address.length > 160 ? address.substring(0, 160) : address;
  }
  return null;
}

// ---- Tarih ve saat ----

const _months = {
  'ocak': 1,
  'şubat': 2,
  'mart': 3,
  'nisan': 4,
  'mayıs': 5,
  'haziran': 6,
  'temmuz': 7,
  'ağustos': 8,
  'eylül': 9,
  'ekim': 10,
  'kasım': 11,
  'aralık': 12,
};

const _weekdays = {
  'pazartesi': DateTime.monday,
  'salı': DateTime.tuesday,
  'çarşamba': DateTime.wednesday,
  'perşembe': DateTime.thursday,
  'cumartesi': DateTime.saturday,
  'cuma': DateTime.friday,
  'pazar': DateTime.sunday,
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

final _numericDate = RegExp(
  r'(?<!\d)(\d{1,2})[./](\d{1,2})[./](\d{4}|\d{2})(?!\d)',
);
final _slashDate = RegExp(r'(?<![\d/])(\d{1,2})/(\d{1,2})(?![\d/])');
final _namedDate = RegExp(
  '(?<!\\d)(\\d{1,2})\\s+(${_months.keys.join('|')})(?:\\s+(\\d{4}))?',
  unicode: true,
);
final _relativeDay = RegExp(
  r'(?<![\p{L}])(yarından sonra|öbür gün|ertesi gün|bugün|yarın|today|tomorrow|tonight|bu akşam|bu gece)',
  unicode: true,
);
final _weekday = RegExp(
  '(?<![\\p{L}])(haftaya |gelecek |bu |next )?(${_weekdays.keys.join('|')})(\\p{L}*)',
  unicode: true,
);
final _clock = RegExp(
  r'(?<![\d.:/])([01]?\d|2[0-3])([:.])([0-5]\d)(?![\d.:/])',
);
final _sayHour = RegExp(
  r'(?<![\p{L}])saat\s+([01]?\d|2[0-3])(?![\d:.])',
  unicode: true,
);
final _suffixHour = RegExp(
  r"(?<![\d.,:/])([01]?\d|2[0-3])\s*['’]?\s*(?:de|da|te|ta)(?![\p{L}])",
  unicode: true,
);

/// "akşam 8", "sabah 9:30", "gece saat 11".
final _periodHour = RegExp(
  r'(?<![\p{L}])(sabah|öğleden sonra|öğlen|öğle|ikindi|akşam|gece)\s+(?:saat\s+)?([01]?\d|2[0-3])(?:[:.]([0-5]\d))?(?!\d)',
  unicode: true,
);
final _amPm = RegExp(
  r'(?<![\d:])(\d{1,2})(?::([0-5]\d))?\s*(am|pm)(?![\p{L}])',
  unicode: true,
);
final _period = RegExp(
  r'(?<![\p{L}])(sabah|öğleden sonra|öğlen|öğle|ikindi|akşam|gece|tonight|morning|evening)',
  unicode: true,
);

SmartAction? _findWhen(
  String lower, {
  required DateTime sentAt,
  required DateTime now,
  required List<(int, int)> taken,
}) {
  bool free(Match m) => taken.every((t) => m.end <= t.$1 || m.start >= t.$2);
  final base = DateTime(sentAt.year, sentAt.month, sentAt.day);
  DateTime? day;
  final dateSpans = <(int, int)>[];

  // Gün.
  for (final m in _numericDate.allMatches(lower)) {
    if (!free(m)) continue;
    final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
    var y = int.parse(m.group(3)!);
    if (y < 100) y += 2000;
    final parsed = _date(y, mo, d);
    if (parsed != null) {
      day = parsed;
      dateSpans.add((m.start, m.end));
      break;
    }
  }
  if (day == null) {
    for (final m in _namedDate.allMatches(lower)) {
      final d = int.parse(m.group(1)!), mo = _months[m.group(2)!]!;
      final y = m.group(3) != null ? int.parse(m.group(3)!) : null;
      final parsed = _date(y ?? base.year, mo, d);
      if (parsed == null) continue;
      day = y == null && parsed.isBefore(base)
          ? _date(base.year + 1, mo, d)
          : parsed;
      dateSpans.add((m.start, m.end));
      break;
    }
  }
  if (day == null) {
    for (final m in _slashDate.allMatches(lower)) {
      if (!free(m)) continue;
      final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
      final parsed = _date(base.year, mo, d);
      if (parsed == null) continue;
      day = parsed.isBefore(base) ? _date(base.year + 1, mo, d) : parsed;
      dateSpans.add((m.start, m.end));
      break;
    }
  }
  var eveningHint = false;
  if (day == null) {
    final m = _relativeDay.firstMatch(lower);
    if (m != null) {
      switch (m.group(1)) {
        case 'bugün' || 'today':
          day = base;
        case 'bu akşam' || 'bu gece' || 'tonight':
          day = base;
          eveningHint = true;
        case 'yarın' || 'tomorrow':
          day = base.add(const Duration(days: 1));
        default:
          day = base.add(const Duration(days: 2));
      }
    }
  }
  if (day == null) {
    for (final m in _weekday.allMatches(lower)) {
      final name = m.group(2)!;
      final rest = m.group(3) ?? '';
      // "pazar" aynı zamanda çarşı demek: yalnızca gün olduğu belliyse.
      if (name == 'pazar' &&
          m.group(1) == null &&
          !_isSundayContext(lower, m.end, rest)) {
        continue;
      }
      final target = _weekdays[name]!;
      if (m.group(1) == 'haftaya ' ||
          m.group(1) == 'gelecek ' ||
          m.group(1) == 'next ') {
        // Gelecek haftanın o günü.
        final nextMonday = base.add(Duration(days: 8 - base.weekday));
        day = nextMonday.add(Duration(days: target - DateTime.monday));
      } else {
        day = base.add(Duration(days: (target - base.weekday) % 7));
      }
      break;
    }
  }

  // Saat.
  bool outsideDate(Match m) =>
      dateSpans.every((t) => m.end <= t.$1 || m.start >= t.$2) && free(m);
  int? hour;
  var minute = 0;
  var explicitMorning = false;
  for (final m in _clock.allMatches(lower)) {
    if (!outsideDate(m)) continue;
    // "12.50 tl" gibi: noktalı yazımda yalnızca "saat" ya da Türkçe ek varsa.
    if (m.group(2) == '.') {
      final before = lower.substring(0, m.start);
      final after = lower.substring(m.end);
      if (!RegExp(r'saat\s*$').hasMatch(before) &&
          !RegExp(r"^\s*['’]?\s*(?:de|da|te|ta)").hasMatch(after)) {
        continue;
      }
    }
    hour = int.parse(m.group(1)!);
    minute = int.parse(m.group(3)!);
    explicitMorning = m.group(1)!.startsWith('0') && hour < 10;
    break;
  }
  if (hour == null) {
    final m = _amPm.firstMatch(lower);
    if (m != null) {
      var h = int.parse(m.group(1)!);
      if (h >= 1 && h <= 12) {
        if (m.group(3) == 'pm' && h < 12) h += 12;
        if (m.group(3) == 'am' && h == 12) h = 0;
        hour = h;
        minute = m.group(2) != null ? int.parse(m.group(2)!) : 0;
        explicitMorning = m.group(3) == 'am';
      }
    }
  }
  if (hour == null) {
    final m = _periodHour.firstMatch(lower);
    if (m != null) {
      hour = int.parse(m.group(2)!);
      minute = m.group(3) != null ? int.parse(m.group(3)!) : 0;
    }
  }
  if (hour == null) {
    final m = _sayHour.firstMatch(lower);
    if (m != null) hour = int.parse(m.group(1)!);
  }
  final period = _period.firstMatch(lower)?.group(1);
  if (hour == null && (day != null || period != null)) {
    // "5'te" yalnızca gün ya da günün bölümü söylenmişse saattir.
    for (final m in _suffixHour.allMatches(lower)) {
      if (!outsideDate(m)) continue;
      hour = int.parse(m.group(1)!);
      break;
    }
  }
  if (hour != null) {
    hour = _applyPeriod(
      hour,
      period ?? (eveningHint ? 'akşam' : null),
      explicitMorning,
    );
  } else if (day != null && (period != null || eveningHint)) {
    // "yarın akşam" gibi: günün bölümünün alışılmış saati.
    hour = switch (period ?? 'akşam') {
      'sabah' || 'morning' => 9,
      'öğlen' || 'öğle' => 12,
      'öğleden sonra' || 'ikindi' => 15,
      'gece' => 22,
      _ => 19,
    };
  }

  if (day == null && hour == null) return null;
  if (hour == null) {
    // Yalnızca gün: bugün ya da ileride olmalı.
    final today = DateTime(now.year, now.month, now.day);
    if (day!.isBefore(today)) return null;
    if (day.difference(today).inDays > 366) return null;
    return SmartAction(SmartKind.when, '', when: day, allDay: true);
  }
  final on = day ?? base;
  var at = DateTime(on.year, on.month, on.day, hour, minute);
  // "Saat 9'da ararım" sabah 10'da yazıldıysa akşam 9'dur.
  if (!at.isAfter(now) &&
      hour < 12 &&
      period == null &&
      !explicitMorning &&
      on == base) {
    at = at.add(const Duration(hours: 12));
  }
  if (!at.isAfter(now) || at.difference(now).inDays > 366) return null;
  return SmartAction(SmartKind.when, '', when: at);
}

bool _isSundayContext(String lower, int end, String rest) {
  if (rest.startsWith('günü') ||
      rest.startsWith('a kadar') ||
      rest.startsWith('ya kadar')) {
    return true;
  }
  final after = lower.substring(end).trimLeft();
  return RegExp(
    r'^(günü|sabah|akşam|öğle|gece|saat|\d)',
    unicode: true,
  ).hasMatch(after);
}

int _applyPeriod(int hour, String? period, bool explicitMorning) {
  switch (period) {
    case 'akşam' || 'evening' || 'tonight' || 'öğleden sonra' || 'ikindi':
      return hour < 12 ? hour + 12 : hour;
    case 'gece':
      return hour >= 6 && hour < 12 ? hour + 12 : hour;
    case 'öğlen' || 'öğle':
      return hour < 6 ? hour + 12 : hour;
    case 'sabah' || 'morning':
      return hour == 12 ? 0 : hour;
  }
  // Belirtilmemiş: 1-7 arası çoğunlukla öğleden sonradır ("saat 5'te" → 17:00).
  if (!explicitMorning && hour >= 1 && hour <= 7) return hour + 12;
  return hour;
}

DateTime? _date(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final d = DateTime(year, month, day);
  return d.month == month ? d : null;
}
