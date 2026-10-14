import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yerel taraftaki (AppSettings.kt) ayarlar: bildirim servisi ve Telegram
/// istemcisi de bunlara uyar.
class AppSettings {
  const AppSettings({
    this.disabledPackages = const {},
    this.hideTelegramChannels = false,
    this.retentionDays = 0,
    this.importantNotifications = true,
    this.unifiedNotifications = false,
    this.telegramGhostRead = false,
    this.keepSourcePackages = const {},
  });

  factory AppSettings.fromMap(Map<Object?, Object?> m) => AppSettings(
    disabledPackages: (m['disabledPackages'] as List<Object?>? ?? const [])
        .cast<String>()
        .toSet(),
    hideTelegramChannels: m['hideTelegramChannels'] as bool? ?? false,
    retentionDays: m['retentionDays'] as int? ?? 0,
    importantNotifications: m['importantNotifications'] as bool? ?? true,
    unifiedNotifications: m['unifiedNotifications'] as bool? ?? false,
    telegramGhostRead: m['telegramGhostRead'] as bool? ?? false,
    keepSourcePackages: (m['keepSourcePackages'] as List<Object?>? ?? const [])
        .cast<String>()
        .toSet(),
  );

  /// Mesajları okunmayan uygulamalar (paket adı).
  final Set<String> disabledPackages;

  /// Telegram yayın kanallarının mesajları alınmaz.
  final bool hideTelegramChannels;

  /// Bundan eski mesajlar silinir; 0 = süresiz.
  final int retentionDays;

  /// "Önemli işaretle" kuralı çalışınca bildirim gösterilir.
  final bool importantNotifications;

  /// Kaynak uygulamaların mesaj bildirimleri kaldırılır, yerine tek tip
  /// Mesa bildirimleri gösterilir.
  final bool unifiedNotifications;

  /// Telegram'da gizli okuma: "görüldü" ve "yazıyor" gönderilmez.
  final bool telegramGhostRead;

  /// Birleşik bildirimlerde kendi bildirimi de çubukta kalan uygulamalar:
  /// Mesa yeniden başlasa da bu sohbetlere doğrudan yanıt gider.
  final Set<String> keepSourcePackages;

  AppSettings copyWith({
    Set<String>? disabledPackages,
    bool? hideTelegramChannels,
    int? retentionDays,
    bool? importantNotifications,
    bool? unifiedNotifications,
    bool? telegramGhostRead,
    Set<String>? keepSourcePackages,
  }) => AppSettings(
    disabledPackages: disabledPackages ?? this.disabledPackages,
    hideTelegramChannels: hideTelegramChannels ?? this.hideTelegramChannels,
    retentionDays: retentionDays ?? this.retentionDays,
    importantNotifications:
        importantNotifications ?? this.importantNotifications,
    unifiedNotifications: unifiedNotifications ?? this.unifiedNotifications,
    telegramGhostRead: telegramGhostRead ?? this.telegramGhostRead,
    keepSourcePackages: keepSourcePackages ?? this.keepSourcePackages,
  );

  Map<String, Object?> toMap() => {
    'disabledPackages': disabledPackages.toList(),
    'hideTelegramChannels': hideTelegramChannels,
    'retentionDays': retentionDays,
    'importantNotifications': importantNotifications,
    'unifiedNotifications': unifiedNotifications,
    'telegramGhostRead': telegramGhostRead,
    'keepSourcePackages': keepSourcePackages.toList(),
  };
}

/// Mesaj saklama süresi seçenekleri (gün → etiket).
Map<int, String> get retentionOptions => {
  0: tr('Süresiz'),
  7: tr('7 gün'),
  30: tr('30 gün'),
  90: tr('90 gün'),
  365: tr('1 yıl'),
};

/// Yalnızca arayüzü ilgilendiren, cihazda saklanan tercihler.
class LocalPrefs {
  LocalPrefs(this._prefs);

  static Future<LocalPrefs> load() async =>
      LocalPrefs(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _lockKey = 'lock_enabled';
  static const _quickRepliesKey = 'quick_replies';
  static const _unifiedPromoKey = 'unified_promo_dismissed';
  static const _ghostHintKey = 'ghost_hint_seen';

  // Kullanıcı değiştirmediyse seçili dilde.
  static List<String> get defaultQuickReplies => [
    tr('Tamam 👍'),
    tr('Şu an müsait değilim, sonra yazarım.'),
    tr('Yoldayım, birazdan oradayım.'),
    tr('Teşekkürler!'),
  ];

  bool get lockEnabled => _prefs.getBool(_lockKey) ?? false;

  static const _languageKey = 'language';

  /// Seçilen dil ("en", …); null: telefonun dili.
  String? get languageCode => _prefs.getString(_languageKey);

  Future<void> setLanguageCode(String? code) => code == null
      ? _prefs.remove(_languageKey)
      : _prefs.setString(_languageKey, code);

  Future<void> setLockEnabled(bool value) => _prefs.setBool(_lockKey, value);

  List<String> get quickReplies =>
      _prefs.getStringList(_quickRepliesKey) ?? defaultQuickReplies;

  Future<void> setQuickReplies(List<String> replies) =>
      _prefs.setStringList(_quickRepliesKey, replies);

  /// Gelen kutusundaki "Bildirimleri birleştir" kartı kapatıldı.
  bool get unifiedPromoDismissed => _prefs.getBool(_unifiedPromoKey) ?? false;

  Future<void> dismissUnifiedPromo() => _prefs.setBool(_unifiedPromoKey, true);

  /// Sohbetteki "görüldü gönderilmez" ipucu kapatıldı.
  bool get ghostHintSeen => _prefs.getBool(_ghostHintKey) ?? false;

  Future<void> dismissGhostHint() => _prefs.setBool(_ghostHintKey, true);

  // ---- Kurulum listesi: sistemin bize söylemediği adımlar elle onaylanır ----

  static const _autostartKey = 'setup_autostart_done';
  static const _recentsLockKey = 'setup_recents_lock_done';
  static const _setupSnoozeKey = 'setup_snoozed_until';
  static const _keepNudgeKey = 'keep_nudge_dismissed';

  /// Xiaomi otomatik başlatma ayarı açıldı (sistem durumu okunamıyor).
  bool get autostartConfirmed => _prefs.getBool(_autostartKey) ?? false;

  Future<void> confirmAutostart() => _prefs.setBool(_autostartKey, true);

  /// Uygulama son uygulamalarda kilitlendi (MIUI kaydırınca kapatmasın).
  bool get recentsLockConfirmed => _prefs.getBool(_recentsLockKey) ?? false;

  Future<void> confirmRecentsLock() => _prefs.setBool(_recentsLockKey, true);

  /// "Kurulumu tamamla" kartı bu zamana kadar gösterilmez.
  DateTime? get setupSnoozedUntil => switch (_prefs.getInt(_setupSnoozeKey)) {
    final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
    null => null,
  };

  Future<void> snoozeSetup(DateTime until) =>
      _prefs.setInt(_setupSnoozeKey, until.millisecondsSinceEpoch);

  /// "… geçmeden gönder" önerisi kapatılan uygulamalar.
  Set<String> get keepNudgeDismissed =>
      (_prefs.getStringList(_keepNudgeKey) ?? const []).toSet();

  Future<void> dismissKeepNudge(String packageName) => _prefs.setStringList(
    _keepNudgeKey,
    {...keepNudgeDismissed, packageName}.toList(),
  );

  // ---- Yedek ----

  static const _lastBackupKey = 'last_backup_at';

  /// Son yedeğin alındığı an (bu telefonda); hiç alınmadıysa null.
  DateTime? get lastBackupAt => switch (_prefs.getInt(_lastBackupKey)) {
    final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
    null => null,
  };

  Future<void> setLastBackupAt(DateTime at) =>
      _prefs.setInt(_lastBackupKey, at.millisecondsSinceEpoch);

  // ---- Günün ipucu ----

  static const _tipIndexKey = 'tip_index';
  static const _tipDismissedKey = 'tip_dismissed_at';

  /// Sıradaki ipucunun sırası (hepsi görüldüyse ipucu sayısına eşit ya da büyük).
  int get tipIndex => _prefs.getInt(_tipIndexKey) ?? 0;

  /// Son ipucunun kapatıldığı an (aynı gün ikincisi gösterilmez).
  DateTime? get tipDismissedAt => switch (_prefs.getInt(_tipDismissedKey)) {
    final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
    null => null,
  };

  Future<void> advanceTip(DateTime now) async {
    await _prefs.setInt(_tipIndexKey, tipIndex + 1);
    await _prefs.setInt(_tipDismissedKey, now.millisecondsSinceEpoch);
  }
}
