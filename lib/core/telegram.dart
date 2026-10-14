import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:typed_data';

/// Telegram (TDLib) bağlantısının durumu. Yerel taraf: TelegramClient.kt.
enum TelegramState {
  unconfigured,
  stopped,
  starting,
  waitPhone,
  waitCode,
  waitEmailCode,
  waitPassword,
  ready,
  loggingOut,
  unsupported;

  /// Kotlin'deki enum adı (ör. WAIT_PHONE) → Dart değeri.
  static TelegramState fromWire(String wire) {
    final camel = wire.toLowerCase().replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m[1]!.toUpperCase(),
    );
    return values.firstWhere(
      (s) => s.name == camel,
      orElse: () => TelegramState.unsupported,
    );
  }

  /// Kullanıcıdan bir değer bekleniyor mu (telefon, kod, şifre).
  bool get needsInput => switch (this) {
    waitPhone || waitCode || waitEmailCode || waitPassword => true,
    _ => false,
  };

  /// Kotlin tarafına gönderilen adım adı.
  String get step => switch (this) {
    waitPhone => 'phone',
    waitCode => 'code',
    waitEmailCode => 'emailCode',
    waitPassword => 'password',
    _ => throw StateError(tr('{step} bir giriş adımı değil', {'step': this})),
  };
}

class TelegramStatus {
  const TelegramStatus({
    required this.configured,
    required this.enabled,
    required this.state,
    this.hint,
  });

  factory TelegramStatus.fromMap(Map<Object?, Object?> m) => TelegramStatus(
    configured: m['configured']! as bool,
    enabled: m['enabled']! as bool,
    state: TelegramState.fromWire(m['state']! as String),
    hint: m['hint'] as String?,
  );

  /// api_id / api_hash derlemeye verilmiş mi.
  final bool configured;

  /// Kullanıcı bağlantıyı açtı.
  final bool enabled;
  final TelegramState state;

  /// Kodun nereye gittiği, şifre ipucu ya da desteklenmeyen adım açıklaması.
  final String? hint;
}

/// Çıkartma paketi ("recent": son kullanılanlar).
class StickerSetInfo {
  const StickerSetInfo({required this.id, required this.title, this.thumbPath});

  factory StickerSetInfo.fromMap(Map<Object?, Object?> m) => StickerSetInfo(
    id: m['id']! as String,
    title: m['title']! as String,
    thumbPath: m['thumbPath'] as String?,
  );

  final String id;
  final String title;
  final String? thumbPath;
}

/// Gönderilebilir çıkartma ya da GIF. [token] yerel tarafta TDLib içeriğine çevrilir.
class PickItem {
  const PickItem({
    required this.token,
    this.thumbPath,
    this.miniThumb,
    this.emoji,
  });

  factory PickItem.fromMap(Map<Object?, Object?> m) => PickItem(
    token: m['token']! as String,
    thumbPath: m['thumbPath'] as String?,
    miniThumb: m['miniThumb'] as Uint8List?,
    emoji: m['emoji'] as String?,
  );

  final String token;

  /// İndirilmiş önizleme dosyası.
  final String? thumbPath;

  /// Önizleme indirilemezse gömülü, bulanık küçük JPEG.
  final Uint8List? miniThumb;
  final String? emoji;
}

/// Telegram sohbet anahtarları `tg|<sohbet kimliği>` biçimindedir.
bool isTelegramKey(String key) => key.startsWith('tg|');
