import 'package:flutter/material.dart';

import 'web_services.dart';

/// Desteklenen uygulamaların görünen adı ve rengi. Hangi paketlerin
/// dinlendiği android/.../SupportedApps.kt'de; ikisi birlikte güncellenmeli.
class MessagingApp {
  const MessagingApp(this.name, this.color, {this.iconId, this.glyph});

  final String name;
  final Color color;

  /// Uygulamayla gelen simge (`assets/web_icons/<iconId>.png`): uygulama
  /// telefonda kurulu değilse baş harf yerine gösterilir.
  final String? iconId;

  /// Gömülü simgesi yoksa uygulama renginde gösterilen işaret.
  final IconData? glyph;

  static const _known = <String, MessagingApp>{
    'com.whatsapp': MessagingApp('WhatsApp', Color(0xFF25D366)),
    'com.whatsapp.w4b': MessagingApp('WhatsApp Business', Color(0xFF128C7E)),
    'org.telegram.messenger': MessagingApp(
      'Telegram',
      Color(0xFF229ED9),
      glyph: Icons.telegram,
    ),
    'org.telegram.messenger.web': MessagingApp(
      'Telegram',
      Color(0xFF229ED9),
      glyph: Icons.telegram,
    ),
    'org.thunderdog.challegram': MessagingApp(
      'Telegram X',
      Color(0xFF229ED9),
      glyph: Icons.telegram,
    ),
    'com.instagram.android': MessagingApp(
      'Instagram',
      Color(0xFFE1306C),
      iconId: 'instagram',
    ),
    'com.facebook.orca': MessagingApp(
      'Messenger',
      Color(0xFF0084FF),
      iconId: 'messenger',
    ),
    'com.facebook.mlite': MessagingApp(
      'Messenger Lite',
      Color(0xFF0084FF),
      iconId: 'messenger',
    ),
    'org.thoughtcrime.securesms': MessagingApp('Signal', Color(0xFF3A76F0)),
    'com.discord': MessagingApp(
      'Discord',
      Color(0xFF5865F2),
      iconId: 'discord',
    ),
    'com.viber.voip': MessagingApp('Viber', Color(0xFF7360F2)),
    'jp.naver.line.android': MessagingApp('LINE', Color(0xFF06C755)),
    'com.snapchat.android': MessagingApp(
      'Snapchat',
      Color(0xFFE6C800),
      iconId: 'snapchat',
    ),
    'com.twitter.android': MessagingApp('X', Color(0xFF536471), iconId: 'x'),
    'com.linkedin.android': MessagingApp(
      'LinkedIn',
      Color(0xFF0A66C2),
      iconId: 'linkedin',
    ),
    'com.microsoft.teams': MessagingApp(
      'Teams',
      Color(0xFF6264A7),
      iconId: 'teams',
    ),
    'com.Slack': MessagingApp('Slack', Color(0xFF611F69), iconId: 'slack'),
    'com.reddit.frontpage': MessagingApp(
      'Reddit',
      Color(0xFFFF4500),
      iconId: 'reddit',
    ),
    'com.zhiliaoapp.musically': MessagingApp(
      'TikTok',
      Color(0xFF010101),
      iconId: 'tiktok',
    ),
    'com.ss.android.ugc.trill': MessagingApp(
      'TikTok',
      Color(0xFF010101),
      iconId: 'tiktok',
    ),
    'com.kakao.talk': MessagingApp('KakaoTalk', Color(0xFFFEE500)),
    'com.google.android.apps.messaging': MessagingApp(
      'SMS',
      Color(0xFF1A73E8),
      glyph: Icons.sms_rounded,
    ),
    'com.samsung.android.messaging': MessagingApp(
      'SMS',
      Color(0xFF1A73E8),
      glyph: Icons.sms_rounded,
    ),
  };

  static MessagingApp of(String packageName) {
    if (packageName.startsWith(webPackagePrefix)) return _web(packageName);
    return _known[packageName] ?? MessagingApp(packageName, Colors.blueGrey);
  }

  /// Web servisi ("web:discord-2"): eklenen servisin adı, yoksa katalogdaki ad.
  static MessagingApp _web(String packageName) {
    final service = WebRegistry.byPackage(packageName);
    if (service != null) {
      return MessagingApp(
        service.name,
        service.color,
        iconId: service.catalogId,
      );
    }
    final id = packageName.substring(webPackagePrefix.length);
    final catalogId = webCatalogFallback.containsKey(id)
        ? id
        : id.split('-').first;
    final fallback = webCatalogFallback[catalogId];
    return fallback == null
        ? const MessagingApp(
            'Web',
            Colors.blueGrey,
            glyph: Icons.language_rounded,
          )
        : MessagingApp(fallback.$1, fallback.$2, iconId: catalogId);
  }

  /// [packagesByName] ve eklenmiş web servisleri ("Discord" → web:discord).
  static Map<String, List<String>> get packagesByNameWithWeb => {
    ...packagesByName,
    for (final s in WebRegistry.all)
      if (!packagesByName.containsKey(s.name)) s.name: [s.packageName],
  };

  static bool isWeb(String packageName) =>
      packageName.startsWith(webPackagePrefix);

  /// Görünen ad → paketler. Aynı adı taşıyan paketler (ör. iki SMS
  /// uygulaması) kural seçiminde tek seçenek olarak gösterilir.
  static Map<String, List<String>> get packagesByName {
    final byName = <String, List<String>>{};
    for (final MapEntry(key: package, value: app) in _known.entries) {
      (byName[app.name] ??= []).add(package);
    }
    return byName;
  }
}
