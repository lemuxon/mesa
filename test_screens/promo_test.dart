// Tanıtım görselleri için İngilizce ekranlar (uydurma örnek veriler):
// build/promo/*.png. Üretildi: screens_test.dart'tan (örnek veriler İngilizce).
// Çerçeve ve başlıklar: python tool/branding/make_promo.py
// Normal test paketinin parçası değil (test/ dışında olduğu için analizci
// test yardımcılarını tanımıyor, aşağıdaki ignore bunun için):
//   flutter test test_screens/promo_test.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/app_scope.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/lock.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/rules.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/core/telegram.dart';
import 'package:mesaj_merkezi/core/web_services.dart';
import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:mesaj_merkezi/screens/home_screen.dart';
import 'package:mesaj_merkezi/screens/summary_screen.dart';
import 'package:mesaj_merkezi/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontDir = r'C:\flutter\bin\cache\artifacts\material_fonts';
final _out = Directory('build/promo');
final _now = DateTime.now();

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
    _now.subtract(Duration(days: days, hours: hours, minutes: minutes));

Conversation _c(
  String title,
  String package,
  String last,
  DateTime time, {
  int unread = 0,
  bool pinned = false,
  bool important = false,
  bool group = false,
}) => Conversation(
  key: '$package|$title',
  packageName: package,
  title: title,
  isGroup: group,
  lastText: last,
  lastTime: time,
  unread: unread,
  pinned: pinned,
  important: important,
  canReply: true,
);

final _inbox = [
  _c(
    'Emma Wilson',
    'com.whatsapp',
    'Around 8, see you there',
    _ago(minutes: 4),
    unread: 2,
    pinned: true,
  ),
  _c(
    'Project Team',
    'org.telegram.messenger',
    'Liam: Uploaded the deck, can you check?',
    _ago(minutes: 18),
    unread: 5,
    group: true,
    important: true,
  ),
  _c(
    'Noah Carter',
    'com.instagram.android',
    'That photo looks amazing 😍',
    _ago(hours: 1),
  ),
  _c(
    'Game Night',
    'web:discord',
    "Ava: Who's in tonight?",
    _ago(hours: 2),
    unread: 12,
    group: true,
  ),
  _c(
    'Mom',
    'com.whatsapp',
    "Dinner's ready, when are you coming?",
    _ago(hours: 5),
  ),
  _c(
    'Olivia Brown',
    'org.thoughtcrime.securesms',
    "Sure, let's talk tomorrow",
    _ago(days: 1),
  ),
  _c(
    'Campus News',
    'org.telegram.messenger',
    'Library is closed on Saturday',
    _ago(days: 2),
    group: true,
  ),
  _c('Lucas', 'com.facebook.orca', 'See you 👋', _ago(days: 4)),
];

Message _m(
  String id,
  String text,
  DateTime time, {
  bool out = false,
  String? sender = 'Emma Wilson',
  String? mediaPath,
  String? kind,
}) => Message(
  id: id,
  sender: out ? null : sender,
  text: text,
  time: time,
  outgoing: out,
  mediaPath: mediaPath,
  mediaKind: kind,
);

const _demoServices = [
  WebService(
    id: 'discord',
    catalogId: 'discord',
    name: 'Discord',
    url: 'https://discord.com/app',
    color: Color(0xFF5865F2),
    unread: 12,
    loaded: true,
  ),
  WebService(
    id: 'slack',
    catalogId: 'slack',
    name: 'Slack',
    url: 'https://app.slack.com/client',
    color: Color(0xFF611F69),
    unread: WebService.unreadDot,
    loaded: true,
  ),
  WebService(
    id: 'x',
    catalogId: 'x',
    name: 'X',
    url: 'https://x.com/messages',
    color: Color(0xFF536471),
    loaded: true,
  ),
  WebService(
    id: 'snapchat',
    catalogId: 'snapchat',
    name: 'Snapchat',
    url: 'https://web.snapchat.com/',
    color: Color(0xFFE6C800),
    unread: 2,
    loaded: true,
  ),
  WebService(
    id: 'teams',
    catalogId: 'teams',
    name: 'Teams',
    url: 'https://teams.microsoft.com/',
    color: Color(0xFF6264A7),
    background: false,
  ),
];

class _DemoWeb implements WebBridge {
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<List<WebService>> services() async {
    WebRegistry.update(_demoServices);
    return _demoServices;
  }

  @override
  Future<List<WebCatalogItem>> catalog() async => const [
    WebCatalogItem(id: 'discord', name: 'Discord', color: Color(0xFF5865F2)),
    WebCatalogItem(
      id: 'instagram',
      name: 'Instagram',
      color: Color(0xFFE1306C),
      appInstalled: true,
    ),
    WebCatalogItem(
      id: 'messenger',
      name: 'Messenger',
      color: Color(0xFF0084FF),
    ),
    WebCatalogItem(id: 'slack', name: 'Slack', color: Color(0xFF611F69)),
    WebCatalogItem(id: 'x', name: 'X', color: Color(0xFF536471)),
    WebCatalogItem(id: 'linkedin', name: 'LinkedIn', color: Color(0xFF0A66C2)),
    WebCatalogItem(id: 'reddit', name: 'Reddit', color: Color(0xFFFF4500)),
    WebCatalogItem(id: 'snapchat', name: 'Snapchat', color: Color(0xFFE6C800)),
    WebCatalogItem(id: 'tiktok', name: 'TikTok', color: Color(0xFF010101)),
    WebCatalogItem(id: 'teams', name: 'Teams', color: Color(0xFF6264A7)),
  ];
  @override
  Future<bool> profilesSupported() async => true;

  @override
  Future<List<InstalledApp>> apps() async => const [
    InstalledApp(
      packageName: 'com.whatsapp',
      name: 'WhatsApp',
      color: Color(0xFF25D366),
      unread: 2,
    ),
    InstalledApp(
      packageName: 'org.telegram.messenger',
      name: 'Telegram',
      color: Color(0xFF229ED9),
      unread: 5,
    ),
    InstalledApp(
      packageName: 'com.instagram.android',
      name: 'Instagram',
      color: Color(0xFFE1306C),
    ),
    InstalledApp(
      packageName: 'com.snapchat.android',
      name: 'Snapchat',
      color: Color(0xFFE6C800),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DemoBridge implements CoreBridge {
  _DemoBridge({this.chat = const []});

  final List<Message> chat;

  @override
  Future<List<WaitingPerson>> waiting() async => [
    WaitingPerson(
      key: 'com.whatsapp|Emma Wilson',
      title: 'Emma Wilson',
      packageName: 'com.whatsapp',
      lastTime: _ago(hours: 5),
      lastText: '',
    ),
    WaitingPerson(
      key: 'com.instagram.android|Noah Carter',
      title: 'Noah Carter',
      packageName: 'com.instagram.android',
      lastTime: _ago(hours: 1),
      lastText: '',
    ),
    WaitingPerson(
      key: 'org.telegram.messenger|Olivia',
      title: 'Olivia Brown',
      packageName: 'org.telegram.messenger',
      lastTime: _ago(minutes: 12),
      lastText: '',
    ),
  ];

  @override
  Future<List<SnoozedConversation>> snoozed() async => [
    SnoozedConversation(
      key: 'com.whatsapp|Mom',
      title: 'Mom',
      packageName: 'com.whatsapp',
      until: _now.add(const Duration(hours: 3)),
    ),
  ];

  @override
  Future<WeeklyStats> stats({int days = 7}) async {
    String day(int ago) {
      final d = _now.subtract(Duration(days: ago));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return WeeklyStats.fromMap({
      'perDay': [
        for (final (ago, n) in [
          (6, 84),
          (5, 120),
          (4, 96),
          (3, 143),
          (2, 77),
          (1, 168),
          (0, 52),
        ])
          {'day': day(ago), 'count': n},
      ],
      'perApp': [
        {'package': 'com.whatsapp', 'count': 412},
        {'package': 'org.telegram.messenger', 'count': 198},
        {'package': 'com.instagram.android', 'count': 86},
        {'package': 'web:discord', 'count': 44},
      ],
      'top': [
        {
          'key': 'a',
          'title': 'Emma Wilson',
          'package': 'com.whatsapp',
          'isGroup': false,
          'count': 132,
        },
        {
          'key': 'b',
          'title': 'Project Team',
          'package': 'org.telegram.messenger',
          'isGroup': true,
          'count': 98,
        },
        {
          'key': 'c',
          'title': 'Noah Carter',
          'package': 'com.instagram.android',
          'isGroup': false,
          'count': 61,
        },
        {
          'key': 'd',
          'title': 'Mom',
          'package': 'com.whatsapp',
          'isGroup': false,
          'count': 40,
        },
      ],
      'busiestHour': 21,
      'incoming': 488,
      'outgoing': 252,
      'people': 23,
      'deleted': 3,
    });
  }

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Stream<bool> get listenerStatusChanges => const Stream.empty();
  @override
  Stream<String> get openRequests => const Stream.empty();
  @override
  Future<String?> takeLaunchConversation() async => null;
  @override
  Future<ListenerStatus> listenerStatus() async =>
      const ListenerStatus(enabled: true, connected: true);
  @override
  Future<List<Conversation>> conversations({bool archived = false}) async =>
      archived ? const [] : _inbox;
  @override
  Future<int> archivedCount() async => 3;
  @override
  Future<AppSettings> settings() async =>
      const AppSettings(unifiedNotifications: true);
  // Kurulum listesi: Xiaomi, pil kısıtlaması açık, Telegram bağlı.
  @override
  Future<SystemHealth> health() async => const SystemHealth(
    listenerEnabled: true,
    listenerConnected: true,
    notificationsAllowed: true,
    batteryUnrestricted: true,
    micAllowed: true,
    xiaomi: false,
  );
  @override
  Future<TelegramStatus> telegramStatus() async => const TelegramStatus(
    configured: true,
    enabled: true,
    state: TelegramState.ready,
  );
  @override
  Future<List<Rule>> rules() async => const [
    Rule(
      id: 1,
      name: 'Night auto-reply',
      action: RuleAction.autoReply,
      replyText: "I'm asleep, I'll text you in the morning.",
      activeFrom: 23 * 60,
      activeTo: 8 * 60,
      recentFires: 4,
    ),
    Rule(
      id: 2,
      name: 'Mute the gaming group',
      action: RuleAction.mute,
      packages: {'com.discord'},
      includeGroups: true,
    ),
    Rule(
      id: 3,
      name: 'Mom is always important',
      action: RuleAction.important,
      senderContains: 'Mom',
      recentFires: 9,
    ),
  ];
  @override
  Future<List<Message>> messages(String key) async => chat;
  @override
  Future<bool> canReply(String key) async => true;
  @override
  Future<void> markRead(String key) async {}
  @override
  Future<void> setActiveConversation(String? key) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('$_fontDir\\$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
  // Emojiler kutu olarak çıkmasın (telefonda sistemin emoji yazı tipi var).
  final emoji = FontLoader('EmojiFallback');
  final bytes = File(r'C:\Windows\Fonts\seguiemj.ttf').readAsBytesSync();
  emoji.addFont(Future.value(ByteData.view(bytes.buffer)));
  await emoji.load();
  // Roboto'da Arapça harf yok: Windows'un Segoe UI'ı yedek yazı tipi.
  final arabic = FontLoader('ArabicFallback');
  arabic.addFont(
    Future.value(
      ByteData.view(
        File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytesSync().buffer,
      ),
    ),
  );
  await arabic.load();
}

ThemeData _withEmoji(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(
    fontFamilyFallback: const ['EmojiFallback', 'ArabicFallback'],
  ),
);

/// Örnek bir "fotoğraf": gün batımı degradesi.
Future<String> _demoPhoto() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(600, 420);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
        const Color(0xFFFF8A65),
        const Color(0xFF7E57C2),
      ]),
  );
  canvas.drawCircle(
    const Offset(420, 240),
    70,
    Paint()..color = const Color(0xFFFFE082),
  );
  final hills = Path()
    ..moveTo(0, 330)
    ..quadraticBezierTo(150, 260, 300, 320)
    ..quadraticBezierTo(450, 380, 600, 300)
    ..lineTo(600, 420)
    ..lineTo(0, 420)
    ..close();
  canvas.drawPath(hills, Paint()..color = const Color(0xFF283593));
  final image = await recorder.endRecording().toImage(600, 420);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}\\mm_demo_photo.png');
  await file.writeAsBytes(png!.buffer.asUint8List());
  return file.path;
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget home, {
  bool dark = false,
  Future<void> Function()? after,
  Map<String, Object> extraPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'setup_snoozed_until': DateTime(2100).millisecondsSinceEpoch,
    'tip_index': 99,
    ...extraPrefs,
  });
  final prefs = await tester.runAsync(LocalPrefs.load);
  final boundary = GlobalKey();
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  tester.view.padding = const FakeViewPadding(top: 63, bottom: 42);
  tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 42);
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: AppScope(
        prefs: prefs!,
        authenticator: _NoAuth(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          supportedLocales: [for (final code in languages.keys) Locale(code)],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: _withEmoji(AppTheme.light()),
          darkTheme: _withEmoji(AppTheme.dark()),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (after != null) await after();
  // Gömülü simgeler (Image.asset) gerçek zamanda çözülür; beklenmezse boş çıkar.
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
  }
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2.625);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    _out.createSync(recursive: true);
    File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

class _NoAuth implements Authenticator {
  @override
  Future<bool> authenticate(String reason) async => true;
  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    debugSetLanguage('en');
  });
  tearDownAll(() => debugSetLanguage('tr'));

  Conversation chatOf(String title, String package, {bool group = false}) =>
      _c(title, package, '', _now, group: group);

  testWidgets('tanıtım', (tester) async {
    // Gerçek gölgeler (testte varsayılan: düz siyah kenar).
    debugDisableShadows = false;
    final photo = (await tester.runAsync(_demoPhoto))!;
    await tester.runAsync(() async {
      final loaded = Completer<void>();
      FileImage(File(photo))
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (_, _) => loaded.complete(),
              onError: (e, _) => loaded.completeError(e),
            ),
          );
      await loaded.future;
    });
    final direct = [
      _m('1', 'Hey! Any plans tonight?', _ago(days: 1, hours: 3)),
      _m('2', 'Not yet, why?', _ago(days: 1, hours: 3), out: true),
      _m(
        '3',
        'A new place opened by the beach, want to go?',
        _ago(minutes: 42),
      ),
      _m(
        '4',
        'This is the view',
        _ago(minutes: 41),
        mediaPath: photo,
        kind: 'photo',
      ),
      _m('5', 'Wow, that looks amazing', _ago(minutes: 20), out: true),
      _m('6', 'What time should we meet?', _ago(minutes: 20), out: true),
      _m('7', 'Around 8, see you there', _ago(minutes: 4)),
    ];
    final group = [
      _m('1', 'We present tomorrow at 10', _ago(hours: 2), sender: 'Liam'),
      _m('2', "Who's preparing the slides?", _ago(hours: 2), sender: 'Sophie'),
      _m('3', "I'll handle it", _ago(hours: 1), out: true),
      _m('4', 'Great, thanks!', _ago(minutes: 50), sender: 'Sophie'),
      _m(
        '5',
        'Uploaded the deck, can you check?',
        _ago(minutes: 18),
        sender: 'Liam',
      ),
    ];
    Future<void> tab(String label) async {
      await tester.tap(find.text(tr(label)));
      await tester.pumpAndSettle();
    }

    await _shoot(
      tester,
      'inbox',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
    );
    await _shoot(
      tester,
      'inbox_dark',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      dark: true,
    );
    await _shoot(
      tester,
      'chat',
      ChatScreen(
        bridge: _DemoBridge(chat: direct),
        conversation: chatOf('Emma Wilson', 'com.whatsapp'),
      ),
    );
    await _shoot(
      tester,
      'group_dark',
      ChatScreen(
        bridge: _DemoBridge(chat: group),
        conversation: chatOf(
          'Project Team',
          'org.telegram.messenger',
          group: true,
        ),
      ),
      dark: true,
      extraPrefs: {'ghost_hint_seen': true},
    );
    await _shoot(
      tester,
      'services',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () => tab('Servisler'),
    );
    await _shoot(
      tester,
      'rules',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () => tab('Kurallar'),
    );
    await _shoot(tester, 'summary', SummaryScreen(bridge: _DemoBridge()));
    await _shoot(
      tester,
      'language',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () async {
        await tab('Ayarlar');
        await tester.tap(find.text(tr('Uygulamanın dili')));
        await tester.pumpAndSettle();
      },
    );
    for (final lang in ['ar', 'ru', 'es']) {
      debugSetLanguage(lang);
      await _shoot(
        tester,
        'inbox_$lang',
        HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      );
    }
    debugSetLanguage('en');
    debugDisableShadows = true;
  });
}
