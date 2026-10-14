import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/apps.dart';

/// Telefonda yüklü uygulamaların gerçek simgeleri (yerel taraftan PNG).
abstract final class AppIcons {
  static const _channel = MethodChannel('mesaj_merkezi/core');
  static final _cache = <String, Future<Uint8List?>>{};
  static final _resolved = <String, Uint8List?>{};
  static final _versions = <String, String?>{};

  static Future<Uint8List?> load(
    String packageName,
  ) => _cache.putIfAbsent(packageName, () async {
    Uint8List? bytes;
    try {
      bytes = await _channel.invokeMethod<Uint8List>('appIcon', {
        'package': packageName,
      });
    } on Exception {
      // Uygulama kurulu değil ya da (testlerde) yerel taraf yok: yedek görünüm.
    }
    return _resolved[packageName] = bytes;
  });

  /// Daha önce yüklenmiş simge; ilk karede baş harf yanıp sönmesin diye.
  static Uint8List? peek(String packageName) => _resolved[packageName];

  /// Web servisinin simgesi değişti (site açılıp simgesi indi): yeniden sorulur.
  static void refreshIfChanged(String packageName, String? version) {
    if (_versions.containsKey(packageName) &&
        _versions[packageName] == version) {
      return;
    }
    _versions[packageName] = version;
    _cache.remove(packageName);
  }
}

/// Uygulamanın simgesi. Uygulama kurulu değilse (ör. yalnızca web servisi
/// ya da "Okunan uygulamalar" listesi) uygulamayla gelen simge, o da yoksa
/// uygulama renginde işaret ya da baş harf.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.packageName, this.size = 20});

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final app = MessagingApp.of(packageName);
    final glyph = app.glyph;
    final letter = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: app.color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: glyph != null
          ? Icon(glyph, color: Colors.white, size: size * 0.62)
          : Text(
              app.name.characters.first,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
    );
    final iconId = app.iconId;
    final fallback = iconId == null
        ? letter
        : ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/web_icons/$iconId.png',
              key: ValueKey('bundled-$iconId'),
              width: size,
              height: size,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => letter,
            ),
          );
    return Semantics(
      label: app.name,
      child: FutureBuilder<Uint8List?>(
        future: AppIcons.load(packageName),
        initialData: AppIcons.peek(packageName),
        builder: (context, snapshot) => switch (snapshot.data) {
          final bytes? => ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              gaplessPlayback: true,
            ),
          ),
          null => fallback,
        },
      ),
    );
  }
}

/// Sohbetin fotoğrafı (yoksa renkli baş harfler); köşede kaynak uygulamanın simgesi.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    super.key,
    required this.title,
    required this.packageName,
    this.avatarPath,
    this.size = 52,
    this.showAppBadge = true,
  });

  final String title;
  final String packageName;
  final String? avatarPath;
  final double size;
  final bool showAppBadge;

  @override
  Widget build(BuildContext context) {
    final initials = InitialsAvatar(title: title, size: size);
    final badge = size * 0.36;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: switch (avatarPath) {
              final path? => Image.file(
                File(path),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // Listede ekrandaki boyutta çözülür (kaydırma akıcı kalsın).
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => initials,
              ),
              null => initials,
            },
          ),
          if (showAppBadge)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(packageName: packageName, size: badge),
              ),
            ),
        ],
      ),
    );
  }
}

/// Addan türetilen sabit renkte, iki harfli avatar.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.title, required this.size});

  final String title;
  final double size;

  static const _palettes = [
    [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
    [Color(0xFF26A69A), Color(0xFF00897B)],
    [Color(0xFFEF5350), Color(0xFFEC407A)],
    [Color(0xFFFFA726), Color(0xFFFF7043)],
    [Color(0xFF42A5F5), Color(0xFF1E88E5)],
    [Color(0xFF66BB6A), Color(0xFF43A047)],
    [Color(0xFFAB47BC), Color(0xFF8E24AA)],
    [Color(0xFF8D6E63), Color(0xFF6D4C41)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[title.hashCode.abs() % _palettes.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(title),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// "Ali Veli" → "AV", "aile" → "A", "😀 Grup" → "😀G", boş → "?".
String initialsOf(String title) {
  final words = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  final first = words.first.characters.first;
  final second = words.length > 1 ? words[1].characters.first : '';
  return (first + second).toUpperCase();
}
