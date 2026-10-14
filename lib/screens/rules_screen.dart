import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/rules.dart';
import '../ui/large_title.dart';
import 'rule_edit_screen.dart';

/// Otomatik kuralların listesi; aç/kapat, düzenle, ekle.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  List<Rule>? _rules;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await widget.bridge.rules();
    if (!mounted) return;
    setState(() => _rules = rules);
  }

  Future<void> _toggle(Rule rule, bool enabled) async {
    await widget.bridge.saveRule(rule.withEnabled(enabled));
    await _load();
  }

  Future<void> _edit([Rule? rule]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RuleEditScreen(bridge: widget.bridge, rule: rule),
      ),
    );
    if (changed ?? false) await _load();
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Kurallar nasıl çalışır?'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                tr(
                  'Kurallar uygulama kapalıyken de, yeni mesaj gelir gelmez çalışır.\n\nOtomatik yanıt güvenliği: aynı anda gelen mesajlara tek yanıt; aynı sohbete bekleme süresi dolmadan tekrar yanıt yok; tüm sohbetlerde saatte en fazla 20 yanıt.\n\nYanıt, kaynak uygulamanın bildirimi üzerinden (Telegram\'da doğrudan) gider; bildirim yoksa gönderilmez.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    final active = rules?.where((r) => r.enabled).length ?? 0;
    return Scaffold(
      appBar: largeTitleAppBar(
        context,
        title: tr('Kurallar'),
        subtitle: rules == null || rules.isEmpty
            ? tr('Otomatik yanıt, sessize alma, önemli işaretleme')
            : tr('{active} etkin kural', {'active': active}),
        actions: [
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: tr('Kurallar nasıl çalışır?'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('Kural ekle')),
      ),
      body: rules == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _Templates(onPick: _edit),
                if (rules.isEmpty)
                  const _EmptyState()
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      tr('Kurallarınız'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final rule in rules)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _RuleCard(
                        rule: rule,
                        onTap: () => _edit(rule),
                        onToggle: (v) => _toggle(rule, v),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onTap,
    required this.onToggle,
  });

  final Rule rule;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  Color _actionColor(ColorScheme scheme) => switch (rule.action) {
    RuleAction.autoReply => scheme.primary,
    RuleAction.mute => const Color(0xFF78909C),
    RuleAction.important => const Color(0xFFFFA000),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _actionColor(scheme);
    final conditions = describeConditions(rule, (p) => MessagingApp.of(p).name);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: rule.enabled ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(rule.action.icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${rule.action.label} · $conditions',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (rule.recentFires > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tr('Son 7 günde {recentFires} kez çalıştı', {
                              'recentFires': rule.recentFires,
                            }),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(value: rule.enabled, onChanged: onToggle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget example(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        children: [
          Icon(
            Icons.auto_mode_rounded,
            size: 56,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            tr('Henüz kural yok'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Yukarıdaki hazır kurallardan birine dokunun ya da kendiniz ekleyin.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          example(
            Icons.star_outline_rounded,
            tr('WhatsApp\'ta "acil" geçen mesajları önemli işaretle'),
          ),
          example(
            Icons.notifications_off_outlined,
            tr('İş grubunu sessize al'),
          ),
          example(
            Icons.reply_rounded,
            tr('Gece 23:00–08:00 arası "Sabah yazarım" diye yanıtla'),
          ),
        ],
      ),
    );
  }
}

/// Tek dokunuşla eklenen hazır kurallar (düzenleyicide açılır, kaydedince eklenir).
class _Templates extends StatelessWidget {
  const _Templates({required this.onPick});

  final ValueChanged<Rule> onPick;

  static List<(String, String, IconData, Color, Rule)> get templates => [
    (
      tr('Gece modu'),
      tr('23:00–08:00 otomatik yanıt'),
      Icons.bedtime_rounded,
      Color(0xFF5E35B1),
      Rule(
        name: tr('Gece otomatik yanıt'),
        action: RuleAction.autoReply,
        replyText: tr('Şu an uyuyorum, sabah dönerim 🌙'),
        cooldownMinutes: 360,
        activeFrom: 23 * 60,
        activeTo: 8 * 60,
      ),
    ),
    (
      tr('Meşgulüm'),
      tr('Herkese kısa yanıt'),
      Icons.do_not_disturb_on_rounded,
      Color(0xFFE53935),
      Rule(
        name: tr('Meşgulüm'),
        action: RuleAction.autoReply,
        replyText: tr('Şu an müsait değilim, birazdan yazarım.'),
        cooldownMinutes: 60,
      ),
    ),
    (
      tr('Mesai dışı'),
      tr('Hafta içi 18:00–09:00'),
      Icons.work_off_rounded,
      Color(0xFF00897B),
      Rule(
        name: tr('Mesai dışı yanıt'),
        action: RuleAction.autoReply,
        replyText: tr('Mesai saatleri dışındayım, yarın dönüş yapacağım.'),
        cooldownMinutes: 360,
        activeFrom: 18 * 60,
        activeTo: 9 * 60,
        activeDays: 0x1f,
      ),
    ),
    (
      tr('Acil mesajlar'),
      tr('"acil", "hemen" geçenleri öne çıkar'),
      Icons.priority_high_rounded,
      Color(0xFFFFA000),
      Rule(
        name: tr('Acil mesajlar'),
        action: RuleAction.important,
        keywords: [tr('acil'), tr('hemen'), tr('önemli'), tr('ara beni')],
        includeGroups: true,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            tr('Hazır kurallar'),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (title, subtitle, icon, color, rule) = templates[i];
              return SizedBox(
                width: 150,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onPick(rule),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const Spacer(),
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
