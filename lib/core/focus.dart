/// Odak modunun durumu (yerel taraf: Focus.kt).
class FocusStatus {
  const FocusStatus({
    required this.active,
    this.manualUntil,
    this.scheduleOn = false,
    this.scheduleFrom = 22 * 60,
    this.scheduleTo = 7 * 60,
    this.scheduleDays = 0x7f,
    this.scheduleActive = false,
    this.end,
    this.vip = const [],
    this.breakthrough = true,
    this.silenced = 0,
    this.unified = false,
  });

  /// Yerel taraftaki "kapatılana kadar" değeri (Long.MAX_VALUE).
  static const indefinite = 0x7fffffffffffffff;

  factory FocusStatus.fromMap(Map<Object?, Object?> m) {
    final manual = (m['manualUntil'] as num?)?.toInt();
    final end = (m['end'] as num?)?.toInt();
    return FocusStatus(
      active: m['active'] as bool? ?? false,
      manualUntil: manual,
      scheduleOn: m['scheduleOn'] as bool? ?? false,
      scheduleFrom: (m['scheduleFrom'] as num?)?.toInt() ?? 22 * 60,
      scheduleTo: (m['scheduleTo'] as num?)?.toInt() ?? 7 * 60,
      scheduleDays: (m['scheduleDays'] as num?)?.toInt() ?? 0x7f,
      scheduleActive: m['scheduleActive'] as bool? ?? false,
      end: end == null ? null : DateTime.fromMillisecondsSinceEpoch(end),
      vip: [...?(m['vip'] as List?)?.cast<String>()],
      breakthrough: m['breakthrough'] as bool? ?? true,
      silenced: (m['silenced'] as num?)?.toInt() ?? 0,
      unified: m['unified'] as bool? ?? false,
    );
  }

  final bool active;

  /// Elle açıldıysa bitiş anı (milisaniye) ya da [indefinite]; değilse null.
  final int? manualUntil;
  final bool scheduleOn;

  /// Gece yarısından dakika.
  final int scheduleFrom;
  final int scheduleTo;

  /// Bit 0 pazartesi … bit 6 pazar.
  final int scheduleDays;
  final bool scheduleActive;

  /// Etkin odağın biteceği an; süresizse null.
  final DateTime? end;

  /// VIP sohbet anahtarları.
  final List<String> vip;

  /// Aynı sohbet 5 dakikada 3. kez yazarsa bildirim gelir.
  final bool breakthrough;

  /// Bu odak süresince susturulan mesaj sayısı.
  final int silenced;

  /// Birleşik bildirimler açık mı (değilse diğer uygulamalar kendi bildirimiyle çalabilir).
  final bool unified;

  bool get indefiniteManual => manualUntil == indefinite;
}

/// Odak süresi seçenekleri: [now]'dan bitiş anı (milisaniye).
int focusUntil(String option, DateTime now) => switch (option) {
  '1h' => now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
  '3h' => now.add(const Duration(hours: 3)).millisecondsSinceEpoch,
  'morning' => _nextMorning(now).millisecondsSinceEpoch,
  _ => FocusStatus.indefinite,
};

/// Bir sonraki sabah 08:00 (şimdi 08:00'den önceyse bugün).
DateTime _nextMorning(DateTime now) {
  final today = DateTime(now.year, now.month, now.day, 8);
  return now.isBefore(today) ? today : today.add(const Duration(days: 1));
}
