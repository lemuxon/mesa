import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/models.dart';
import '../ui/avatars.dart';
import '../ui/theme.dart';

/// Haftalık özet: kaç mesaj, hangi günler, hangi uygulamalar, en çok
/// yazışılan kişiler. Tüm uygulamaları bir arada gören tek yer burası.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.bridge, this.onOpen});

  final CoreBridge bridge;

  /// En çok yazışılanlardan birine dokunulunca o sohbet açılır.
  final ValueChanged<String>? onOpen;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  WeeklyStats? _stats;

  @override
  void initState() {
    super.initState();
    widget.bridge.stats().then((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Haftalık özet'))),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _Hero(stats: stats),
                const SizedBox(height: 12),
                _Card(
                  title: tr('Günlere göre'),
                  child: _DayBars(perDay: stats.perDay),
                ),
                if (stats.perApp.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Card(
                    title: tr('Uygulamalar'),
                    child: _AppShare(perApp: stats.perApp, total: stats.total),
                  ),
                ],
                if (stats.top.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Card(
                    title: tr('En çok yazıştıkların'),
                    child: Column(
                      children: [
                        for (final (i, t) in stats.top.indexed)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ConversationAvatar(
                              title: t.title,
                              packageName: t.packageName,
                              avatarPath: t.avatarPath,
                              size: 44,
                            ),
                            title: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              tr('{count} mesaj · {name}', {
                                'count': t.count,
                                'name': MessagingApp.of(t.packageName).name,
                              }),
                            ),
                            trailing: Text(
                              const ['🥇', '🥈', '🥉'].elementAtOrNull(i) ??
                                  '${i + 1}.',
                              style: const TextStyle(fontSize: 22),
                            ),
                            onTap: widget.onOpen == null
                                ? null
                                : () => widget.onOpen!(t.key),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _Facts(stats: stats),
              ],
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.stats});

  final WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Son 7 gün'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('{total} mesaj', {'total': stats.total}),
            style: theme.textTheme.displaySmall?.copyWith(
              color: white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _HeroFact(
                icon: Icons.south_west_rounded,
                text: tr('{incoming} gelen', {'incoming': stats.incoming}),
              ),
              _HeroFact(
                icon: Icons.north_east_rounded,
                text: tr('{outgoing} giden', {'outgoing': stats.outgoing}),
              ),
              _HeroFact(
                icon: Icons.people_alt_rounded,
                text: tr('{people} kişi', {'people': stats.people}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.white),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Son 7 günün mesaj sayısı: tek seri, tek renk; bugün koyu, diğerleri açık.
/// Değer yalnızca bugün ve en yoğun günde yazılı; dokununca o günün sayısı.
class _DayBars extends StatefulWidget {
  const _DayBars({required this.perDay});

  final Map<String, int> perDay;

  @override
  State<_DayBars> createState() => _DayBarsState();
}

class _DayBarsState extends State<_DayBars> {
  int? _selected;

  static List<String> get _short => [
    tr('Pzt'),
    tr('Sal'),
    tr('Çar'),
    tr('Per'),
    tr('Cum'),
    tr('Cmt'),
    tr('Paz'),
  ];

  static String _keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final counts = [for (final d in days) widget.perDay[_keyOf(d)] ?? 0];
    final max = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final peak = max == 0 ? -1 : counts.indexOf(max);
    final bar = theme.brightness == Brightness.dark
        ? const Color(0xFF8C9EFF)
        : AppTheme.brand;
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _selected = _selected == i ? null : i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (i == 6 || i == peak || i == _selected)
                      Text(
                        '${counts[i]}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 18,
                      height: max == 0
                          ? 2
                          : (96 * counts[i] / max).clamp(2, 96).toDouble(),
                      decoration: BoxDecoration(
                        color: i == 6 || i == _selected
                            ? bar
                            : bar.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i == 6 ? tr('Bugün') : _short[days[i].weekday - 1],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: i == 6 ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Uygulamalara göre pay: kimliği simge ve ad taşır, çubuk tek renk.
class _AppShare extends StatelessWidget {
  const _AppShare({required this.perApp, required this.total});

  final List<(String, int)> perApp;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bar = theme.brightness == Brightness.dark
        ? const Color(0xFF8C9EFF)
        : AppTheme.brand;
    return Column(
      children: [
        for (final (package, count) in perApp.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                AppIcon(packageName: package, size: 24),
                const SizedBox(width: 10),
                SizedBox(
                  width: 84,
                  child: Text(
                    MessagingApp.of(package).name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : count / total,
                      minHeight: 8,
                      color: bar,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    tr('%{percent}', {
                      'percent': total == 0 ? 0 : (100 * count / total).round(),
                    }),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.stats});

  final WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    final hour = stats.busiestHour;
    final facts = <(IconData, String)>[
      if (hour != null)
        (
          Icons.schedule_rounded,
          tr('En yoğun saatin {hour}:00', {
            'hour': hour.toString().padLeft(2, '0'),
          }),
        ),
      if (stats.incoming > 0)
        (
          Icons.reply_rounded,
          tr('Gelen her 10 mesaja {ratio} yanıt', {
            'ratio': (10 * stats.outgoing / stats.incoming).toStringAsFixed(1),
          }),
        ),
      if (stats.deleted > 0)
        (
          Icons.restore_from_trash_rounded,
          tr('Gönderenin silip sende kalan {deleted} mesaj', {
            'deleted': stats.deleted,
          }),
        ),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: tr('Bilgiler'),
      child: Column(
        children: [
          for (final (icon, text) in facts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: AppTheme.brandEnd),
              title: Text(text),
            ),
        ],
      ),
    );
  }
}
