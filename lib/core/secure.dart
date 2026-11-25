import 'dart:convert';

import 'package:flutter/services.dart';

/// Şifreli DNS sağlayıcılarının kimlikleri (yerel taraftaki DohProviders ile aynı).
const dnsProviderIds = [
  'cloudflare',
  'cloudflare_security',
  'cloudflare_family',
  'adguard',
  'quad9',
  'google',
];

/// Sağlayıcının dile bağlı olmayan adı.
String dnsProviderName(String id) => switch (id) {
  'cloudflare' => 'Cloudflare 1.1.1.1',
  'cloudflare_security' => 'Cloudflare 1.1.1.2',
  'cloudflare_family' => 'Cloudflare 1.1.1.3',
  'adguard' => 'AdGuard DNS',
  'quad9' => 'Quad9 9.9.9.9',
  'google' => 'Google 8.8.8.8',
  _ => id,
};

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Bütün telefonun şifreli DNS'inin (yerel DNS VPN'i) durumu.
class SecureDnsStatus {
  const SecureDnsStatus({
    required this.running,
    required this.enabled,
    required this.prepared,
    required this.provider,
    this.queries = 0,
    this.cacheHits = 0,
    this.failures = 0,
    this.latencyMs = 0,
    this.since,
    this.lastStop,
    this.otherVpn = false,
    this.privateDns,
  });

  factory SecureDnsStatus.fromMap(Map<Object?, Object?> m) => SecureDnsStatus(
    running: m['running'] as bool? ?? false,
    enabled: m['enabled'] as bool? ?? false,
    prepared: m['prepared'] as bool? ?? false,
    provider: m['provider'] as String? ?? dnsProviderIds.first,
    queries: _int(m['queries']),
    cacheHits: _int(m['cacheHits']),
    failures: _int(m['failures']),
    latencyMs: _int(m['latencyMs']),
    since: _int(m['since']) > 0
        ? DateTime.fromMillisecondsSinceEpoch(_int(m['since']))
        : null,
    lastStop: m['lastStop'] as String?,
    otherVpn: m['otherVpn'] as bool? ?? false,
    privateDns: m['privateDns'] as String?,
  );

  final bool running;
  final bool enabled;

  /// Kullanıcı VPN iznini vermiş mi.
  final bool prepared;
  final String provider;
  final int queries;
  final int cacheHits;
  final int failures;

  /// Ağdan gelen yanıtların ortalama süresi.
  final int latencyMs;
  final DateTime? since;

  /// Son kapanma nedeni: user, revoked (başka VPN), permission, error.
  final String? lastStop;

  /// Başka bir uygulamanın VPN'i açık (aynı anda tek VPN çalışır).
  final bool otherVpn;

  /// Sistemin "Özel DNS" ayarı: off, opportunistic, hostname.
  final String? privateDns;

  /// "Özel DNS" bir sunucuya sabitlenmişse sistem VPN'in DNS'ini kullanmaz.
  bool get privateDnsOverrides => privateDns == 'hostname';
}

/// Web servisleri için erişim kalkanının durumu.
class ShieldStatus {
  const ShieldStatus({
    required this.supported,
    required this.enabled,
    this.active = false,
    this.connections = 0,
    this.splits = 0,
    this.failures = 0,
  });

  factory ShieldStatus.fromMap(Map<Object?, Object?> m) => ShieldStatus(
    supported: m['supported'] as bool? ?? false,
    enabled: m['enabled'] as bool? ?? false,
    active: m['active'] as bool? ?? false,
    connections: _int(m['connections']),
    splits: _int(m['splits']),
    failures: _int(m['failures']),
  );

  final bool supported;
  final bool enabled;
  final bool active;
  final int connections;

  /// Bölünerek gönderilen TLS el sıkışmaları (SNI engelini aşma denemeleri).
  final int splits;
  final int failures;
}

/// WireGuard tünelinin canlı durumu.
class VpnStatus {
  const VpnStatus({
    this.activeId,
    this.rx = 0,
    this.tx = 0,
    this.handshake,
    this.lastError,
  });

  factory VpnStatus.fromMap(Map<Object?, Object?> m) => VpnStatus(
    activeId: m['activeId'] as String?,
    rx: _int(m['rx']),
    tx: _int(m['tx']),
    handshake: _int(m['handshake']) > 0
        ? DateTime.fromMillisecondsSinceEpoch(_int(m['handshake']))
        : null,
    lastError: m['lastError'] as String?,
  );

  /// Açık tünelin kimliği; kapalıysa null.
  final String? activeId;
  final int rx;
  final int tx;

  /// Sunucuyla son el sıkışma; hiç olmadıysa null (sunucu yanıt vermiyor).
  final DateTime? handshake;
  final String? lastError;
}

/// İçe aktarılmış WireGuard yapılandırması (özel anahtar arayüze gelmez).
class WireGuardTunnel {
  const WireGuardTunnel({
    required this.id,
    required this.name,
    this.endpoints = const [],
    this.addresses = const [],
    this.dns = const [],
    this.fullTunnel = true,
    this.active = false,
    this.broken = false,
  });

  factory WireGuardTunnel.fromMap(Map<Object?, Object?> m) => WireGuardTunnel(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    endpoints: [...?(m['endpoints'] as List?)?.cast<String>()],
    addresses: [...?(m['addresses'] as List?)?.cast<String>()],
    dns: [...?(m['dns'] as List?)?.cast<String>()],
    fullTunnel: m['fullTunnel'] as bool? ?? true,
    active: m['active'] as bool? ?? false,
    broken: m['broken'] as bool? ?? false,
  );

  final String id;
  final String name;
  final List<String> endpoints;
  final List<String> addresses;
  final List<String> dns;

  /// Bütün trafik tünelden mi geçiyor (0.0.0.0/0).
  final bool fullTunnel;
  final bool active;

  /// Bu telefonda açılamıyor (ör. sıfırlama sonrası); silinip yeniden eklenmeli.
  final bool broken;
}

/// İçe aktarma sonucu: başarılıysa kimlik, değilse hata kodu.
class WireGuardImport {
  const WireGuardImport({this.id, this.error});

  factory WireGuardImport.fromMap(Map<Object?, Object?> m) =>
      WireGuardImport(id: m['id'] as String?, error: m['error'] as String?);

  final String? id;

  /// BAD_CONFIG…, NO_PEER, TOO_LARGE, READ.
  final String? error;
}

class SecureStatus {
  const SecureStatus({
    required this.dns,
    required this.shield,
    this.vpn = const VpnStatus(),
  });

  factory SecureStatus.fromMap(Map<Object?, Object?> m) => SecureStatus(
    dns: SecureDnsStatus.fromMap((m['dns'] as Map?) ?? const {}),
    shield: ShieldStatus.fromMap((m['shield'] as Map?) ?? const {}),
    vpn: VpnStatus.fromMap((m['vpn'] as Map?) ?? const {}),
  );

  final SecureDnsStatus dns;
  final ShieldStatus shield;
  final VpnStatus vpn;
}

/// Metin bir WireGuard yapılandırmasına benziyor mu (panodan önerirken).
bool looksLikeWireGuardConfig(String text) =>
    text.contains('[Interface]') && text.contains('PrivateKey');

/// TDLib'e eklenmiş Telegram proxy'si (anahtar ve parola arayüze gelmez).
class TelegramProxy {
  const TelegramProxy({
    required this.id,
    required this.server,
    required this.port,
    required this.type,
    required this.enabled,
    this.lastUsed,
  });

  factory TelegramProxy.fromMap(Map<Object?, Object?> m) => TelegramProxy(
    id: _int(m['id']),
    server: m['server'] as String? ?? '',
    port: _int(m['port']),
    type: m['type'] as String? ?? 'other',
    enabled: m['enabled'] as bool? ?? false,
    lastUsed: _int(m['lastUsed']) > 0
        ? DateTime.fromMillisecondsSinceEpoch(_int(m['lastUsed']))
        : null,
  );

  final int id;
  final String server;
  final int port;

  /// mtproto, socks5 ya da http.
  final String type;
  final bool enabled;
  final DateTime? lastUsed;

  String get typeLabel => switch (type) {
    'mtproto' => 'MTProto',
    'socks5' => 'SOCKS5',
    'http' => 'HTTP',
    _ => type,
  };
}

/// Eklenecek proxy (bağlantıdan ya da elle).
class ProxyLink {
  const ProxyLink({
    required this.type,
    required this.server,
    required this.port,
    this.secret = '',
    this.username = '',
    this.password = '',
  });

  /// mtproto ya da socks5.
  final String type;
  final String server;
  final int port;

  /// MTProto anahtarı, onaltılık (TDLib bu biçimi ister).
  final String secret;
  final String username;
  final String password;
}

/// MTProto anahtarını onaltılık biçime çevirir: bağlantılarda onaltılık ya da
/// base64url olarak bulunur. Geçersizse null.
String? normalizeMtprotoSecret(String secret) {
  final s = secret.trim();
  if (s.isEmpty) return null;
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(s) && s.length.isEven) {
    return s.length >= 32 ? s.toLowerCase() : null;
  }
  try {
    final padded = s.padRight((s.length + 3) ~/ 4 * 4, '=');
    final bytes = base64Url.decode(
      padded.replaceAll('+', '-').replaceAll('/', '_'),
    );
    if (bytes.length < 16) return null;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  } on FormatException {
    return null;
  }
}

/// Telegram proxy bağlantısını ayrıştırır: `tg://proxy?…`, `tg://socks?…`,
/// `https://t.me/proxy?…`, `https://t.me/socks?…` (şemasız da olur).
/// Geçerli değilse null.
ProxyLink? parseProxyLink(String text) {
  var raw = text.trim();
  if (raw.isEmpty) return null;
  if (!raw.contains('://')) raw = 'https://$raw';
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  String? kind;
  if (uri.scheme == 'tg') {
    kind = uri.host;
  } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      const ['t.me', 'telegram.me', 'telegram.dog'].contains(uri.host)) {
    kind = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (kind != 'proxy' && kind != 'socks') return null;
  final q = uri.queryParameters;
  final server = (q['server'] ?? '').trim();
  final port = int.tryParse(q['port'] ?? '');
  if (server.isEmpty || port == null || port < 1 || port > 65535) return null;
  if (kind == 'proxy') {
    final secret = normalizeMtprotoSecret(q['secret'] ?? '');
    if (secret == null) return null;
    return ProxyLink(
      type: 'mtproto',
      server: server,
      port: port,
      secret: secret,
    );
  }
  return ProxyLink(
    type: 'socks5',
    server: server,
    port: port,
    username: q['user'] ?? '',
    password: q['pass'] ?? '',
  );
}

/// MainActivity.kt'deki "mesaj_merkezi/secure" kanalı (SecureChannel.kt).
class SecureBridge {
  SecureBridge();

  static const _channel = MethodChannel('mesaj_merkezi/secure');

  Future<SecureStatus> status() async => SecureStatus.fromMap(
    (await _channel.invokeMapMethod<Object?, Object?>('status')) ?? const {},
  );

  /// "started" ya da "permission" (sistemin VPN izni penceresi açıldı).
  Future<String> startDns() async =>
      await _channel.invokeMethod<String>('dnsStart') ?? 'permission';

  Future<void> stopDns() => _channel.invokeMethod<void>('dnsStop');

  Future<void> setDnsProvider(String id) =>
      _channel.invokeMethod<void>('dnsProvider', {'id': id});

  Future<void> openVpnSettings() =>
      _channel.invokeMethod<void>('openVpnSettings');

  Future<void> setShield(bool enabled) =>
      _channel.invokeMethod<void>('shieldSet', {'enabled': enabled});

  /// Telegram açılmadıysa null.
  Future<List<TelegramProxy>?> telegramProxies() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'tgProxies',
    );
    return raw?.map(TelegramProxy.fromMap).toList();
  }

  /// Hata metni; başarılıysa null.
  Future<String?> addTelegramProxy(ProxyLink link) =>
      _channel.invokeMethod<String>('tgProxyAdd', {
        'type': link.type,
        'server': link.server,
        'port': link.port,
        'secret': link.secret,
        'username': link.username,
        'password': link.password,
      });

  Future<String?> setTelegramProxyEnabled(int id, bool enabled) => _channel
      .invokeMethod<String>('tgProxyEnable', {'id': id, 'enabled': enabled});

  Future<String?> removeTelegramProxy(int id) =>
      _channel.invokeMethod<String>('tgProxyRemove', {'id': id});

  /// Telegram'a gidiş-dönüş (ms); [id] null ise proxy'siz. Ulaşılamazsa null.
  Future<int?> pingTelegram(int? id) async =>
      (await _channel.invokeMethod<num>('tgProxyPing', {'id': id}))?.toInt();

  Future<List<WireGuardTunnel>> wireGuardTunnels() async =>
      (await _channel.invokeListMethod<Map<Object?, Object?>>('wgTunnels') ??
              const [])
          .map(WireGuardTunnel.fromMap)
          .toList();

  Future<WireGuardImport> importWireGuard(String name, String text) async =>
      WireGuardImport.fromMap(
        (await _channel.invokeMapMethod<Object?, Object?>('wgImport', {
              'name': name,
              'text': text,
            })) ??
            const {},
      );

  /// Seçilen .conf dosyasını (içerik adresi) içe aktarır.
  Future<WireGuardImport> importWireGuardFile(String uri) async =>
      WireGuardImport.fromMap(
        (await _channel.invokeMapMethod<Object?, Object?>('wgImportUri', {
              'uri': uri,
            })) ??
            const {},
      );

  /// null: açıldı; "PERMISSION": sistemin VPN izni penceresi açıldı;
  /// diğer: hata kodu (VPN_NOT_AUTHORIZED, DNS_RESOLUTION_FAILURE, …).
  Future<String?> connectWireGuard(String id) =>
      _channel.invokeMethod<String>('wgConnect', {'id': id});

  Future<String?> disconnectWireGuard() =>
      _channel.invokeMethod<String>('wgDisconnect');

  Future<void> removeWireGuard(String id) =>
      _channel.invokeMethod<void>('wgRemove', {'id': id});
}
