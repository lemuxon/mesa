import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/models.dart';
import '../core/telegram.dart';
import '../ui/avatars.dart';
import 'media_viewer.dart';

enum _MediaFilter { all, photos, videos }

/// Bir sohbette (kişi ekranında kişinin tüm uygulamalarında) paylaşılan
/// fotoğraf ve videolar, aylara göre. Gönderenin sildiği medya girmez.
class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({
    super.key,
    required this.bridge,
    required this.title,
    required this.members,
  });

  final CoreBridge bridge;
  final String title;

  /// Galerisi gösterilen sohbetler (kişi ekranında birden çok).
  final List<Conversation> members;

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<MediaItem>? _items;
  _MediaFilter _filter = _MediaFilter.all;

  late final Map<String, String> _packageOf = {
    for (final m in widget.members) m.key: m.packageName,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.bridge.media([
      for (final m in widget.members) m.key,
    ]);
    if (mounted) setState(() => _items = items);
  }

  Future<void> _toggleStar(MediaItem item) async {
    final m = item.message;
    await widget.bridge.starMessage(m.id, !m.starred);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            m.starred ? tr('Kaydedilenlerden çıkarıldı.') : tr('Kaydedildi ⭐'),
          ),
        ),
      );
    await _load();
  }

  Conversation? _memberOfMessage(Message m, List<MediaItem> shown) {
    final key = shown.where((i) => i.message.id == m.id).firstOrNull?.key;
    return widget.members.where((c) => c.key == key).firstOrNull;
  }

  /// Açılan medyadan galerideki diğerlerine (ekrandaki sırayla) kaydırılır.
  void _open(MediaItem item, List<MediaItem> shown) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaViewer(
          bridge: widget.bridge,
          message: item.message,
          gallery: [for (final i in shown) i.message],
          titleOf: (m) => m.outgoing ? tr('Siz') : (m.sender ?? widget.title),
          sourceAppOf: (m) {
            final member = _memberOfMessage(m, shown);
            return member == null || isTelegramKey(member.key)
                ? null
                : MessagingApp.of(member.packageName).name;
          },
          onOpenInApp: (m) {
            final member = _memberOfMessage(m, shown);
            if (member != null) widget.bridge.openInSourceApp(member);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;
    final shown = items == null
        ? const <MediaItem>[]
        : switch (_filter) {
            _MediaFilter.all => items,
            _MediaFilter.photos =>
              items.where((i) => !i.message.isVideo).toList(),
            _MediaFilter.videos =>
              items.where((i) => i.message.isVideo).toList(),
          };
    final months = _byMonth(shown);
    final showApp = _packageOf.values.toSet().length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Medya')),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final (filter, label) in [
                          (_MediaFilter.all, tr('Tümü')),
                          (_MediaFilter.photos, tr('Fotoğraflar')),
                          (_MediaFilter.videos, tr('Videolar')),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                      ],
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyGallery(),
                  ),
                for (final (label, monthItems) in months) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(label, style: theme.textTheme.titleSmall),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                      itemCount: monthItems.length,
                      itemBuilder: (context, i) {
                        final item = monthItems[i];
                        return _MediaTile(
                          key: ValueKey('media-${item.message.id}'),
                          item: item,
                          packageName: showApp ? _packageOf[item.key] : null,
                          onTap: () => _open(item, shown),
                          onLongPress: () => _toggleStar(item),
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }
}

List<String> get _months => [
  tr('Ocak'),
  tr('Şubat'),
  tr('Mart'),
  tr('Nisan'),
  tr('Mayıs'),
  tr('Haziran'),
  tr('Temmuz'),
  tr('Ağustos'),
  tr('Eylül'),
  tr('Ekim'),
  tr('Kasım'),
  tr('Aralık'),
];

/// Yeniden eskiye sıralı öğeleri aylara böler ("Ekim 2026").
List<(String, List<MediaItem>)> _byMonth(List<MediaItem> items) {
  final groups = <(String, List<MediaItem>)>[];
  for (final item in items) {
    final t = item.message.time;
    final label = '${_months[t.month - 1]} ${t.year}';
    if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
    groups.last.$2.add(item);
  }
  return groups;
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    super.key,
    required this.item,
    required this.packageName,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaItem item;

  /// Kişi galerisinde medyanın geldiği uygulama; tek sohbette null.
  final String? packageName;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final m = item.message;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width / 3;
    final app = packageName;
    return Semantics(
      button: true,
      label: m.isVideo ? tr('Video') : tr('Fotoğraf'),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerHighest),
            Image.file(
              File(m.mediaPath!),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // Kare boyutunda çözülür: galeri kaydırılırken takılmasın.
              cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (_, _, _) =>
                  Icon(Icons.broken_image_outlined, color: scheme.outline),
            ),
            if (m.isVideo)
              const Positioned(
                left: 6,
                bottom: 6,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 22,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            if (m.starred)
              const Positioned(
                right: 6,
                bottom: 6,
                child: Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 18,
                  shadows: [Shadow(blurRadius: 4)],
                ),
              ),
            if (app != null)
              Positioned(
                right: 5,
                top: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Tooltip(
                      message: MessagingApp.of(app).name,
                      child: AppIcon(packageName: app, size: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            tr('Henüz fotoğraf ya da video yok'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'Bildiriminde önizlemesi gelen fotoğraflar ve Telegram medyası burada toplanır.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
