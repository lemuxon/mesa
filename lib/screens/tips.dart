import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/settings.dart';

/// Gizli kalan bir özelliği tanıtan kısa ipucu.
class Tip {
  const Tip(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Sırayla, günde en fazla biri gösterilir.
List<Tip> get tips => [
  Tip(
    Icons.touch_app_outlined,
    tr(
      'Bir sohbete basılı tutun: sabitleyin, sonraya erteleyin ya da aynı kişinin başka uygulamadaki sohbetiyle birleştirin.',
    ),
  ),
  Tip(
    Icons.schedule_send_outlined,
    tr('Gönder düğmesine basılı tutun: mesajı istediğiniz saate planlayın.'),
  ),
  Tip(
    Icons.bookmark_add_outlined,
    tr(
      'Bir mesaja basılı tutup "Kaydet": tüm uygulamalardan kaydettikleriniz üstteki 🔖 listesinde.',
    ),
  ),
  Tip(
    Icons.photo_library_outlined,
    tr(
      'Sohbetin üstündeki galeri düğmesi: o kişiyle paylaşılan tüm fotoğraf ve videolar tek yerde.',
    ),
  ),
  Tip(
    Icons.bolt_rounded,
    tr(
      'Bildirimden yazmadan yanıtlayın: hazır yanıtlarınız bildirimin altında tek dokunuşla. Listeyi Ayarlar → Hazır yanıtlar\'dan değiştirin.',
    ),
  ),
  Tip(
    Icons.widgets_outlined,
    tr(
      'Ana ekran bileşeni: okunmamışlar ve yanıt bekleyenler uygulamayı açmadan. Ayarlar → Ana ekran → Ekle.',
    ),
  ),
  Tip(
    Icons.insights_rounded,
    tr(
      'Haftalık özet: kimlerle en çok yazıştığınızı üstteki grafik düğmesinden görün.',
    ),
  ),
];

/// Bugün gösterilecek ipucu; hepsi görüldüyse ya da bugün biri kapatıldıysa null.
Tip? tipForToday(LocalPrefs prefs, DateTime now) {
  final index = prefs.tipIndex;
  if (index >= tips.length) return null;
  final last = prefs.tipDismissedAt;
  if (last != null &&
      last.year == now.year &&
      last.month == now.month &&
      last.day == now.day) {
    return null;
  }
  return tips[index];
}

/// Gelen kutusundaki ipucu kartı.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip, required this.onDone});

  final Tip tip;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tip.icon, color: scheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Günün ipucu'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tip.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onDone, child: Text(tr('Anladım'))),
            ),
          ],
        ),
      ),
    );
  }
}
