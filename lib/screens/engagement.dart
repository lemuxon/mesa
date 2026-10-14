import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../ui/avatars.dart';
import '../ui/theme.dart';

/// "Sonra" seçici: 1 saat, 3 saat, bu akşam, yarın sabah ya da özel zaman.
/// Sonra hatırlat ve planlı mesaj aynı seçiciyi kullanır.
Future<DateTime?> pickLaterTime(
  BuildContext context, {
  required String title,
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  final today = DateTime(at.year, at.month, at.day);
  final evening = today.add(const Duration(hours: 20));
  final tomorrowMorning = today.add(const Duration(days: 1, hours: 9));
  final options = <(IconData, String, DateTime)>[
    (
      Icons.timer_outlined,
      tr('1 saat sonra'),
      at.add(const Duration(hours: 1)),
    ),
    (
      Icons.more_time_rounded,
      tr('3 saat sonra'),
      at.add(const Duration(hours: 3)),
    ),
    if (evening.isAfter(at.add(const Duration(minutes: 30))))
      (Icons.nights_stay_outlined, tr('Bu akşam'), evening),
    (Icons.wb_sunny_outlined, tr('Yarın sabah'), tomorrowMorning),
  ];
  final choice = await showModalBottomSheet<Object>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final (icon, label, time) in options)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: Text(
                formatWhen(time, at),
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: () => Navigator.of(context).pop(time),
            ),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined),
            title: Text(tr('Tarih ve saat seç')),
            onTap: () => Navigator.of(context).pop('custom'),
          ),
        ],
      ),
    ),
  );
  if (choice is DateTime) return choice;
  if (choice != 'custom' || !context.mounted) return null;
  final date = await showDatePicker(
    context: context,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
    initialDate: today,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(at.add(const Duration(hours: 1))),
  );
  if (time == null) return null;
  final picked = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  return picked.isAfter(at) ? picked : null;
}

/// Sohbetler'in üstünde: size yazıp yanıt bekleyenler ve ne kadardır beklediği.
class WaitingStrip extends StatelessWidget {
  const WaitingStrip({
    super.key,
    required this.people,
    required this.onOpen,
    required this.onLongPress,
  });

  final List<WaitingPerson> people;
  final ValueChanged<WaitingPerson> onOpen;
  final ValueChanged<WaitingPerson> onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 16,
                color: AppTheme.brandEnd,
              ),
              const SizedBox(width: 6),
              Text(
                tr('Yanıt bekliyor · {count}', {'count': people.length}),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final p = people[i];
              final waited = now.difference(p.lastTime);
              // Uzun bekleyenler daha belirgin: 3 saati geçince turuncu halka.
              final ring = waited.inHours >= 3
                  ? const Color(0xFFFF8F00)
                  : AppTheme.brand;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpen(p),
                onLongPress: () => onLongPress(p),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [ring, AppTheme.brandEnd],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                          ),
                          child: ConversationAvatar(
                            title: p.title,
                            packageName: p.packageName,
                            avatarPath: p.avatarPath,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.title.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        formatWaiting(p.lastTime, now),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ring,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

/// Ertelenmiş sohbetler: ne zaman hatırlatılacağı, hemen geri getirme.
Future<void> showSnoozedSheet(
  BuildContext context,
  CoreBridge bridge,
  List<SnoozedConversation> snoozed,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            tr('Ertelenen sohbetler'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final s in snoozed)
          ListTile(
            leading: AppIcon(packageName: s.packageName, size: 32),
            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '⏰ ${formatWhen(s.until, DateTime.now())} · '
              '${MessagingApp.of(s.packageName).name}',
            ),
            trailing: TextButton(
              onPressed: () async {
                await bridge.unsnooze(s.key);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(tr('Şimdi göster')),
            ),
          ),
      ],
    ),
  ),
);
