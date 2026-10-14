import '../l10n/l10n.dart';

// Dil değişince yeniden hesaplansın diye getter.
List<String> get _weekdays => [
  tr('Pazartesi'),
  tr('Salı'),
  tr('Çarşamba'),
  tr('Perşembe'),
  tr('Cuma'),
  tr('Cumartesi'),
  tr('Pazar'),
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Sohbetteki gün ayracı: "Bugün", "Dün", son bir haftada gün adı, daha
/// eskiyse "1 Ekim" (başka yılsa yılıyla).
String formatDayLabel(DateTime t, DateTime now) {
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final daysAgo = (today.difference(day).inHours / 24).round();
  if (daysAgo == 0) return tr('Bugün');
  if (daysAgo == 1) return tr('Dün');
  if (daysAgo > 1 && daysAgo < 7) return _weekdays[t.weekday - 1];
  final label = _dayMonth(t.day, t.month);
  return t.year == now.year ? label : '$label ${t.year}';
}

/// "1 Ekim". Her ay ayrı metin: bazı dillerde ay adı tarihte başka hal
/// alır (Rusça "1 октября", galeri başlığında "октябрь") ya da önce gelir
/// (İngilizce "October 1").
String _dayMonth(int day, int month) => switch (month) {
  1 => tr('{day} Ocak', {'day': day}),
  2 => tr('{day} Şubat', {'day': day}),
  3 => tr('{day} Mart', {'day': day}),
  4 => tr('{day} Nisan', {'day': day}),
  5 => tr('{day} Mayıs', {'day': day}),
  6 => tr('{day} Haziran', {'day': day}),
  7 => tr('{day} Temmuz', {'day': day}),
  8 => tr('{day} Ağustos', {'day': day}),
  9 => tr('{day} Eylül', {'day': day}),
  10 => tr('{day} Ekim', {'day': day}),
  11 => tr('{day} Kasım', {'day': day}),
  _ => tr('{day} Aralık', {'day': day}),
};

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Saat: "14:05".
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// Gelen kutusu satırındaki zaman: bugünse saat, dünse "Dün", son bir
/// haftaysa gün adı, daha eskiyse tarih.
String formatListTime(DateTime t, DateTime now) {
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  // Yaz saati geçişinde iki gece yarısı arası 23/25 saat olabilir.
  final daysAgo = (today.difference(day).inHours / 24).round();
  if (daysAgo <= 0) return formatClock(t);
  if (daysAgo == 1) return tr('Dün');
  if (daysAgo < 7) return _weekdays[t.weekday - 1];
  // Sayısal tarih sırası ve ayracı dile göre (İngilizce ay/gün/yıl).
  return tr('{day}.{month}.{year}', {
    'day': _two(t.day),
    'month': _two(t.month),
    'year': t.year,
  });
}

/// Gelecekteki an: "bugün 20:00", "yarın 09:00", "Cuma 14:00", "12 Ekim 09:00".
String formatWhen(DateTime t, DateTime now) {
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final daysAhead = (day.difference(today).inHours / 24).round();
  final clock = formatClock(t);
  if (daysAhead == 0) return tr('bugün {clock}', {'clock': clock});
  if (daysAhead == 1) return tr('yarın {clock}', {'clock': clock});
  if (daysAhead > 1 && daysAhead < 7) {
    return '${_weekdays[t.weekday - 1]} $clock';
  }
  return '${_dayMonth(t.day, t.month)} $clock';
}

/// Bekleme süresi: "3 dk", "2 sa", "1 g".
String formatWaiting(DateTime since, DateTime now) {
  final d = now.difference(since);
  if (d.inMinutes < 1) return tr('şimdi');
  if (d.inMinutes < 60) return tr('{n} dk', {'n': d.inMinutes});
  if (d.inHours < 24) return tr('{n} sa', {'n': d.inHours});
  return tr('{n} g', {'n': d.inDays});
}

/// Süre: "0:42", "3:05", "1:02:03".
String formatDuration(Duration d) {
  final s = _two(d.inSeconds % 60);
  return d.inHours > 0
      ? '${d.inHours}:${_two(d.inMinutes % 60)}:$s'
      : '${d.inMinutes}:$s';
}

/// Dosya boyutu: "850 KB", "4,2 MB" (İngilizce ve Arapçada "4.2 MB";
/// Fransızca "Mo", Rusça "МБ").
String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes ${tr('B')}';
  final units = [tr('KB'), tr('MB'), tr('GB')];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 10 || unit == 0
      ? value.round().toString()
      : _decimalComma
      ? value.toStringAsFixed(1).replaceAll('.', ',')
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// Medyanın süre ve boyut özeti ("1:23 · 4,2 MB"); bilgi yoksa null.
String? formatMediaInfo({int? seconds, int? bytes}) {
  final parts = [
    if (seconds != null) formatDuration(Duration(seconds: seconds)),
    if (bytes != null) formatSize(bytes),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Ondalık ayırıcı virgül olan diller.
bool get _decimalComma => !const {'en', 'ar'}.contains(currentLanguage);
