import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/models.dart';
import '../core/people.dart';
import '../core/settings.dart';
import '../core/telegram.dart';
import '../core/web_services.dart';
import '../ui/avatars.dart';
import '../ui/theme.dart';
import 'archive_screen.dart';
import 'chat_screen.dart';
import 'conversation_widgets.dart';
import 'engagement.dart';
import 'search_screen.dart';
import 'services_screen.dart';
import 'setup_checklist.dart';
import 'tips.dart';
import 'starred_screen.dart';
import 'summary_screen.dart';
import 'welcome_screen.dart';

/// Tüm uygulamalardan gelen sohbetlerin tek listesi.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required this.bridge, this.web});

  final CoreBridge bridge;

  /// Verilirse filtre çiplerinin sonunda "+ Ekle" çipi servis ekler.
  final WebBridge? web;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

/// Servis bu kadar süre bağlanmazsa uyarı gösterilir. Uygulama açılırken
/// sistemin servisi bağlaması bir an sürer; uyarı boşuna yanıp sönmesin.
const serviceWarningDelay = Duration(seconds: 3);

class _InboxScreenState extends State<InboxScreen> with WidgetsBindingObserver {
  ListenerStatus? _status;
  bool _showServiceWarning = false;
  Timer? _warningTimer;
  List<Conversation> _conversations = const [];
  List<WaitingPerson> _waiting = const [];
  List<SnoozedConversation> _snoozed = const [];
  List<PersonSuggestion> _suggestions = const [];

  /// Kurulum listesi için; okunamazsa (eski yerel taraf) eski öneri kartı.
  SystemHealth? _health;
  TelegramStatus? _telegram;
  int _archivedCount = 0;
  bool _unifiedEnabled = true;
  Set<String> _keepSource = const {};

  /// Seçili uygulama filtresi (görünen ad); null = tümü.
  String? _appFilter;
  StreamSubscription<String>? _changes;
  StreamSubscription<bool>? _statusChanges;
  StreamSubscription<String>? _openRequests;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _changes = widget.bridge.changes.listen((_) => _load());
    _statusChanges = widget.bridge.listenerStatusChanges.listen((connected) {
      final status = _status;
      if (status != null) _applyStatus(status.withConnected(connected));
    });
    _openRequests = widget.bridge.openRequests.listen(_openByKey);
    _refresh().then((_) async {
      // Uygulama bir birleşik bildirime dokunularak açıldıysa o sohbete git.
      final key = await widget.bridge.takeLaunchConversation();
      if (key != null) await _openByKey(key);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    _statusChanges?.cancel();
    _openRequests?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  // Kullanıcı ayarlardan izni verip geri döndüğünde ekranı güncelle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await widget.bridge.listenerStatus();
    if (!mounted) return;
    _applyStatus(status);
    await _load();
  }

  void _applyStatus(ListenerStatus status) {
    final broken = status.enabled && !status.connected;
    setState(() {
      _status = status;
      if (!broken) _showServiceWarning = false;
    });
    if (!broken) {
      _warningTimer?.cancel();
      _warningTimer = null;
    } else if (!_showServiceWarning && _warningTimer == null) {
      _warningTimer = Timer(serviceWarningDelay, () {
        _warningTimer = null;
        final current = _status;
        if (mounted &&
            current != null &&
            current.enabled &&
            !current.connected) {
          setState(() => _showServiceWarning = true);
        }
      });
    }
  }

  Future<void> _rebind() async {
    await widget.bridge.rebindListener();
    // Bağlanırsa durum olayı uyarıyı kaldırır; bu yalnızca yedek kontrol.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) await _refresh();
  }

  Future<void> _load() async {
    final conversations = await widget.bridge.conversations();
    final archivedCount = await widget.bridge.archivedCount();
    final settings = await widget.bridge.settings();
    var waiting = _waiting;
    var snoozed = _snoozed;
    var suggestions = _suggestions;
    try {
      waiting = await widget.bridge.waiting();
      snoozed = await widget.bridge.snoozed();
    } catch (_) {
      // Eski yerel taraf ya da test.
    }
    try {
      suggestions = await widget.bridge.personSuggestions();
    } catch (_) {
      // Eski yerel taraf ya da test.
    }
    var health = _health;
    var telegram = _telegram;
    try {
      health = await widget.bridge.health();
      telegram = await widget.bridge.telegramStatus();
    } catch (_) {
      // Eski yerel taraf ya da test: kurulum listesi gösterilmez.
    }
    if (!mounted) return;
    setState(() {
      _conversations = conversations;
      _archivedCount = archivedCount;
      _unifiedEnabled = settings.unifiedNotifications;
      _keepSource = settings.keepSourcePackages;
      _waiting = waiting;
      _snoozed = snoozed;
      _suggestions = suggestions;
      _health = health;
      _telegram = telegram;
    });
  }

  Future<void> _waitingActions(WaitingPerson p) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.done_rounded),
              title: Text(tr('Yanıt gerekmez')),
              subtitle: Text(tr('Yeni mesaj gelene kadar listeden kalkar')),
              onTap: () => Navigator.of(context).pop('dismiss'),
            ),
            ListTile(
              leading: const Icon(Icons.alarm_rounded),
              title: Text(tr('Sonra hatırlat')),
              onTap: () => Navigator.of(context).pop('snooze'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'dismiss') {
      await widget.bridge.dismissWaiting(p.key);
    } else if (choice == 'snooze' && mounted) {
      final at = await pickLaterTime(
        context,
        title: tr('Ne zaman hatırlatılsın?'),
      );
      if (at == null) return;
      await widget.bridge.snooze(p.key, at);
    }
    await _load();
  }

  Future<void> _openByKey(String key) async {
    final all = [
      ...await widget.bridge.conversations(),
      ...await widget.bridge.conversations(archived: true),
    ];
    final conversation = all.where((c) => c.key == key).firstOrNull;
    if (conversation == null || !mounted) return;
    // Kişiye aitse kişi ekranı, yanıt bu sohbetin uygulamasından.
    final person = conversation.personId;
    final members = person == null
        ? const <Conversation>[]
        : all.where((c) => c.personId == person).toList();
    if (members.length > 1) {
      members.sort((a, b) => b.lastTime.compareTo(a.lastTime));
      await _push(
        ChatScreen(
          bridge: widget.bridge,
          conversation: conversation,
          members: members,
        ),
      );
    } else {
      await _open(conversation);
    }
  }

  Future<void> _enableUnified() async {
    final settings = await widget.bridge.settings();
    await widget.bridge.requestNotificationPermission();
    await widget.bridge.updateSettings(
      settings.copyWith(unifiedNotifications: true),
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Birleşik bildirimler açık. Yeni mesajlar artık Mesa bildirimiyle gelecek.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!status.enabled) {
      return Scaffold(
        body: WelcomeScreen(onGrant: widget.bridge.openListenerSettings),
      );
    }
    final unreadTotal = _conversations.fold<int>(0, (n, c) => n + c.unread);
    final scope = AppScope.maybeOf(context);
    final showPromo =
        !_unifiedEnabled && !(scope?.prefs.unifiedPromoDismissed ?? false);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Mesajlar'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              unreadTotal == 0
                  ? tr('Hepsi okundu')
                  : tr('{unreadTotal} okunmamış', {'unreadTotal': unreadTotal}),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _push(
              SummaryScreen(bridge: widget.bridge, onOpen: _openFromScreen),
            ),
            icon: const Icon(Icons.insights_rounded),
            tooltip: tr('Haftalık özet'),
          ),
          IconButton(
            onPressed: () => _push(
              StarredScreen(bridge: widget.bridge, onOpen: _openFromScreen),
            ),
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: tr('Kaydedilenler'),
          ),
          PopupMenuButton<_InboxMenu>(
            tooltip: tr('Diğer'),
            onSelected: _onMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _InboxMenu.markAllRead,
                child: ListTile(
                  leading: Icon(Icons.done_all_rounded),
                  title: Text(tr('Tümünü okundu say')),
                ),
              ),
              PopupMenuItem(
                value: _InboxMenu.archive,
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(
                    _archivedCount > 0
                        ? tr('Arşiv ({archivedCount})', {
                            'archivedCount': _archivedCount,
                          })
                        : tr('Arşiv'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showServiceWarning)
            ServiceWarning(
              xiaomi: status.xiaomi,
              onOpenAutostart: widget.bridge.openAutostartSettings,
              onOpenAppSettings: widget.bridge.openAppSettings,
              onRebind: _rebind,
            ),
          _SearchPill(onTap: () => _push(SearchScreen(bridge: widget.bridge))),
          Expanded(child: _buildInbox(context, showPromo, scope)),
        ],
      ),
    );
  }

  Widget _buildInbox(BuildContext context, bool showPromo, AppScope? scope) {
    // Kurulum listesi okunabiliyorsa birleşik bildirim önerisi onun bir adımı.
    final health = _health;
    final checklist = health == null || scope == null
        ? null
        : SetupChecklist(
            bridge: widget.bridge,
            prefs: scope.prefs,
            health: health,
            settings: AppSettings(
              unifiedNotifications: _unifiedEnabled,
              keepSourcePackages: _keepSource,
            ),
            usesWhatsApp: _conversations.any(
              (c) => c.packageName.startsWith('com.whatsapp'),
            ),
            telegram: _telegram,
            onChanged: _load,
          );
    final showChecklist =
        checklist != null && checklist.visible(DateTime.now());
    // Kurulum listesi açıkken ipucu beklesin: ekran kalabalıklaşmasın.
    final tip = showChecklist || scope == null
        ? null
        : tipForToday(scope.prefs, DateTime.now());
    final promo = showChecklist
        ? checklist
        : showPromo && checklist == null
        ? _UnifiedPromo(
            onEnable: _enableUnified,
            onDismiss: () async {
              await scope?.prefs.dismissUnifiedPromo();
              if (mounted) setState(() {});
            },
          )
        : null;
    if (_conversations.isEmpty) {
      return ListView(children: [?promo, const _EmptyInbox()]);
    }

    final apps = <String, String>{
      for (final c in _conversations)
        MessagingApp.of(c.packageName).name: c.packageName,
    };
    // En çok sohbeti olan uygulama başta (alfabetik sırada WhatsApp sona
    // kalıyordu); eşitlikte ada göre.
    final counts = <String, int>{};
    for (final c in _conversations) {
      counts.update(
        MessagingApp.of(c.packageName).name,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    final appNames = apps.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    // "Tümü"nde aynı kişinin sohbetleri tek satır; uygulama filtresinde
    // o uygulamanın sohbetleri tek tek.
    final entries = _appFilter == null
        ? groupByPerson(_conversations)
        : [
            for (final c in _conversations)
              if (MessagingApp.of(c.packageName).name == _appFilter)
                InboxEntry.single(c),
          ];
    final byKey = {for (final c in _conversations) c.key: c};
    final suggestion = _appFilter != null
        ? null
        : _suggestions
              .where((s) => byKey.containsKey(s.a) && byKey.containsKey(s.b))
              .firstOrNull;

    return CustomScrollView(
      slivers: [
        if (appNames.length > 1 || widget.web != null)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                children: [
                  _filterChip(tr('Tümü'), null, null),
                  for (final name in appNames)
                    _filterChip(name, name, apps[name]),
                  if (widget.web case final web?)
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: Text(tr('Ekle')),
                      tooltip: tr('Servis ekle'),
                      onPressed: () async {
                        await addWebService(context, web);
                        await _load();
                      },
                    ),
                ],
              ),
            ),
          ),
        if (promo != null) SliverToBoxAdapter(child: promo),
        if (_waiting.isNotEmpty)
          SliverToBoxAdapter(
            child: WaitingStrip(
              people: _waiting,
              onOpen: (p) => _openByKey(p.key),
              onLongPress: _waitingActions,
            ),
          ),
        if (tip != null && scope != null)
          SliverToBoxAdapter(
            child: TipCard(
              tip: tip,
              onDone: () async {
                await scope.prefs.advanceTip(DateTime.now());
                if (mounted) setState(() {});
              },
            ),
          ),
        if (suggestion != null)
          SliverToBoxAdapter(
            child: PersonSuggestionCard(
              a: byKey[suggestion.a]!,
              b: byKey[suggestion.b]!,
              reason: suggestion.reason,
              onMerge: () =>
                  _mergeSuggestion(byKey[suggestion.a]!, byKey[suggestion.b]!),
              onDismiss: () => _dismissSuggestion(suggestion),
            ),
          ),
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return ConversationTile(
              conversation: entry.summary,
              members: entry.isPerson ? entry.members : const [],
              onTap: () => _openEntry(entry),
              onLongPress: () => _entryActions(entry),
            );
          },
        ),
        if (_snoozed.isNotEmpty)
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.alarm_rounded),
              title: Text(
                tr('{count} ertelenmiş sohbet', {'count': _snoozed.length}),
              ),
              subtitle: Text(tr('Zamanı gelince hatırlatılacak')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await showSnoozedSheet(context, widget.bridge, _snoozed);
                await _load();
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// Özet ya da Kaydedilenler'den bir sohbete: o ekranı kapatmadan üstüne açılır.
  void _openFromScreen(String key) => _openByKey(key);

  Widget _filterChip(String label, String? value, String? packageName) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: packageName == null
              ? null
              : AppIcon(packageName: packageName, size: 18),
          label: Text(label),
          selected: _appFilter == value,
          onSelected: (_) => setState(() => _appFilter = value),
        ),
      );

  Future<void> _open(Conversation c) =>
      _push(ChatScreen(bridge: widget.bridge, conversation: c));

  /// Kişi satırı: yanıt en son yazışılan uygulamadan.
  Future<void> _openEntry(InboxEntry entry) => entry.isPerson
      ? _push(
          ChatScreen(
            bridge: widget.bridge,
            conversation: preferredMember(entry.members),
            members: entry.members,
          ),
        )
      : _open(entry.latest);

  Future<void> _entryActions(InboxEntry entry) async {
    final changed = entry.isPerson
        ? await showPersonActions(context, widget.bridge, entry)
        : await showConversationActions(
            context,
            widget.bridge,
            entry.latest,
            others: _conversations,
          );
    if (changed) await _load();
  }

  Future<void> _mergeSuggestion(Conversation a, Conversation b) async {
    final name = personNameFor(a, b);
    await widget.bridge.mergePeople([a.key, b.key], name: name);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            '{name} artık tek satırda: {name2} ve {name3} mesajları birlikte.',
            {
              'name': name,
              'name2': MessagingApp.of(a.packageName).name,
              'name3': MessagingApp.of(b.packageName).name,
            },
          ),
        ),
      ),
    );
  }

  Future<void> _dismissSuggestion(PersonSuggestion s) async {
    await widget.bridge.dismissPersonSuggestion(s.a, s.b);
    await _load();
  }

  Future<void> _onMenu(_InboxMenu item) async {
    switch (item) {
      case _InboxMenu.markAllRead:
        await widget.bridge.markAllRead();
        await _load();
      case _InboxMenu.archive:
        await _push(ArchiveScreen(bridge: widget.bridge));
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    await _load();
  }
}

enum _InboxMenu { markAllRead, archive }

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  tr('Tüm mesajlarda ara'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(tr('Henüz mesaj yok'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            tr(
              'WhatsApp, Instagram, Discord gibi uygulamalardan yeni mesaj geldikçe burada toplanır; eski mesajlar görünmez. Telegram\'ı Ayarlar\'dan bağlarsanız geçmişi de gelir.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bildirimleri birleştir" önerisi: Mesa'nın asıl farkı.
class _UnifiedPromo extends StatelessWidget {
  const _UnifiedPromo({required this.onEnable, required this.onDismiss});

  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Bildirimleri birleştir'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    tooltip: tr('Kapat'),
                  ),
                ],
              ),
              Text(
                tr(
                  'Her uygulamanın ayrı bildirimi yerine tek tip Mesa bildirimleri: kişi fotoğrafı, doğrudan yanıt ve kurallarınla birlikte.',
                ),
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brand,
                ),
                onPressed: onEnable,
                child: Text(tr('Aç')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İzin verilmiş ama sistem bildirim servisini bağlamamış: hiçbir mesaj
/// yakalanmıyor. En sık sebep üreticinin arka plan kısıtlamaları.
class ServiceWarning extends StatelessWidget {
  const ServiceWarning({
    super.key,
    required this.xiaomi,
    required this.onOpenAutostart,
    required this.onOpenAppSettings,
    required this.onRebind,
  });

  final bool xiaomi;
  final VoidCallback onOpenAutostart;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onRebind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('Bildirim servisi çalışmıyor'),
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              xiaomi
                  ? tr(
                      'Yeni mesajlar şu an yakalanmıyor. Xiaomi uygulamayı arka planda engelliyor: Otomatik başlatma iznini açın ve uygulama ayarlarında pil tasarrufunu "Kısıtlama yok" yapın. Ardından "Yeniden bağla"ya dokunun.',
                    )
                  : tr(
                      'Yeni mesajlar şu an yakalanmıyor. Telefon uygulamayı arka planda kapatmış olabilir: uygulama ayarlarında pil kısıtlamasını kaldırın, ardından "Yeniden bağla"ya dokunun.',
                    ),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            Wrap(
              spacing: 4,
              children: [
                if (xiaomi)
                  TextButton(
                    onPressed: onOpenAutostart,
                    child: Text(tr('Otomatik başlatma')),
                  ),
                TextButton(
                  onPressed: onOpenAppSettings,
                  child: Text(tr('Uygulama ayarları')),
                ),
                TextButton(
                  onPressed: onRebind,
                  child: Text(tr('Yeniden bağla')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Aynı kişi mi?": farklı uygulamalarda adı ya da numarası aynı iki sohbet.
class PersonSuggestionCard extends StatelessWidget {
  const PersonSuggestionCard({
    super.key,
    required this.a,
    required this.b,
    required this.reason,
    required this.onMerge,
    required this.onDismiss,
  });

  final Conversation a;
  final Conversation b;
  final String reason;
  final VoidCallback onMerge;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget side(Conversation c) => Expanded(
      child: Column(
        children: [
          ConversationAvatar(
            title: c.title,
            packageName: c.packageName,
            avatarPath: c.avatarPath,
            size: 44,
          ),
          const SizedBox(height: 6),
          Text(
            c.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge,
          ),
          Text(
            MessagingApp.of(c.packageName).name,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('Aynı kişi mi?'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reason == 'phone'
                  ? tr(
                      'Telefon numaraları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.',
                    )
                  : tr(
                      'Adları aynı. Birleştirirseniz mesajları tek satırda, tek zaman çizgisinde görürsünüz.',
                    ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                side(a),
                Icon(Icons.add_link_rounded, color: scheme.outline),
                side(b),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: Text(tr('Farklı kişiler')),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onMerge, child: Text(tr('Birleştir'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
