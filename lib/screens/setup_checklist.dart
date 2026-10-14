import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../core/telegram.dart';
import 'telegram_screen.dart';

/// Uygulamanın (ve aynı adı taşıyan eşinin, ör. WhatsApp Business) kendi
/// bildirimi çubukta kalsın: yanıtlar uygulama yeniden başlasa da kaynak
/// uygulamaya geçmeden gider.
Future<void> keepSourceFor(CoreBridge bridge, String packageName) async {
  final settings = await bridge.settings();
  final packages =
      MessagingApp.packagesByName[MessagingApp.of(packageName).name] ??
      [packageName];
  await bridge.updateSettings(
    settings.copyWith(
      keepSourcePackages: {...settings.keepSourcePackages, ...packages},
    ),
  );
}

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final bool done;
  final Future<void> Function() onTap;
}

/// Gelen kutusunun üstünde "Kurulumu tamamla": mesajların eksiksiz ve
/// gecikmesiz gelmesi için gereken ayarlar, ilerlemesiyle. Her adım tek
/// dokunuş; hepsi tamamlanınca kart kaybolur. Sistemin bize söylemediği
/// adımlar (Xiaomi otomatik başlatma, son uygulamalarda kilit) elle onaylanır.
class SetupChecklist extends StatefulWidget {
  const SetupChecklist({
    super.key,
    required this.bridge,
    required this.prefs,
    required this.health,
    required this.settings,
    required this.usesWhatsApp,
    required this.onChanged,
    this.telegram,
  });

  final CoreBridge bridge;
  final LocalPrefs prefs;
  final SystemHealth health;
  final AppSettings settings;

  /// Gelen kutusunda WhatsApp sohbeti var mı (doğrudan yanıt adımı için).
  final bool usesWhatsApp;
  final TelegramStatus? telegram;

  /// Bir adım değişti: gelen kutusu durumu yeniden okusun.
  final VoidCallback onChanged;

  List<_Step> get _steps => [
    _Step(
      icon: Icons.notifications_active_outlined,
      title: tr('Birleşik bildirimler'),
      subtitle: tr('Tüm mesajlar tek tip, buradan yanıtlanabilen bildirimle'),
      action: tr('Aç'),
      done: settings.unifiedNotifications,
      onTap: () async {
        await bridge.requestNotificationPermission();
        await bridge.updateSettings(
          (await bridge.settings()).copyWith(unifiedNotifications: true),
        );
      },
    ),
    _Step(
      icon: Icons.notifications_outlined,
      title: tr('Bildirim izni'),
      subtitle: tr('Kapalıysa yeni mesajları fark etmezsiniz'),
      action: tr('Aç'),
      done: health.notificationsAllowed,
      onTap: () async {
        await bridge.requestNotificationPermission();
        await bridge.openNotificationSettings();
      },
    ),
    _Step(
      icon: Icons.battery_full_rounded,
      title: tr('Pil kısıtlamasını kaldır'),
      subtitle: tr('Arka planda kapatılmasın, mesajlar gecikmesin'),
      action: tr('Kaldır'),
      done: health.batteryUnrestricted,
      onTap: bridge.openBatterySettings,
    ),
    if (health.xiaomi) ...[
      _Step(
        icon: Icons.rocket_launch_outlined,
        title: tr('Otomatik başlatma'),
        subtitle: tr('Telefon yeniden açılınca da çalışsın'),
        action: tr('Aç'),
        done: prefs.autostartConfirmed,
        onTap: () async {
          await bridge.openAutostartSettings();
          await prefs.confirmAutostart();
        },
      ),
      _Step(
        icon: Icons.lock_outline_rounded,
        title: tr('Son uygulamalarda kilitle'),
        subtitle: tr(
          'Son uygulamalarda karta basılı tutup kilide dokunun; kilitsizken kaydırınca kapanıyor',
        ),
        action: tr('Yaptım'),
        done: prefs.recentsLockConfirmed,
        onTap: prefs.confirmRecentsLock,
      ),
    ],
    if (usesWhatsApp && settings.unifiedNotifications)
      _Step(
        icon: Icons.send_rounded,
        title: tr('WhatsApp\'a geçmeden yanıt'),
        subtitle: tr('Uygulama yeniden başlasa da yanıtlar doğrudan gitsin'),
        action: tr('Aç'),
        done: settings.keepSourcePackages.contains('com.whatsapp'),
        onTap: () => keepSourceFor(bridge, 'com.whatsapp'),
      ),
  ];

  /// Kart gösterilmeli mi: eksik adım var ve kullanıcı ertelemedi.
  bool visible(DateTime now) {
    final snoozed = prefs.setupSnoozedUntil;
    if (snoozed != null && now.isBefore(snoozed)) return false;
    return _steps.any((s) => !s.done);
  }

  @override
  State<SetupChecklist> createState() => _SetupChecklistState();
}

class _SetupChecklistState extends State<SetupChecklist> {
  /// Varsayılan yalnızca sıradaki adım: gelen kutusu her gün açılıyor,
  /// kart sohbetleri aşağı itmesin.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final steps = w._steps;
    final done = steps.where((s) => s.done).length;
    if (done == steps.length) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = steps.where((s) => !s.done).toList();
    final shown = _expanded ? pending : pending.take(1);
    final telegram = w.telegram;
    final telegramPending =
        telegram != null &&
        telegram.configured &&
        telegram.state != TelegramState.ready;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Kurulumu tamamla · {done}/{count}', {
                          'done': done,
                          'count': steps.length,
                        }),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        tr('Mesajlar eksiksiz ve gecikmeden gelsin'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: tr('Sonra'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () async {
                    await w.prefs.snoozeSetup(
                      DateTime.now().add(const Duration(days: 3)),
                    );
                    w.onChanged();
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: done / steps.length,
                  minHeight: 5,
                ),
              ),
            ),
            for (final step in shown)
              ListTile(
                contentPadding: const EdgeInsets.only(right: 8),
                leading: Icon(step.icon, color: scheme.primary),
                title: Text(step.title),
                subtitle: Text(step.subtitle),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    await step.onTap();
                    w.onChanged();
                  },
                  child: Text(step.action),
                ),
              ),
            if (_expanded && telegramPending)
              ListTile(
                contentPadding: const EdgeInsets.only(right: 8),
                leading: Icon(Icons.send_outlined, color: scheme.outline),
                title: Text(tr('Telegram\'ı bağla · isteğe bağlı')),
                subtitle: Text(tr('Sessiz gruplar ve geçmiş de gelsin')),
                trailing: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TelegramScreen(bridge: w.bridge),
                      ),
                    );
                    w.onChanged();
                  },
                  child: Text(tr('Bağla')),
                ),
              ),
            if (pending.length > 1 || (telegramPending && !_expanded))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? tr('Daha az göster')
                        : pending.length > 1
                        ? tr('{pending} adım daha', {
                            'pending': pending.length - 1,
                          })
                        : tr('İsteğe bağlı adımlar'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
