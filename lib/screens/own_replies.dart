import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/bridge.dart';

/// WhatsApp'tan yazılan yanıtları yakalayan erişilebilirlik servisinin
/// izlediği uygulamalar (yerel taraf: OwnReplies.kt).
const ownReplyPackages = {'com.whatsapp', 'com.whatsapp.w4b'};

/// Ne olacağını anlatır; onaylanırsa Android'in Erişilebilirlik ayarı açılır.
/// Servis yalnızca orada açılıp kapatılabilir.
Future<void> enableOwnReplies(BuildContext context, CoreBridge bridge) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.forum_outlined),
      title: Text(tr('WhatsApp\'ta yazdıklarınız da görünsün')),
      content: SingleChildScrollView(
        child: Text(
          tr(
            'WhatsApp\'ta Gönder\'e bastığınızda yazdığınız mesaj Mesa\'daki aynı sohbete eklenir; WhatsApp\'ta açtığınız sohbet burada da okunmuş sayılır.\n\nAçılan sayfada "Mesa: WhatsApp yanıtlarım"ı açın. Yalnızca WhatsApp okunur ve hiçbir şey telefondan çıkmaz.\n\nAyar soluk görünüyorsa: Uygulama bilgisi → ⋮ → Kısıtlanmış ayarlara izin ver.',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr('Vazgeç')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr('Ayarı aç')),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await bridge.openOwnRepliesSettings();
  } catch (_) {
    // Eski yerel taraf: ayar sayfası yok.
  }
}

/// Servis açık mı; okunamazsa (eski yerel taraf, test) açık sayılır ki
/// öneri boşuna görünmesin.
Future<bool> ownRepliesEnabled(CoreBridge bridge) async {
  try {
    return await bridge.ownRepliesEnabled();
  } catch (_) {
    return true;
  }
}

/// WhatsApp sohbetinde, yanıtlar yalnızca gelen taraftan görünürken çıkan öneri.
class OwnRepliesNudge extends StatelessWidget {
  const OwnRepliesNudge({
    super.key,
    required this.onEnable,
    required this.onDismiss,
  });

  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(Icons.forum_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(
                  'WhatsApp\'tan yazdığınız yanıtlar burada görünmüyor. Görünsün mü?',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(onPressed: onEnable, child: Text(tr('Aç'))),
            IconButton(
              tooltip: tr('Kapat'),
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
