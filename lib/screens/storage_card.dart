import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/format.dart';
import '../ui/large_title.dart';

/// Ayarlar'da "Depolama": neyin ne kadar yer kapladığı ve önbellek temizliği.
/// Mesajlar, kişiler, kurallar ve oturumlar silinmez.
class StorageCard extends StatefulWidget {
  const StorageCard({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<StorageCard> createState() => _StorageCardState();
}

class _StorageCardState extends State<StorageCard> {
  Map<String, int>? _usage;
  bool _cleaning = false;

  static List<(String, IconData, String)> get _labels => [
    ('database', Icons.chat_outlined, tr('Mesajlar')),
    ('media', Icons.photo_outlined, tr('Fotoğraflar ve profil resimleri')),
    ('telegram', Icons.send_outlined, tr('Telegram önbelleği')),
    ('web', Icons.language_rounded, tr('Web servisleri')),
    ('temporary', Icons.hourglass_empty_rounded, tr('Geçici dosyalar')),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usage = await widget.bridge.storageUsage();
      if (mounted) setState(() => _usage = usage);
    } catch (_) {
      // Eski yerel taraf ya da test: bölüm gösterilmez.
    }
  }

  Future<void> _clean() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Önbellek temizlensin mi?')),
        content: Text(
          tr(
            'Telegram\'da 7 gündür açılmamış fotoğraf ve videolar, web servislerinin önbelleği ve geçici dosyalar silinir. Mesajlar, kişiler ve oturumlar silinmez; Telegram medyası açınca yeniden iner.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Temizle')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cleaning = true);
    var freed = 0;
    try {
      freed = await widget.bridge.cleanStorage();
    } catch (_) {
      // Temizlenemedi: aşağıda yine yeniden okunur.
    }
    await _load();
    if (!mounted) return;
    setState(() => _cleaning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          freed > 0
              ? tr('{freed} yer açıldı.', {'freed': formatSize(freed)})
              : tr('Temizlenecek önbellek yoktu.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;
    if (usage == null) return const SizedBox.shrink();
    final total = usage.values.fold(0, (a, b) => a + b);
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Depolama · ${formatSize(total)}',
      children: [
        for (final (key, icon, label) in _labels)
          ListTile(
            dense: true,
            leading: Icon(icon),
            title: Text(label),
            trailing: Text(
              formatSize(usage[key] ?? 0),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr('Eski mesajları silmek için: saklama süresi.'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _cleaning ? null : _clean,
                icon: _cleaning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cleaning_services_outlined),
                label: Text(tr('Önbelleği temizle')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
