import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/web_services.dart';
import '../ui/avatars.dart';
import '../ui/large_title.dart';
import '../ui/text_dialog.dart';

/// Tüm uygulamalara tek yerden hızlı geçiş: telefonda kurulu mesajlaşma
/// uygulamaları (dokununca kendileri açılır, en akıcısı) ve Ferdium'daki gibi
/// resmi web sürümleriyle açılan servisler.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.bridge, this.inboxChanges});

  final WebBridge bridge;

  /// Gelen kutusu değişti (uygulamaların okunmamış sayıları yenilensin).
  final Stream<Object?>? inboxChanges;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<WebService>? _services;
  List<InstalledApp> _apps = const [];
  List<WebCatalogItem> _catalog = const [];
  bool _profiles = false;
  StreamSubscription<void>? _changes;
  StreamSubscription<Object?>? _inbox;
  Timer? _appsDebounce;

  @override
  void initState() {
    super.initState();
    _changes = widget.bridge.changes.listen((_) => _load());
    // Mesajlar art arda gelebilir; sayılar en fazla yarım saniyede bir okunur.
    _inbox = widget.inboxChanges?.listen((_) {
      _appsDebounce?.cancel();
      _appsDebounce = Timer(const Duration(milliseconds: 500), _loadApps);
    });
    _load();
    _loadApps();
    _loadCatalog();
  }

  @override
  void dispose() {
    _changes?.cancel();
    _inbox?.cancel();
    _appsDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final apps = await widget.bridge.apps();
    if (mounted) setState(() => _apps = apps);
  }

  Future<void> _openApp(InstalledApp app) async {
    final opened = await widget.bridge.openApp(app.packageName);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('{name} açılamadı.', {'name': app.name}))),
    );
  }

  Future<void> _load() async {
    final services = await widget.bridge.services();
    if (!mounted) return;
    // Sitenin simgesi sonradan iner; gelen kutusundaki rozetler de yenilensin.
    for (final s in services) {
      AppIcons.refreshIfChanged(s.packageName, s.iconVersion);
    }
    setState(() => _services = services);
  }

  Future<void> _loadCatalog() async {
    final catalog = await widget.bridge.catalog();
    final profiles = await widget.bridge.profilesSupported();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _profiles = profiles;
    });
  }

  Future<void> _add() async {
    await addWebService(context, widget.bridge);
    await _load();
  }

  Future<void> _addCatalog(String catalogId) async {
    final id = await widget.bridge.add(catalogId);
    await _load();
    // Hemen açılır: kullanıcı giriş yapsın.
    await widget.bridge.open(id);
  }

  Future<void> _settings(WebService service) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ServiceSettingsSheet(
        bridge: widget.bridge,
        service: service,
        profilesSupported: _profiles,
      ),
    );
    await _load();
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Servisler nasıl çalışır?'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              tr(
                'Her servis kendi resmi web sitesiyle, uygulamanın içindeki tarayıcıda açılır. Giriş bilgileriniz yalnızca bu telefonda kalır; Mesa yalnızca o servisin sunucusuyla konuşur.\n\nArka planda bağlı servisler uygulama kapalıyken de yeni mesajları bildirir ve mesajlar Sohbetler\'e düşer. Bunun için telefonun pil ayarında Mesa\'ya "Kısıtlama yok" verilmelidir. Her açık servis pil ve bellek harcar.\n\nInstagram, X ve LinkedIn gibi bazı siteler açıkken mesaj bildirimi göndermez; onlarda okunmamış sayısı arttığında haber verilir.\n\n"Google ile giriş" bu sayfalarda çalışmaz; e-posta ve şifreyle girin.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    final unread =
        (services ?? const <WebService>[])
            .where((s) => s.unread > 0)
            .fold<int>(0, (sum, s) => sum + s.unread) +
        _apps.fold<int>(0, (sum, a) => sum + a.unread);
    final theme = Theme.of(context);
    Widget header(String text) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: largeTitleAppBar(
        context,
        title: tr('Servisler'),
        subtitle: unread > 0
            ? tr('{unread} okunmamış', {'unread': unread})
            : tr('Tüm uygulamalar tek yerde'),
        actions: [
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: tr('Servisler nasıl çalışır?'),
          ),
        ],
      ),
      floatingActionButton: services == null || services.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('Servis ekle')),
            ),
      body: services == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_apps.isNotEmpty) ...[
                  header(tr('Uygulamalar')),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 92,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: _apps.length,
                      itemBuilder: (context, i) => _AppTile(
                        app: _apps[i],
                        onTap: () => _openApp(_apps[i]),
                      ),
                    ),
                  ),
                ],
                header(tr('Web servisleri')),
                if (services.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                      catalog: _catalog,
                      onAdd: _add,
                      onQuickAdd: _addCatalog,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.12,
                          ),
                      itemCount: services.length,
                      itemBuilder: (context, i) => _ServiceTile(
                        service: services[i],
                        onTap: () => widget.bridge.open(services[i].id),
                        onMore: () => _settings(services[i]),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Servis ekleme akışı (Servisler ekranı ve Sohbetler'deki "+" çipi):
/// katalogdan ya da adresle eklenir ve giriş yapılsın diye hemen açılır.
/// Eklenen servisin kimliği; vazgeçildiyse null.
Future<String?> addWebService(BuildContext context, WebBridge bridge) async {
  final catalog = await bridge.catalog();
  final services = await bridge.services();
  if (!context.mounted) return null;
  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AddServiceSheet(catalog: catalog, services: services),
  );
  if (choice == null || !context.mounted) return null;
  final id = choice == _AddServiceSheet.custom
      ? await showDialog<String>(
          context: context,
          builder: (_) => _CustomSiteDialog(bridge: bridge),
        )
      : await bridge.add(choice);
  if (id == null) return null;
  await bridge.open(id);
  return id;
}

/// Servisin simgesi: kurulu uygulamanın ya da sitenin simgesi (yerel taraf
/// seçer), yoksa katalog simgesi, o da yoksa servis renginde baş harf.
class WebServiceIcon extends StatelessWidget {
  const WebServiceIcon({
    super.key,
    required this.name,
    required this.color,
    this.packageName,
    this.catalogId,
    this.size = 48,
  });

  final String name;
  final Color color;

  /// Simgesi sorulacak paket ("web:discord" ya da kurulu uygulama).
  final String? packageName;

  /// Katalogdaki servis ("discord"): uygulamayla gelen simgesi kullanılır.
  final String? catalogId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        name.characters.first.toUpperCase(),
        style: TextStyle(
          color: color.computeLuminance() > 0.6 ? Colors.black : Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
    final id = catalogId;
    final fallback = id == null
        ? letter
        : ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.26),
            child: Image.asset(
              'assets/web_icons/$id.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => letter,
            ),
          );
    final package = packageName;
    if (package == null) return fallback;
    return FutureBuilder<Uint8List?>(
      future: AppIcons.load(package),
      initialData: AppIcons.peek(package),
      builder: (context, snapshot) => switch (snapshot.data) {
        final bytes? => ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.26),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
        null => fallback,
      },
    );
  }
}

/// Telefondaki uygulamanın kısayolu: gerçek simgesi, adı, okunmamış rozeti.
class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onTap});

  final InstalledApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: app.unread > 0,
              label: Text(app.unread > 99 ? '99+' : '${app.unread}'),
              offset: const Offset(4, -4),
              child: AppIcon(packageName: app.packageName, size: 48),
            ),
            const SizedBox(height: 6),
            Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.onTap,
    required this.onMore,
  });

  final WebService service;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = service.unread;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_horiz_rounded),
                tooltip: tr('{name} ayarları', {'name': service.name}),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge(
                      isLabelVisible: service.hasUnread,
                      label: unread > 0
                          ? Text(unread > 99 ? '99+' : '$unread')
                          : null,
                      smallSize: 12,
                      offset: const Offset(6, -6),
                      child: WebServiceIcon(
                        name: service.name,
                        color: service.color,
                        packageName: service.packageName,
                        catalogId: service.catalogId,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      switch (unread) {
                        > 0 => tr('{unread} okunmamış', {'unread': unread}),
                        WebService.unreadDot => tr('Okunmamış var'),
                        _ when !service.notify => tr('Bildirim kapalı'),
                        _ when service.background => tr('Arka planda bağlı'),
                        _ => tr('Yalnızca açıkken'),
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: service.hasUnread
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: service.hasUnread ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.catalog,
    required this.onAdd,
    required this.onQuickAdd,
  });

  final List<WebCatalogItem> catalog;
  final VoidCallback onAdd;
  final ValueChanged<String> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          Icon(
            Icons.language_rounded,
            size: 56,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            tr('Henüz web servisi yok'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Telefonda uygulaması olmayan servisleri resmi web sürümleriyle buraya ekleyin. Yeni mesajlar Sohbetler\'e ve bildirimlere düşer.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('Servis ekle')),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in catalog.where((c) => !c.appInstalled))
                ActionChip(
                  avatar: WebServiceIcon(
                    name: item.name,
                    color: item.color,
                    packageName: item.appPackage,
                    catalogId: item.id,
                    size: 20,
                  ),
                  label: Text(item.name),
                  onPressed: () => onQuickAdd(item.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddServiceSheet extends StatelessWidget {
  const _AddServiceSheet({required this.catalog, required this.services});

  static const custom = '__site__';

  final List<WebCatalogItem> catalog;
  final List<WebService> services;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(tr('Servis ekle'), style: theme.textTheme.titleLarge),
          ),
          for (final item in catalog)
            ListTile(
              leading: WebServiceIcon(
                name: item.name,
                color: item.color,
                packageName: item.appPackage,
                catalogId: item.id,
                size: 40,
              ),
              title: Text(item.name),
              subtitle: _subtitle(item),
              trailing: const Icon(Icons.add_rounded),
              onTap: () => Navigator.of(context).pop(item.id),
            ),
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.language_rounded,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(tr('Başka bir site')),
            subtitle: Text(tr('Adresini yazarak, ör. vk.com/im')),
            trailing: const Icon(Icons.add_rounded),
            onTap: () => Navigator.of(context).pop(custom),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              tr(
                'KakaoTalk, Viber, LINE ve Signal\'in web sürümü yok. Uygulamaları telefona kurulursa mesajları bildirimlerden otomatik toplanır.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _subtitle(WebCatalogItem item) {
    final added = services.any((s) => s.catalogId == item.id);
    if (added) return Text(tr('Ekli · ikinci hesap eklenir'));
    if (item.appInstalled) {
      return Text(tr('Uygulaması kurulu, bildirimleri zaten geliyor'));
    }
    return null;
  }
}

class _CustomSiteDialog extends StatefulWidget {
  const _CustomSiteDialog({required this.bridge});

  final WebBridge bridge;

  @override
  State<_CustomSiteDialog> createState() => _CustomSiteDialogState();
}

class _CustomSiteDialogState extends State<_CustomSiteDialog> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await widget.bridge.addCustom(_name.text, _url.text);
      if (mounted) Navigator.of(context).pop(id);
    } on InvalidWebUrlException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = tr('https ile açılan geçerli bir site adresi yazın.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Başka bir site')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: tr('Ad')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: tr('Adres'),
              hintText: 'vk.com/im',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Vazgeç')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(tr('Ekle')),
        ),
      ],
    );
  }
}

class _ServiceSettingsSheet extends StatefulWidget {
  const _ServiceSettingsSheet({
    required this.bridge,
    required this.service,
    required this.profilesSupported,
  });

  final WebBridge bridge;
  final WebService service;
  final bool profilesSupported;

  @override
  State<_ServiceSettingsSheet> createState() => _ServiceSettingsSheetState();
}

class _ServiceSettingsSheetState extends State<_ServiceSettingsSheet> {
  late String _name = widget.service.name;
  late bool _background = widget.service.background;
  late bool _notify = widget.service.notify;
  late bool _autoplay = widget.service.autoplay;

  String get _host => Uri.tryParse(widget.service.url)?.host ?? '';

  Future<void> _rename() async {
    final name = await showTextDialog(
      context,
      title: tr('Adını değiştir'),
      confirmLabel: tr('Kaydet'),
      initial: _name,
    );
    if (name == null || name.trim().isEmpty) return;
    await widget.bridge.update(widget.service.id, name: name.trim());
    if (mounted) setState(() => _name = name.trim());
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr('Vazgeç')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _logout() async {
    final ok = await _confirm(
      tr('{name} oturumu kapatılsın mı?', {'name': _name}),
      tr(
        'Bu servisin giriş bilgileri ve site verileri telefondan silinir. Yeniden giriş yapmanız gerekir.',
      ),
      tr('Oturumu kapat'),
    );
    if (!ok) return;
    await widget.bridge.logout(widget.service.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final ok = await _confirm(
      tr('{name} kaldırılsın mı?', {'name': _name}),
      tr(
        'Oturum ve site verileri telefondan silinir. Sohbetler\'deki eski mesajlar kalır.',
      ),
      tr('Kaldır'),
    );
    if (!ok) return;
    await widget.bridge.remove(widget.service.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: WebServiceIcon(
              name: _name,
              color: service.color,
              packageName: service.packageName,
              catalogId: service.catalogId,
              size: 44,
            ),
            title: Text(_name, style: theme.textTheme.titleLarge),
            subtitle: Text(_host),
            trailing: FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).pop();
                widget.bridge.open(service.id);
              },
              child: Text(tr('Aç')),
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.sync_rounded),
            title: Text(tr('Arka planda bağlı kalsın')),
            subtitle: Text(
              tr(
                'Uygulama kapalıyken de yeni mesajlar bildirilir; pil kullanımı artar',
              ),
            ),
            value: _background,
            onChanged: (v) {
              setState(() => _background = v);
              widget.bridge.update(service.id, background: v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(tr('Bildirimler')),
            subtitle: Text(tr('Yeni mesajlar Sohbetler\'e ve bildirimlere')),
            value: _notify,
            onChanged: (v) {
              setState(() => _notify = v);
              widget.bridge.update(service.id, notify: v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.smart_display_outlined),
            title: Text(tr('Videolar kendiliğinden oynasın')),
            subtitle: Text(
              tr('Kapalıyken videolar dokununca oynar; sayfa daha akıcı olur'),
            ),
            value: _autoplay,
            onChanged: (v) {
              setState(() => _autoplay = v);
              widget.bridge.update(service.id, autoplay: v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(tr('Adını değiştir')),
            onTap: _rename,
          ),
          if (widget.profilesSupported)
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(tr('Oturumu kapat')),
              onTap: _logout,
            ),
          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
            ),
            title: Text(
              tr('Kaldır'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: _remove,
          ),
        ],
      ),
    );
  }
}
