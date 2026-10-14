import 'package:flutter/services.dart';

/// Eklenebilecek bir web servisi (android/.../WebCatalog.kt).
class WebCatalogItem {
  const WebCatalogItem({
    required this.id,
    required this.name,
    required this.color,
    this.appInstalled = false,
    this.appPackage,
  });

  factory WebCatalogItem.fromMap(Map<Object?, Object?> m) => WebCatalogItem(
    id: m['id']! as String,
    name: m['name']! as String,
    color: Color(m['color']! as int),
    appInstalled: m['appInstalled'] as bool? ?? false,
    appPackage: m['appPackage'] as String?,
  );

  final String id;
  final String name;
  final Color color;

  /// Servisin telefon uygulaması kurulu; bildirimleri zaten yakalanıyor.
  final bool appInstalled;

  /// Kurulu uygulamanın paketi (simgesi gösterilir).
  final String? appPackage;
}

/// Kullanıcının eklediği web servisi.
class WebService {
  const WebService({
    required this.id,
    required this.name,
    required this.url,
    required this.color,
    this.catalogId,
    this.desktop = false,
    this.wide = false,
    this.background = true,
    this.notify = true,
    this.zoom = 100,
    this.autoplay = true,
    this.unread = 0,
    this.loaded = false,
    this.iconVersion,
  });

  factory WebService.fromMap(Map<Object?, Object?> m) => WebService(
    id: m['id']! as String,
    catalogId: m['catalogId'] as String?,
    name: m['name']! as String,
    url: m['url']! as String,
    color: Color(m['color']! as int),
    desktop: m['desktop'] as bool? ?? false,
    wide: m['wide'] as bool? ?? false,
    background: m['background'] as bool? ?? true,
    notify: m['notify'] as bool? ?? true,
    zoom: m['zoom'] as int? ?? 100,
    autoplay: m['autoplay'] as bool? ?? true,
    unread: m['unread'] as int? ?? 0,
    loaded: m['loaded'] as bool? ?? false,
    iconVersion: m['iconVersion'] as String?,
  );

  /// Okunmamış var ama sayısı bilinmiyor (sayfa başlığında "•").
  static const unreadDot = -1;

  final String id;
  final String? catalogId;
  final String name;
  final String url;
  final Color color;
  final bool desktop;
  final bool wide;

  /// Uygulama kapalıyken de bağlı kalır, yeni mesajda bildirim gelir.
  final bool background;
  final bool notify;
  final int zoom;

  /// Videolar kendiliğinden oynar; kapalıysa dokununca oynar (daha akıcı).
  final bool autoplay;
  final int unread;

  /// Sayfa şu an açık (arka planda ya da ekranda).
  final bool loaded;

  /// Simge değişince (site açılıp simgesi inince) değişir; yerel taraf
  /// simgeyi `appIcon` kanalından [packageName] ile verir.
  final String? iconVersion;

  /// Gelen kutusundaki sohbetlerin paket adı.
  String get packageName => '$webPackagePrefix$id';

  bool get hasUnread => unread != 0;
}

const webPackagePrefix = 'web:';

/// Telefonda kurulu desteklenen mesajlaşma uygulaması (Servisler'de kısayol).
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.name,
    required this.color,
    this.unread = 0,
  });

  factory InstalledApp.fromMap(Map<Object?, Object?> m) => InstalledApp(
    packageName: m['package']! as String,
    name: m['name']! as String,
    color: Color(m['color']! as int),
    unread: m['unread'] as int? ?? 0,
  );

  final String packageName;
  final String name;
  final Color color;

  /// Mesa'daki okunmamış mesaj sayısı.
  final int unread;
}

/// Kullanıcının girdiği site adresi geçersiz (https olmalı).
class InvalidWebUrlException implements Exception {
  const InvalidWebUrlException();
}

/// Web servisleri kanalı (android/.../WebChannel.kt).
class WebBridge {
  WebBridge();

  static const _channel = MethodChannel('mesaj_merkezi/web');

  /// Liste, okunmamış sayısı ya da simge değişti.
  late final Stream<void> changes = const EventChannel(
    'mesaj_merkezi/web_events',
  ).receiveBroadcastStream().map((_) {}).asBroadcastStream();

  Future<List<WebCatalogItem>> catalog() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('catalog') ??
        const [];
    return raw.map(WebCatalogItem.fromMap).toList();
  }

  /// Telefonda kurulu mesajlaşma uygulamaları ve okunmamış sayıları.
  Future<List<InstalledApp>> apps() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('apps') ??
        const [];
    return raw.map(InstalledApp.fromMap).toList();
  }

  /// Uygulamayı açar; açılamazsa false.
  Future<bool> openApp(String packageName) async =>
      await _channel.invokeMethod<bool>('openApp', {'package': packageName}) ??
      false;

  Future<List<WebService>> services() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('services') ??
        const [];
    final services = raw.map(WebService.fromMap).toList();
    WebRegistry.update(services);
    return services;
  }

  /// Aynı servis ekliyse ikinci hesap olarak eklenir. Yeni servisin kimliği.
  Future<String> add(String catalogId) async =>
      (await _channel.invokeMethod<String>('add', {'catalogId': catalogId}))!;

  Future<String> addCustom(String name, String url) async {
    try {
      return (await _channel.invokeMethod<String>('add', {
        'name': name,
        'url': url,
      }))!;
    } on PlatformException catch (e) {
      if (e.code == 'INVALID_URL') throw const InvalidWebUrlException();
      rethrow;
    }
  }

  Future<void> update(
    String id, {
    String? name,
    bool? background,
    bool? notify,
    bool? autoplay,
  }) => _channel.invokeMethod<void>('update', {
    'id': id,
    'name': ?name,
    'background': ?background,
    'notify': ?notify,
    'autoplay': ?autoplay,
  });

  Future<void> remove(String id) =>
      _channel.invokeMethod<void>('remove', {'id': id});

  /// Oturumu kapatır; telefon bunu desteklemiyorsa false.
  Future<bool> logout(String id) async =>
      await _channel.invokeMethod<bool>('logout', {'id': id}) ?? false;

  /// Servisin sayfasını açar.
  Future<void> open(String id) =>
      _channel.invokeMethod<void>('open', {'id': id});

  /// Servis başına ayrı oturum (aynı servisten iki hesap, tek tek çıkış).
  Future<bool> profilesSupported() async =>
      await _channel.invokeMethod<bool>('profilesSupported') ?? false;
}

/// Gelen kutusunda web sohbetlerinin adı ve rengi için son bilinen liste.
abstract final class WebRegistry {
  static var _byId = <String, WebService>{};

  static void update(List<WebService> services) {
    _byId = {for (final s in services) s.id: s};
  }

  static Iterable<WebService> get all => _byId.values;

  static WebService? byPackage(String packageName) =>
      _byId[packageName.substring(webPackagePrefix.length)];
}

/// Liste henüz okunmadıysa katalogdaki ad ve renk ("discord-2" → Discord).
const webCatalogFallback = <String, (String, Color)>{
  'discord': ('Discord', Color(0xFF5865F2)),
  'instagram': ('Instagram', Color(0xFFE1306C)),
  'messenger': ('Messenger', Color(0xFF0084FF)),
  'slack': ('Slack', Color(0xFF611F69)),
  'x': ('X', Color(0xFF536471)),
  'linkedin': ('LinkedIn', Color(0xFF0A66C2)),
  'reddit': ('Reddit', Color(0xFFFF4500)),
  'snapchat': ('Snapchat', Color(0xFFE6C800)),
  'tiktok': ('TikTok', Color(0xFF010101)),
  'teams': ('Teams', Color(0xFF6264A7)),
};
