import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/stored_labels.dart';
import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../ui/avatars.dart';
import '../ui/bidi.dart';

/// Tüm uygulamalardan kaydedilen (yıldızlanan) mesajlar tek listede.
/// Saklama süresi bunları silmez.
class StarredScreen extends StatefulWidget {
  const StarredScreen({super.key, required this.bridge, this.onOpen});

  final CoreBridge bridge;

  /// Mesaja dokununca sohbeti açar.
  final ValueChanged<String>? onOpen;

  @override
  State<StarredScreen> createState() => _StarredScreenState();
}

class _StarredScreenState extends State<StarredScreen> {
  List<StarredMessage>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.bridge.starred();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _unstar(StarredMessage m) async {
    await widget.bridge.starMessage(m.id, false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Kaydedilenler'))),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 56,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('Henüz kaydedilen mesaj yok'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        'Bir mesaja basılı tutup "Kaydet"e dokunun. Adres, kod, tarih gibi önemli mesajlar hangi uygulamadan gelirse gelsin burada toplanır.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = items[i];
                final who = m.outgoing ? tr('Siz') : (m.sender ?? m.title);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onOpen == null
                        ? null
                        : () => widget.onOpen!(m.key),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIcon(packageName: m.packageName, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.title} · ${MessagingApp.of(m.packageName).name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (m.mediaPath != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(m.mediaPath!),
                                        height: 120,
                                        fit: BoxFit.cover,
                                        cacheHeight: 240,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                Text(
                                  localizeStored(m.text),
                                  textDirection: textDirectionOf(m.text),
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$who · ${formatDayLabel(m.time, DateTime.now())} '
                                  '${formatClock(m.time)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _unstar(m),
                            icon: const Icon(Icons.bookmark_remove_outlined),
                            tooltip: tr('Kaydedilenlerden çıkar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
