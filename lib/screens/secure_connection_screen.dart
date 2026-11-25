import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/secure.dart';
import '../ui/large_title.dart';
import '../ui/text_dialog.dart';

/// Şifreli DNS (bütün telefon), tam VPN (WireGuard), web servisleri için
/// erişim kalkanı ve Telegram proxy'leri. Mesa'nın sunucusu ya da hesabı yok.
class SecureConnectionScreen extends StatefulWidget {
  const SecureConnectionScreen({
    super.key,
    required this.bridge,
    this.onOpenTelegram,
    this.pickFile,
    this.refreshInterval = const Duration(seconds: 2),
  });

  final SecureBridge bridge;

  /// Dosya seçici (WireGuard .conf içe aktarma); içerik adresi ya da null.
  final Future<String?> Function()? pickFile;

  /// Telegram henüz açılmadıysa proxy bölümündeki bağlantı buraya gider;
  /// dönünce proxy listesi yeniden okunur.
  final Future<void> Function()? onOpenTelegram;

  /// Açıkken sayaçların yenilenme aralığı.
  final Duration refreshInterval;

  @override
  State<SecureConnectionScreen> createState() => _SecureConnectionScreenState();
}

class _SecureConnectionScreenState extends State<SecureConnectionScreen> {
  SecureStatus? _status;
  List<TelegramProxy>? _proxies;
  bool _proxiesLoaded = false;
  List<WireGuardTunnel> _tunnels = const [];
  Timer? _timer;
  bool _busy = false;

  /// Bağlanılmakta olan tünel (düğme dönerken).
  String? _connecting;

  /// Proxy kimliği (null: doğrudan) → ms; -1 ölçülüyor, -2 ulaşılamadı.
  final Map<int?, int> _pings = {};

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadProxies();
    _loadTunnels();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _refresh());
  }

  Future<void> _loadTunnels() async {
    List<WireGuardTunnel> tunnels;
    try {
      tunnels = await widget.bridge.wireGuardTunnels();
    } on PlatformException {
      tunnels = const [];
    }
    if (mounted) setState(() => _tunnels = tunnels);
  }

  /// Yerel hata kodunun kullanıcıya gösterilecek açıklaması.
  String _vpnError(String code) {
    if (code.startsWith('BAD_CONFIG')) {
      return tr(
        'Yapılandırma okunamadı. Dosyanın bir WireGuard (.conf) dosyası olduğundan emin olun.',
      );
    }
    return switch (code) {
      'PERMISSION' => tr(
        'Açılan pencerede "Tamam"a dokunarak VPN iznini verin.',
      ),
      'VPN_NOT_AUTHORIZED' => tr(
        'VPN izni verilmedi. Açmak için yeniden deneyin.',
      ),
      'DNS_RESOLUTION_FAILURE' => tr(
        'Sunucunun adresi çözülemedi. İnternet bağlantınızı kontrol edin.',
      ),
      'NO_PEER' => tr('Yapılandırmada sunucu ([Peer]) yok.'),
      'TOO_LARGE' || 'READ' => tr('Dosya okunamadı.'),
      _ => tr('Tünel açılamadı ({code}).', {'code': code}),
    };
  }

  Future<void> _imported(WireGuardImport result) async {
    if (!mounted) return;
    if (result.error != null) {
      _snack(_vpnError(result.error!));
      return;
    }
    _snack(tr('WireGuard yapılandırması eklendi.'));
    await _loadTunnels();
  }

  Future<void> _importFile() async {
    final uri = await widget.pickFile?.call();
    if (uri == null) return;
    await _imported(await widget.bridge.importWireGuardFile(uri));
  }

  Future<void> _importPaste() async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    final text = await showTextDialog(
      context,
      title: tr('WireGuard yapılandırması'),
      confirmLabel: tr('İçe aktar'),
      hint: '[Interface]\nPrivateKey = …\n\n[Peer]\n…',
      initial: looksLikeWireGuardConfig(clip) ? clip.trim() : '',
      maxLines: 8,
    );
    if (text == null || text.trim().isEmpty) return;
    await _imported(await widget.bridge.importWireGuard('', text));
  }

  Future<void> _toggleTunnel(WireGuardTunnel tunnel, bool on) async {
    setState(() => _connecting = tunnel.id);
    final error = on
        ? await widget.bridge.connectWireGuard(tunnel.id)
        : await widget.bridge.disconnectWireGuard();
    if (error != null && mounted) _snack(_vpnError(error));
    if (error == 'PERMISSION') {
      // İzin penceresinden sonra tünel arka planda açılır.
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    await _refresh();
    await _loadTunnels();
    if (mounted) setState(() => _connecting = null);
  }

  Future<void> _removeTunnel(WireGuardTunnel tunnel) async {
    await widget.bridge.removeWireGuard(tunnel.id);
    await _refresh();
    await _loadTunnels();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final status = await widget.bridge.status();
      if (mounted) setState(() => _status = status);
    } on PlatformException {
      // Bir sonraki turda yeniden denenir.
    }
  }

  Future<void> _loadProxies() async {
    List<TelegramProxy>? proxies;
    try {
      proxies = await widget.bridge.telegramProxies();
    } on PlatformException {
      proxies = null;
    }
    if (!mounted) return;
    setState(() {
      _proxies = proxies;
      _proxiesLoaded = true;
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setDns(bool on) async {
    setState(() => _busy = true);
    try {
      if (on) {
        final result = await widget.bridge.startDns();
        if (result == 'permission' && mounted) {
          _snack(tr('Açılan pencerede "Tamam"a dokunarak VPN iznini verin.'));
        }
      } else {
        await widget.bridge.stopDns();
      }
    } on PlatformException catch (e) {
      if (mounted) _snack(e.message ?? tr('Bir hata oluştu.'));
    }
    // İzin penceresi ve servisin açılması biraz sürer.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setProvider(String id) async {
    await widget.bridge.setDnsProvider(id);
    await _refresh();
  }

  Future<void> _setShield(bool on) async {
    await widget.bridge.setShield(on);
    await _refresh();
    if (on && mounted) {
      _snack(
        tr(
          'Erişim kalkanı açıldı. Web servislerini yeniden açınca devreye girer.',
        ),
      );
    }
  }

  Future<void> _ping(int? id) async {
    setState(() => _pings[id] = -1);
    int? ms;
    try {
      ms = await widget.bridge.pingTelegram(id);
    } on PlatformException {
      ms = null;
    }
    if (mounted) setState(() => _pings[id] = ms ?? -2);
  }

  Future<void> _addFromLink() async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (_) =>
          _LinkDialog(initial: parseProxyLink(clip) != null ? clip.trim() : ''),
    );
    if (text == null || !mounted) return;
    final link = parseProxyLink(text);
    if (link == null) {
      _snack(tr('Bu bir Telegram proxy bağlantısı değil.'));
      return;
    }
    await _add(link);
  }

  Future<void> _addManually() async {
    final link = await showDialog<ProxyLink>(
      context: context,
      builder: (_) => const _ManualProxyDialog(),
    );
    if (link != null) await _add(link);
  }

  Future<void> _add(ProxyLink link) async {
    final error = await widget.bridge.addTelegramProxy(link);
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }
    _snack(tr('Proxy eklendi ve Telegram için açıldı.'));
    await _loadProxies();
  }

  Future<void> _toggleProxy(TelegramProxy proxy, bool on) async {
    final error = await widget.bridge.setTelegramProxyEnabled(proxy.id, on);
    if (error != null && mounted) _snack(error);
    await _loadProxies();
  }

  Future<void> _removeProxy(TelegramProxy proxy) async {
    final error = await widget.bridge.removeTelegramProxy(proxy.id);
    if (error != null && mounted) _snack(error);
    await _loadProxies();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Güvenli bağlantı'))),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _intro(context),
                _dnsSection(context, status.dns),
                _vpnSection(context, status.vpn),
                _shieldSection(context, status.shield),
                _telegramSection(context),
                _about(context),
              ],
            ),
    );
  }

  Widget _intro(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          Icon(
            Icons.shield_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tr(
                'Engellenen servislere erişin ve DNS sorgularınızı gizleyin. Sunucu yok, hesap yok.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warning(BuildContext context, String text) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.info_outline_rounded, color: theme.colorScheme.error),
      title: Text(text, style: theme.textTheme.bodyMedium),
    );
  }

  String _providerDescription(String id) => switch (id) {
    'cloudflare' => tr('En hızlı seçeneklerden biri; gizlilik odaklı'),
    'cloudflare_security' => tr('Zararlı ve oltalama sitelerini engeller'),
    'cloudflare_family' => tr(
      'Zararlı sitelerle birlikte yetişkin içeriği de engeller',
    ),
    'adguard' => tr('Bütün telefonda reklamları ve izleyicileri engeller'),
    'quad9' => tr('Zararlı siteleri engeller; kâr amacı gütmeyen kuruluş'),
    'google' => tr('Google\'ın genel DNS\'i'),
    _ => '',
  };

  Widget _dnsSection(BuildContext context, SecureDnsStatus dns) {
    return SectionCard(
      title: tr('Şifreli DNS'),
      children: [
        SwitchListTile(
          secondary: Icon(
            dns.running ? Icons.lock_rounded : Icons.lock_open_rounded,
          ),
          title: Text(tr('Bütün telefonda şifreli DNS')),
          subtitle: Text(
            dns.running
                ? tr('Açık · {provider}', {
                    'provider': dnsProviderName(dns.provider),
                  })
                : tr('Kapalı'),
          ),
          value: dns.running,
          onChanged: _busy ? null : _setDns,
        ),
        if (dns.running)
          ListTile(
            leading: const Icon(Icons.speed_rounded),
            title: Text(
              tr('{count, plural, one{# sorgu} other{# sorgu}}', {
                'count': dns.queries,
              }),
            ),
            subtitle: Text(
              tr(
                'Ortalama {ms} ms · {cached} önbellekten · {failed} başarısız',
                {
                  'ms': dns.latencyMs,
                  'cached': dns.cacheHits,
                  'failed': dns.failures,
                },
              ),
            ),
          ),
        if (!dns.running && dns.lastStop == 'revoked')
          _warning(
            context,
            tr('Başka bir VPN açıldığı için şifreli DNS kapandı.'),
          ),
        if (!dns.running && dns.lastStop == 'permission')
          _warning(
            context,
            tr('VPN izni verilmedi. Açmak için yeniden deneyin.'),
          ),
        if (!dns.running && dns.otherVpn)
          _warning(
            context,
            tr(
              'Başka bir VPN açık. Android aynı anda tek VPN\'e izin verir; şifreli DNS açılınca o kapanır.',
            ),
          ),
        if (dns.privateDnsOverrides)
          _warning(
            context,
            tr(
              'Telefonun "Özel DNS" ayarı bir sunucuya sabitlenmiş; o ayar kapatılmadan şifreli DNS etkisiz kalabilir.',
            ),
          ),
        for (final id in dnsProviderIds)
          ListTile(
            leading: Icon(
              id == dns.provider
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: id == dns.provider
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(dnsProviderName(id)),
            subtitle: Text(_providerDescription(id)),
            selected: id == dns.provider,
            onTap: id == dns.provider ? null : () => _setProvider(id),
          ),
        ListTile(
          leading: const Icon(Icons.autorenew_rounded),
          title: Text(tr('Her zaman açık')),
          subtitle: Text(
            tr(
              'Telefon açılınca kendiliğinden başlasın: sistemin VPN ayarlarında Mesa için "Her zaman açık VPN"i seçin.',
            ),
          ),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: widget.bridge.openVpnSettings,
        ),
        ListTile(
          leading: const Icon(Icons.touch_app_outlined),
          title: Text(tr('Hızlı ayarlar kutucuğu')),
          subtitle: Text(
            tr(
              'Bildirim panelini aşağı çekip düzenle simgesine dokunun ve "Şifreli DNS" kutucuğunu ekleyin; tek dokunuşla açıp kapatırsınız.',
            ),
          ),
        ),
      ],
    );
  }

  /// Açık tünelin canlı durum satırı.
  String _vpnLine(VpnStatus vpn) {
    final handshake = vpn.handshake;
    if (handshake == null) {
      return tr('Bağlanıyor… sunucudan henüz yanıt yok');
    }
    final seconds = DateTime.now().difference(handshake).inSeconds;
    final traffic = tr('↓ {rx} · ↑ {tx}', {
      'rx': formatSize(vpn.rx),
      'tx': formatSize(vpn.tx),
    });
    // WireGuard en geç ~2 dakikada bir yeniden el sıkışır.
    if (seconds > 180) {
      return '${tr('Sunucudan uzun süredir yanıt yok')} · $traffic';
    }
    return '${tr('Bağlı')} · $traffic';
  }

  Widget _vpnSection(BuildContext context, VpnStatus vpn) {
    return SectionCard(
      title: tr('Tam VPN (WireGuard)'),
      children: [
        if (_tunnels.isEmpty)
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: Text(
              tr(
                'Bütün trafiğiniz kendi WireGuard sunucunuz ya da bir VPN sağlayıcısı üzerinden geçer; IP adresiniz değişir.',
              ),
            ),
            subtitle: Text(
              tr(
                'Yapılandırma dosyasını kendi sunucunuzdan ya da WireGuard dosyası veren bir sağlayıcıdan (ör. Proton VPN\'in ücretsiz planı) alabilirsiniz.',
              ),
            ),
          ),
        for (final tunnel in _tunnels)
          ListTile(
            leading: Icon(
              tunnel.id == vpn.activeId
                  ? Icons.vpn_lock_rounded
                  : Icons.vpn_key_outlined,
              color: tunnel.id == vpn.activeId
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(tunnel.name),
            subtitle: Text(
              tunnel.broken
                  ? tr(
                      'Bu yapılandırma bu telefonda açılamıyor; silip yeniden içe aktarın.',
                    )
                  : tunnel.id == vpn.activeId
                  ? _vpnLine(vpn)
                  : [
                      ...tunnel.endpoints,
                      if (!tunnel.fullTunnel) tr('yalnızca bazı adresler'),
                    ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_connecting == tunnel.id)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (!tunnel.broken)
                  Switch(
                    value: tunnel.id == vpn.activeId,
                    onChanged: _connecting == null
                        ? (v) => _toggleTunnel(tunnel, v)
                        : null,
                  ),
                PopupMenuButton<String>(
                  onSelected: (_) => _removeTunnel(tunnel),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'remove', child: Text(tr('Sil'))),
                  ],
                ),
              ],
            ),
          ),
        if (widget.pickFile != null)
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: Text(tr('Dosyadan içe aktar')),
            subtitle: const Text('.conf'),
            onTap: _importFile,
          ),
        ListTile(
          leading: const Icon(Icons.content_paste_rounded),
          title: Text(tr('Panodan yapıştır')),
          onTap: _importPaste,
        ),
        if (_tunnels.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: Text(tr('Bağlantı yoksa interneti kes')),
            subtitle: Text(
              tr(
                'Sistemin VPN ayarlarında Mesa için "Her zaman açık VPN" ve "VPN olmadan bağlantıları engelle"yi açın.',
              ),
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: widget.bridge.openVpnSettings,
          ),
      ],
    );
  }

  Widget _shieldSection(BuildContext context, ShieldStatus shield) {
    return SectionCard(
      title: tr('Erişim kalkanı'),
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.travel_explore_rounded),
          title: Text(tr('Web servisleri için erişim kalkanı')),
          subtitle: Text(
            shield.supported
                ? tr(
                    'Discord, Slack gibi web servisleri DNS ve SNI engellerine takılmadan açılır. VPN gerekmez, kendi VPN\'inizle de çakışmaz.',
                  )
                : tr('Bu telefonun tarayıcı bileşeni bunu desteklemiyor.'),
          ),
          value: shield.enabled,
          onChanged: shield.supported ? _setShield : null,
        ),
        if (shield.enabled && shield.connections > 0)
          ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: Text(
              tr('{connections} bağlantı · {splits} engel aşma', {
                'connections': shield.connections,
                'splits': shield.splits,
              }),
            ),
          ),
      ],
    );
  }

  String _pingLabel(int? id) {
    final ms = _pings[id];
    if (ms == null) return '';
    if (ms == -1) return tr('Ölçülüyor…');
    if (ms == -2) return tr('Ulaşılamıyor');
    return '$ms ms';
  }

  Widget _telegramSection(BuildContext context) {
    final proxies = _proxies;
    return SectionCard(
      title: tr('Telegram proxy'),
      children: [
        if (!_proxiesLoaded)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (proxies == null)
          ListTile(
            leading: const Icon(Icons.send_rounded),
            title: Text(
              tr('Proxy eklemek için önce Telegram bağlantısını başlatın.'),
            ),
            trailing: widget.onOpenTelegram == null
                ? null
                : const Icon(Icons.chevron_right_rounded),
            onTap: widget.onOpenTelegram == null
                ? null
                : () async {
                    await widget.onOpenTelegram!();
                    await _loadProxies();
                  },
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.network_ping_rounded),
            title: Text(tr('Telegram\'a doğrudan erişim')),
            subtitle: _pings.containsKey(null) ? Text(_pingLabel(null)) : null,
            trailing: TextButton(
              onPressed: () => _ping(null),
              child: Text(tr('Dene')),
            ),
          ),
          for (final proxy in proxies)
            ListTile(
              leading: Icon(
                proxy.enabled ? Icons.vpn_lock_rounded : Icons.dns_outlined,
              ),
              title: Text('${proxy.server}:${proxy.port}'),
              subtitle: Text(
                [
                  proxy.typeLabel,
                  if (proxy.enabled) tr('Kullanılıyor'),
                  if (_pings.containsKey(proxy.id)) _pingLabel(proxy.id),
                ].join(' · '),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: proxy.enabled,
                    onChanged: (v) => _toggleProxy(proxy, v),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) =>
                        v == 'ping' ? _ping(proxy.id) : _removeProxy(proxy),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'ping', child: Text(tr('Hızı ölç'))),
                      PopupMenuItem(value: 'remove', child: Text(tr('Sil'))),
                    ],
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text(tr('Bağlantıdan ekle')),
            subtitle: const Text('tg://proxy · t.me/proxy · t.me/socks'),
            onTap: _addFromLink,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(tr('Elle ekle')),
            subtitle: const Text('MTProto · SOCKS5'),
            onTap: _addManually,
          ),
        ],
      ],
    );
  }

  Widget _about(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        tr(
          'Şifreli DNS, operatörün DNS engellerini aşar ve hangi sitelere girdiğinizi operatörden gizler. IP adresinizi gizlemez; tam bir VPN değildir. DNS sorguları seçtiğiniz sağlayıcıya gider, Mesa\'nın sunucusu yoktur.',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

/// Proxy bağlantısını yapıştırma penceresi.
class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.initial});

  final String initial;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr('Proxy bağlantısı')),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLines: 3,
      minLines: 1,
      decoration: const InputDecoration(
        hintText: 'tg://proxy?server=…&port=…&secret=…',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(tr('Vazgeç')),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: Text(tr('Ekle')),
      ),
    ],
  );
}

/// Proxy bilgilerini elle girme penceresi.
class _ManualProxyDialog extends StatefulWidget {
  const _ManualProxyDialog();

  @override
  State<_ManualProxyDialog> createState() => _ManualProxyDialogState();
}

class _ManualProxyDialogState extends State<_ManualProxyDialog> {
  String _type = 'mtproto';
  final _server = TextEditingController();
  final _port = TextEditingController();
  final _secret = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_server, _port, _secret, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final server = _server.text.trim();
    final port = int.tryParse(_port.text.trim());
    if (server.isEmpty || port == null || port < 1 || port > 65535) {
      setState(() => _error = tr('Sunucu ve port (1–65535) gerekli.'));
      return;
    }
    if (_type == 'mtproto') {
      final secret = normalizeMtprotoSecret(_secret.text);
      if (secret == null) {
        setState(() => _error = tr('Geçerli bir MTProto anahtarı girin.'));
        return;
      }
      Navigator.of(context).pop(
        ProxyLink(type: 'mtproto', server: server, port: port, secret: secret),
      );
    } else {
      Navigator.of(context).pop(
        ProxyLink(
          type: 'socks5',
          server: server,
          port: port,
          username: _user.text.trim(),
          password: _pass.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr('Proxy ekle')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'mtproto', label: Text('MTProto')),
              ButtonSegment(value: 'socks5', label: Text('SOCKS5')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          TextField(
            controller: _server,
            decoration: InputDecoration(labelText: tr('Sunucu')),
            keyboardType: TextInputType.url,
          ),
          TextField(
            controller: _port,
            decoration: InputDecoration(labelText: tr('Port')),
            keyboardType: TextInputType.number,
          ),
          if (_type == 'mtproto')
            TextField(
              controller: _secret,
              decoration: InputDecoration(labelText: tr('Anahtar (secret)')),
            )
          else ...[
            TextField(
              controller: _user,
              decoration: InputDecoration(
                labelText: tr('Kullanıcı adı (isteğe bağlı)'),
              ),
            ),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('Parola (isteğe bağlı)'),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(tr('Vazgeç')),
      ),
      FilledButton(onPressed: _save, child: Text(tr('Ekle'))),
    ],
  );
}
