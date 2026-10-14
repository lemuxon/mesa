import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../ui/avatars.dart';
import '../ui/large_title.dart';
import '../ui/text_dialog.dart';
import 'backup_card.dart';
import 'language_tile.dart';
import 'storage_card.dart';
import 'telegram_screen.dart';

/// Kaynak uygulamalar, bildirim, gizlilik ve hazır yanıt ayarları.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  AppSettings? _settings;
  SystemHealth? _health;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.bridge.settings().then((s) {
      if (mounted) setState(() => _settings = s);
    });
    _loadHealth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Sistem ayarlarından dönünce durum yenilensin.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadHealth();
  }

  Future<void> _loadHealth() async {
    try {
      final health = await widget.bridge.health();
      if (mounted) setState(() => _health = health);
    } catch (_) {
      // Eski yerel taraf ya da test: kart gösterilmez.
    }
  }

  /// Her değişiklikte güncel ayarlar telefondan okunur ve yalnızca değişen
  /// alan yazılır. Sekmeler bellekte kaldığı için eldeki kopya eskimiş
  /// olabilir: gelen kutusundaki karttan açılan birleşik bildirimler, burada
  /// başka bir ayar değişince eski kopyayla geri kapanıyordu (2026-10-10).
  Future<void> _update(AppSettings Function(AppSettings) change) async {
    final updated = change(await widget.bridge.settings());
    if (mounted) setState(() => _settings = updated);
    await widget.bridge.updateSettings(updated);
  }

  Future<void> _toggleApp(List<String> packages, bool captured) => _update((s) {
    final disabled = {...s.disabledPackages};
    captured ? disabled.removeAll(packages) : disabled.addAll(packages);
    return s.copyWith(disabledPackages: disabled);
  });

  Future<void> _setRetention(int days) async {
    final current = _settings!;
    final shortens =
        days != 0 &&
        (current.retentionDays == 0 || days < current.retentionDays);
    if (shortens) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('Eski mesajlar silinsin mi?')),
          content: Text(
            tr(
              '{days} öncesine ait mesajlar ve görselleri Mesa\'dan kalıcı olarak silinecek. Kaynak uygulamalardaki mesajlara dokunulmaz.',
              {'days': retentionOptions[days]},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr('Vazgeç')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(tr('Sil')),
            ),
          ],
        ),
      );
      if (!(confirmed ?? false)) return;
    }
    await _update((s) => s.copyWith(retentionDays: days));
  }

  Future<void> _setUnifiedNotifications(bool value) async {
    if (value) await widget.bridge.requestNotificationPermission();
    await _update((s) => s.copyWith(unifiedNotifications: value));
  }

  /// Kendi bildirimi de kalabilecek uygulamalar (Telegram doğrudan bağlı).
  static Map<String, List<String>> get _keepableApps => {
    for (final e in MessagingApp.packagesByName.entries)
      if (!e.key.startsWith('Telegram')) e.key: e.value,
  };

  String _keptSummary(AppSettings settings) {
    final names = [
      for (final MapEntry(key: name, value: packages) in _keepableApps.entries)
        if (packages.any(settings.keepSourcePackages.contains)) name,
    ];
    return names.isEmpty
        ? tr(
            'Seçilen uygulamalarda yanıt, Mesa yeniden başlasa da doğrudan gider',
          )
        : names.join(', ');
  }

  Future<void> _pickKeptApps() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final kept = _settings?.keepSourcePackages ?? const <String>{};
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tr('Kendi bildirimi de kalsın'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tr(
                  'Seçtiğiniz uygulamanın bildirimi çubuktan kaldırılmaz. Bildirim orada durdukça, Mesa yeniden başlasa da (güncelleme, telefonun yeniden açılması) o sohbete yanıt ve planlı mesaj uygulamaya geçmeden gider. Aynı mesaj için iki bildirim görürsünüz; Mesa\'nınki sessiz gelir.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final MapEntry(key: name, value: packages)
                in _keepableApps.entries)
              CheckboxListTile(
                secondary: AppIcon(packageName: packages.first, size: 28),
                title: Text(name),
                value: packages.any(kept.contains),
                onChanged: (v) async {
                  await _update((s) {
                    final next = {...s.keepSourcePackages};
                    v == true
                        ? next.addAll(packages)
                        : next.removeAll(packages);
                    return s.copyWith(keepSourcePackages: next);
                  });
                  setSheetState(() {});
                },
              ),
          ],
        );
      },
    ),
  );

  /// Başlatıcı destekliyorsa sistemin "ana ekrana ekle" penceresi; yoksa tarif.
  Future<void> _pinWidget() async {
    var shown = false;
    try {
      shown = await widget.bridge.pinWidget();
    } catch (_) {
      // Eski yerel taraf: tarif gösterilir.
    }
    if (shown || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 8),
        content: Text(
          tr(
            'Ana ekranda boş bir yere basılı tutun → Bileşenler (Widget) → Mesa\'yı sürükleyip bırakın.',
          ),
        ),
      ),
    );
  }

  Future<void> _setImportantNotifications(bool value) async {
    if (value) await widget.bridge.requestNotificationPermission();
    await _update((s) => s.copyWith(importantNotifications: value));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final scope = AppScope.maybeOf(context);
    return Scaffold(
      appBar: largeTitleAppBar(context, title: tr('Ayarlar')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (_health case final health?)
                  _HealthCard(
                    health: health,
                    bridge: widget.bridge,
                    onChanged: _loadHealth,
                  ),
                LanguageTile(bridge: widget.bridge, prefs: scope?.prefs),
                SectionCard(
                  title: tr('Bildirimler'),
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      title: Text(tr('Birleşik bildirimler')),
                      subtitle: Text(
                        tr(
                          'Uygulamaların ayrı bildirimleri yerine kişi fotoğraflı, yanıtlanabilen tek tip bildirim',
                        ),
                      ),
                      value: settings.unifiedNotifications,
                      onChanged: _setUnifiedNotifications,
                    ),
                    if (settings.unifiedNotifications)
                      ListTile(
                        leading: const Icon(Icons.layers_outlined),
                        title: Text(tr('Kendi bildirimi de kalsın')),
                        subtitle: Text(_keptSummary(settings)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickKeptApps,
                      ),
                    SwitchListTile(
                      secondary: const Icon(Icons.star_outline_rounded),
                      title: Text(tr('Önemli mesajlarda bildirim')),
                      subtitle: Text(
                        tr(
                          '"Önemli işaretle" kuralına uyunca, sessizdekiler dahil',
                        ),
                      ),
                      value: settings.importantNotifications,
                      onChanged: _setImportantNotifications,
                    ),
                  ],
                ),
                SectionCard(
                  title: tr('Ana ekran'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.widgets_outlined),
                      title: Text(tr('Ana ekran bileşeni')),
                      subtitle: Text(
                        tr(
                          'Okunmamışlar ve yanıt bekleyenler, uygulamayı açmadan',
                        ),
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: _pinWidget,
                        child: Text(tr('Ekle')),
                      ),
                    ),
                  ],
                ),
                StorageCard(bridge: widget.bridge),
                BackupCard(bridge: widget.bridge, prefs: scope?.prefs),
                SectionCard(
                  title: tr('Bağlantılar'),
                  children: [
                    ListTile(
                      leading: const AppIcon(
                        packageName: 'org.telegram.messenger',
                        size: 28,
                      ),
                      title: const Text('Telegram'),
                      subtitle: Text(
                        tr('Doğrudan bağlantı: sessiz gruplar ve geçmiş'),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TelegramScreen(bridge: widget.bridge),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined),
                      title: Text(tr('Telegram\'da gizli okuma')),
                      subtitle: Text(
                        tr('Okuduğunuzda "görüldü", yazarken "yazıyor" gitmez'),
                      ),
                      value: settings.telegramGhostRead,
                      onChanged: (v) =>
                          _update((s) => s.copyWith(telegramGhostRead: v)),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.campaign_outlined),
                      title: Text(tr('Telegram kanallarını gösterme')),
                      subtitle: Text(
                        tr('Kişiler ve gruplar gelmeye devam eder'),
                      ),
                      value: settings.hideTelegramChannels,
                      onChanged: (v) =>
                          _update((s) => s.copyWith(hideTelegramChannels: v)),
                    ),
                  ],
                ),
                SectionCard(
                  title: tr('Okunan uygulamalar'),
                  children: [
                    for (final MapEntry(key: name, value: packages)
                        in MessagingApp.packagesByName.entries)
                      SwitchListTile(
                        secondary: AppIcon(
                          packageName: packages.first,
                          size: 28,
                        ),
                        title: Text(name),
                        value: !packages.every(
                          settings.disabledPackages.contains,
                        ),
                        onChanged: (v) => _toggleApp(packages, v),
                      ),
                  ],
                ),
                SectionCard(
                  title: tr('Gizlilik'),
                  children: [
                    ListTile(
                      leading: Icon(Icons.visibility_off_rounded),
                      title: Text(tr('Görmeden okuma')),
                      subtitle: Text(
                        tr(
                          'WhatsApp, Instagram ve diğerlerinde mesajı burada okumak karşı tarafa "görüldü" göndermez. Yanıt verirseniz gider.',
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.restore_from_trash_rounded),
                      title: Text(tr('Silinen mesajlar korunur')),
                      subtitle: Text(
                        tr(
                          'Gönderen mesajı silse de metni burada "silindi" etiketiyle kalır.',
                        ),
                      ),
                    ),
                    if (scope != null)
                      _LockTile(scope: scope, bridge: widget.bridge),
                    ListTile(
                      leading: const Icon(Icons.auto_delete_outlined),
                      title: Text(tr('Mesajları sakla')),
                      subtitle: Text(
                        settings.retentionDays == 0
                            ? tr('Süresiz')
                            : tr('{retentionDays} sonra silinir', {
                                'retentionDays':
                                    retentionOptions[settings.retentionDays],
                              }),
                      ),
                      trailing: DropdownButton<int>(
                        value:
                            retentionOptions.containsKey(settings.retentionDays)
                            ? settings.retentionDays
                            : 0,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final MapEntry(key: days, value: label)
                              in retentionOptions.entries)
                            DropdownMenuItem(value: days, child: Text(label)),
                        ],
                        onChanged: (v) => _setRetention(v!),
                      ),
                    ),
                  ],
                ),
                if (scope != null)
                  SectionCard(
                    title: tr('Yazma'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bolt_outlined),
                        title: Text(tr('Hazır yanıtlar')),
                        subtitle: Text(
                          tr('{count} yanıt', {
                            'count': scope.prefs.quickReplies.length,
                          }),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuickRepliesScreen(
                                prefs: scope.prefs,
                                bridge: widget.bridge,
                              ),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

/// Kilidi açarken kimlik doğrulanır: kullanıcı kilitlenip dışarıda kalmasın.
class _LockTile extends StatefulWidget {
  const _LockTile({required this.scope, required this.bridge});

  final AppScope scope;
  final CoreBridge bridge;

  @override
  State<_LockTile> createState() => _LockTileState();
}

class _LockTileState extends State<_LockTile> {
  Future<void> _toggle(bool value) async {
    final prefs = widget.scope.prefs;
    final auth = widget.scope.authenticator;
    if (value) {
      if (!await auth.isAvailable()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('Telefonda ekran kilidi ya da parmak izi tanımlı değil.'),
            ),
          ),
        );
        return;
      }
      if (!await auth.authenticate(
        tr('Uygulama kilidini açmak için doğrulayın'),
      )) {
        return;
      }
    }
    await prefs.setLockEnabled(value);
    try {
      await widget.bridge.appLockSetEnabled(value);
    } catch (_) {
      // Eski yerel taraf ya da test: yerel taraf Flutter ayarını da okur.
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint_rounded),
      title: Text(tr('Uygulama kilidi')),
      subtitle: Text(tr('Parmak izi, yüz tanıma ya da ekran kilidi')),
      value: widget.scope.prefs.lockEnabled,
      onChanged: _toggle,
    );
  }
}

/// Sohbet ekranındaki hazır yanıtların düzenlenmesi.
class QuickRepliesScreen extends StatefulWidget {
  const QuickRepliesScreen({super.key, required this.prefs, this.bridge});

  final LocalPrefs prefs;

  /// Verilirse liste değişince bildirimdeki seçenekler de güncellenir.
  final CoreBridge? bridge;

  @override
  State<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends State<QuickRepliesScreen> {
  late List<String> _replies = [...widget.prefs.quickReplies];

  Future<void> _save(List<String> replies) async {
    setState(() => _replies = replies);
    await widget.prefs.setQuickReplies(replies);
    try {
      await widget.bridge?.setQuickReplies(replies);
    } catch (_) {
      // Eski yerel taraf ya da test: bildirim seçenekleri sonraki açılışta.
    }
  }

  Future<void> _add() async {
    final text = await showTextDialog(
      context,
      title: tr('Yeni hazır yanıt'),
      confirmLabel: tr('Ekle'),
      maxLines: 3,
    );
    if (text == null || text.isEmpty || _replies.contains(text)) return;
    await _save([..._replies, text]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Hazır yanıtlar'))),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: tr('Ekle'),
        child: const Icon(Icons.add),
      ),
      body: _replies.isEmpty
          ? Center(child: Text(tr('Hazır yanıt yok.')))
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final reply in _replies)
                  ListTile(
                    title: Text(reply),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: tr('Sil'),
                      onPressed: () => _save([..._replies]..remove(reply)),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// En üstte: mesajların eksiksiz gelmesi için gereken ayarlar ve tek
/// dokunuşla düzeltme.
class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.health,
    required this.bridge,
    required this.onChanged,
  });

  final SystemHealth health;
  final CoreBridge bridge;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final problems = health.problems;
    Widget row({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool ok,
      String? fix,
      VoidCallback? onFix,
    }) => ListTile(
      leading: Icon(
        ok ? Icons.check_circle_rounded : Icons.error_rounded,
        color: ok ? const Color(0xFF22B573) : const Color(0xFFF59E0B),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ok || onFix == null
          ? Icon(icon, color: theme.colorScheme.outline)
          : FilledButton.tonal(
              onPressed: onFix,
              child: Text(fix ?? tr('Düzelt')),
            ),
    );
    return SectionCard(
      title: problems == 0
          ? tr('Sistem durumu · her şey hazır')
          : tr('Sistem durumu · {problems} ayar eksik', {'problems': problems}),
      children: [
        row(
          icon: Icons.notifications_outlined,
          title: tr('Bildirim erişimi'),
          subtitle: health.listenerOk
              ? tr('Mesajlar yakalanıyor')
              : health.listenerEnabled
              ? tr('İzin var ama sistem servisi bağlamadı')
              : tr('Mesajları okumak için gerekli'),
          ok: health.listenerOk,
          fix: health.listenerEnabled ? tr('Bağla') : tr('İzin ver'),
          onFix: () async {
            if (!health.listenerEnabled) {
              await bridge.openListenerSettings();
            } else if (health.xiaomi) {
              await bridge.openAutostartSettings();
            } else {
              await bridge.rebindListener();
            }
            onChanged();
          },
        ),
        row(
          icon: Icons.notifications_active_outlined,
          title: tr('Bildirim izni'),
          subtitle: health.notificationsAllowed
              ? tr('Yeni mesajlar bildirilir')
              : tr('Kapalıysa yeni mesaj bildirimi görmezsiniz'),
          ok: health.notificationsAllowed,
          fix: tr('Aç'),
          onFix: () async {
            await bridge.requestNotificationPermission();
            await bridge.openNotificationSettings();
            onChanged();
          },
        ),
        row(
          icon: Icons.battery_full_rounded,
          title: tr('Pil kısıtlaması yok'),
          subtitle: health.batteryUnrestricted
              ? tr('Arka planda kapatılmaz')
              : tr(
                  'Telefon uygulamayı arka planda kapatıp mesajları geciktirebilir',
                ),
          ok: health.batteryUnrestricted,
          fix: tr('Kaldır'),
          onFix: () async {
            await bridge.openBatterySettings();
            onChanged();
          },
        ),
        if (health.xiaomi)
          ListTile(
            leading: Icon(
              Icons.rocket_launch_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(tr('Otomatik başlatma (Xiaomi)')),
            subtitle: Text(
              tr('Açık olmalı; telefon yeniden başlayınca da çalışsın'),
            ),
            trailing: TextButton(
              onPressed: bridge.openAutostartSettings,
              child: Text(tr('Kontrol et')),
            ),
          ),
        row(
          icon: Icons.mic_none_rounded,
          title: tr('Mikrofon'),
          subtitle: health.micAllowed
              ? tr('Sesli mesaj kaydedilebilir')
              : tr('Yalnızca sesli mesaj için; ilk kayıtta sorulur'),
          ok: health.micAllowed,
        ),
      ],
    );
  }
}
