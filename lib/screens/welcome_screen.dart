import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../ui/mesa_logo.dart';

/// Bildirim erişimi verilmemişken gösterilen tanıtım ve izin ekranı.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGrant,
    this.restrictedSettings = false,
    this.onAppInfo,
  });

  final VoidCallback onGrant;

  /// Android 13+ mağaza dışı kurulum: erişim anahtarı gri kalabilir, önce
  /// uygulama bilgilerinden kısıtlanmış ayarlara izin verilmeli.
  final bool restrictedSettings;
  final VoidCallback? onAppInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          const Center(child: MesaLogo()),
          const SizedBox(height: 24),
          Text(
            tr('Tüm mesajların tek yerde'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'WhatsApp, Telegram, Instagram, Discord ve diğerleri tek gelen kutusunda; uygulamalar arasında gidip gelmeden.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          _Feature(
            icon: Icons.people_alt_outlined,
            title: tr('Bir kişi, tek sohbet'),
            text: tr(
              'Aynı kişiyle WhatsApp\'tan, Instagram\'dan, Telegram\'dan yazıştıklarınız tek zaman çizgisinde; yanıtı istediğiniz uygulamadan verin.',
            ),
          ),
          _Feature(
            icon: Icons.visibility_off_outlined,
            title: tr('Görüldü göndermeden oku'),
            text: tr(
              'WhatsApp ve Instagram mesajlarını burada okumak karşı tarafa "görüldü" göndermez; Telegram\'da da isteğe bağlı.',
            ),
          ),
          _Feature(
            icon: Icons.restore_rounded,
            title: tr('Silinen mesajın yazısı kalır'),
            text: tr(
              'Gönderen "herkesten sil" dese de yazdığı metin burada "silindi" etiketiyle durur.',
            ),
          ),
          _Feature(
            icon: Icons.schedule_send_outlined,
            title: 'Unutma, ertele, planla',
            text: tr(
              'Yanıt bekleyenler en üstte; sohbeti sonraya ertele, mesajı istediğin saate planla.',
            ),
          ),
          _Feature(
            icon: Icons.lock_outline_rounded,
            title: tr('Telefonunda kalır'),
            text: tr(
              'Mesajlar yalnızca bu telefonda saklanır; hiçbir sunucuya gönderilmez.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onGrant,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(tr('Bildirim erişimini aç')),
          ),
          const SizedBox(height: 12),
          Text(
            tr(
              'Mesa mesajları uygulamaların bildirimlerinden okur. Açılan listede Mesa\'yı bulup izin verin.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (restrictedSettings) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('İzin verilemiyor mu?'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'Android, mağaza dışından kurulan uygulamalarda bu izni kısıtlar. Mesa\'nın anahtarına bir kez dokunun, sonra Uygulama bilgileri → ⋮ → Kısıtlanmış ayarlara izin ver\'i seçip tekrar deneyin.',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: onAppInfo,
                      icon: const Icon(Icons.info_outline_rounded),
                      label: Text(tr('Uygulama bilgileri')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
