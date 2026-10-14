import 'l10n.dart';

/// Yerel taraf (bildirimden ve Telegram'dan yakalarken) metni olmayan
/// mesajları veritabanına Türkçe etiketle yazar: "📷 Fotoğraf",
/// "🎤 Sesli mesaj: altyazı", "😀 Çıkartma" gibi. Kayıt Türkçe kalır (eski
/// mesajlar ve karşılaştırmalar bozulmasın); gösterirken seçili dile çevrilir.
String localizeStored(String text) {
  if (currentLanguage == 'tr' || text.isEmpty) return text;
  for (final label in _labels) {
    if (text == label) return _translate(label);
    if (text.startsWith('$label: ')) {
      return _translate(label) + text.substring(label.length);
    }
  }
  // Çıkartma: "😀 Çıkartma" (emojisiyle) ya da yalnızca "Çıkartma".
  const sticker = 'Çıkartma';
  if (text == sticker || text.endsWith(' $sticker')) {
    return text.substring(0, text.length - sticker.length) + tr('Çıkartma');
  }
  return text;
}

const _labels = [
  '📷 Fotoğraf',
  '🎥 Video',
  '🎵 Ses dosyası',
  '🎤 Sesli mesaj',
  '🎤 Ses',
  '⏺ Görüntülü mesaj',
  '📍 Konum',
  '📄 Dosya',
  '👤 Kişi',
  '📊 Anket',
];

String _translate(String label) => switch (label) {
  '📷 Fotoğraf' => tr('📷 Fotoğraf'),
  '🎥 Video' => tr('🎥 Video'),
  '🎵 Ses dosyası' => tr('🎵 Ses dosyası'),
  '🎤 Sesli mesaj' => tr('🎤 Sesli mesaj'),
  '🎤 Ses' => tr('🎤 Ses'),
  '⏺ Görüntülü mesaj' => tr('⏺ Görüntülü mesaj'),
  '📍 Konum' => tr('📍 Konum'),
  '📄 Dosya' => tr('📄 Dosya'),
  '👤 Kişi' => tr('👤 Kişi'),
  '📊 Anket' => tr('📊 Anket'),
  _ => label,
};
