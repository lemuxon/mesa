// Tasarım incelemesi için ekran görüntüleri: uydurma örnek verilerle,
// gerçek yazı tipleri ve simgelerle çizilir; build/screens/*.png'ye yazılır.
// Normal test paketinin parçası değil (test/ dışında olduğu için analizci
// test yardımcılarını tanımıyor, aşağıdaki ignore bunun için):
//   flutter test test_screens/screens_test.dart
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
import 'package:mesaj_merkezi/screens/welcome_screen.dart';
import 'package:mesaj_merkezi/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontDir = r'C:\flutter\bin\cache\artifacts\material_fonts';
final _out = Directory('build/screens');
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
    'Ayşe Yılmaz',
    'com.whatsapp',
    'Akşam 8 gibi orada oluruz',
    _ago(minutes: 4),
    unread: 2,
    pinned: true,
  ),
  _c(
    'Proje Ekibi',
    'org.telegram.messenger',
    'Mert: Sunumu yükledim, bakar mısın?',
    _ago(minutes: 18),
    unread: 5,
    group: true,
    important: true,
  ),
  _c(
    'Can Demir',
    'com.instagram.android',
    'Fotoğraf çok güzel olmuş',
    _ago(hours: 1),
  ),
  _c(
    'Oyun Gecesi',
    'web:discord',
    'Zeynep: Bu akşam kim var?',
    _ago(hours: 2),
    unread: 12,
    group: true,
  ),
  _c(
    'Annem',
    'com.whatsapp',
    'Yemek hazır, ne zaman geliyorsun?',
    _ago(hours: 5),
  ),
  _c(
    'Elif Kaya',
    'org.thoughtcrime.securesms',
    'Tamam, yarın konuşuruz',
    _ago(days: 1),
  ),
  _c(
    'Kampüs Duyuru',
    'org.telegram.messenger',
    'Kütüphane cumartesi kapalı',
    _ago(days: 2),
    group: true,
  ),
  _c('Burak', 'com.facebook.orca', 'Görüşürüz 👋', _ago(days: 4)),
];

Message _m(
  String id,
  String text,
  DateTime time, {
  bool out = false,
  String? sender = 'Ayşe Yılmaz',
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
      key: 'com.whatsapp|Ayşe Yılmaz',
      title: 'Ayşe Yılmaz',
      packageName: 'com.whatsapp',
      lastTime: _ago(hours: 5),
      lastText: '',
    ),
    WaitingPerson(
      key: 'com.instagram.android|Can Demir',
      title: 'Can Demir',
      packageName: 'com.instagram.android',
      lastTime: _ago(hours: 1),
      lastText: '',
    ),
    WaitingPerson(
      key: 'org.telegram.messenger|Elif',
      title: 'Elif Kaya',
      packageName: 'org.telegram.messenger',
      lastTime: _ago(minutes: 12),
      lastText: '',
    ),
  ];

  @override
  Future<List<SnoozedConversation>> snoozed() async => [
    SnoozedConversation(
      key: 'com.whatsapp|Annem',
      title: 'Annem',
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
          'title': 'Ayşe Yılmaz',
          'package': 'com.whatsapp',
          'isGroup': false,
          'count': 132,
        },
        {
          'key': 'b',
          'title': 'Proje Ekibi',
          'package': 'org.telegram.messenger',
          'isGroup': true,
          'count': 98,
        },
        {
          'key': 'c',
          'title': 'Can Demir',
          'package': 'com.instagram.android',
          'isGroup': false,
          'count': 61,
        },
        {
          'key': 'd',
          'title': 'Annem',
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
    batteryUnrestricted: false,
    micAllowed: true,
    xiaomi: true,
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
      name: 'Gece otomatik yanıt',
      action: RuleAction.autoReply,
      replyText: 'Şu an uyuyorum, sabah yazarım.',
      activeFrom: 23 * 60,
      activeTo: 8 * 60,
      recentFires: 4,
    ),
    Rule(
      id: 2,
      name: 'Oyun grubunu sessize al',
      action: RuleAction.mute,
      packages: {'com.discord'},
      includeGroups: true,
    ),
    Rule(
      id: 3,
      name: 'Annemden gelenler önemli',
      action: RuleAction.important,
      senderContains: 'Annem',
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
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await tester.runAsync(LocalPrefs.load);
  final boundary = GlobalKey();
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
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
  for (var i = 0; i < 3; i++) {
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
  setUpAll(_loadFonts);

  Conversation chatOf(String title, String package, {bool group = false}) =>
      _c(title, package, '', _now, group: group);

  testWidgets('ekranlar', (tester) async {
    final photo = (await tester.runAsync(_demoPhoto))!;
    // Dosya okuma testin sahte zamanında hiç bitmez; fotoğraf ekranlar
    // çizilmeden önce gerçek zamanda önbelleğe alınır, Image.file oradan bulur.
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
      _m('1', 'Selam! Bu akşam planın var mı?', _ago(days: 1, hours: 3)),
      _m('2', 'Henüz yok, neden?', _ago(days: 1, hours: 3), out: true),
      _m('3', 'Sahilde yeni bir yer açılmış, gidelim mi?', _ago(minutes: 42)),
      _m(
        '4',
        'Manzarası böyle',
        _ago(minutes: 41),
        mediaPath: photo,
        kind: 'photo',
      ),
      _m('5', 'Vay, çok güzelmiş', _ago(minutes: 20), out: true),
      _m('6', 'Kaçta buluşalım?', _ago(minutes: 20), out: true),
      _m('7', 'Akşam 8 gibi orada oluruz', _ago(minutes: 4)),
      _m('8', '🎥 Video', _ago(minutes: 3)),
    ];
    final group = [
      _m('1', 'Sunumu yarın 10\'da yapıyoruz', _ago(hours: 2), sender: 'Mert'),
      _m('2', 'Slaytları kim hazırlıyor?', _ago(hours: 2), sender: 'Selin'),
      _m('3', 'Ben hallederim', _ago(hours: 1), out: true),
      _m('4', 'Süper, teşekkürler', _ago(minutes: 50), sender: 'Selin'),
      _m(
        '5',
        'Sunumu yükledim, bakar mısın?',
        _ago(minutes: 18),
        sender: 'Mert',
      ),
    ];

    await _shoot(
      tester,
      '01_gelen_kutusu',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
    );
    await _shoot(
      tester,
      '02_gelen_kutusu_koyu',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      dark: true,
    );
    await _shoot(
      tester,
      '03_sohbet',
      ChatScreen(
        bridge: _DemoBridge(chat: direct),
        conversation: chatOf('Ayşe Yılmaz', 'com.whatsapp'),
      ),
    );
    await _shoot(
      tester,
      '04_grup_koyu',
      ChatScreen(
        bridge: _DemoBridge(chat: group),
        conversation: chatOf(
          'Proje Ekibi',
          'org.telegram.messenger',
          group: true,
        ),
      ),
      dark: true,
    );
    await _shoot(
      tester,
      '05_kurallar',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () async {
        await tester.tap(find.text('Kurallar'));
        await tester.pumpAndSettle();
      },
    );
    await _shoot(
      tester,
      '07_servisler',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () async {
        await tester.tap(find.text('Servisler'));
        await tester.pumpAndSettle();
      },
    );
    await _shoot(
      tester,
      '08_servis_ekle',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () async {
        await tester.tap(find.text('Servisler'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Servis ekle'));
        await tester.pumpAndSettle();
      },
    );
    await _shoot(tester, '09_ozet', SummaryScreen(bridge: _DemoBridge()));
    await _shoot(
      tester,
      '06_ayarlar',
      HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      after: () async {
        await tester.tap(find.text('Ayarlar'));
        await tester.pumpAndSettle();
      },
    );
    await _shoot(
      tester,
      '07_karsilama',
      Scaffold(body: WelcomeScreen(onGrant: () {})),
    );

    // Başka dillerde: İngilizce ve sağdan sola Arapça.
    for (final lang in ['en', 'ar']) {
      debugSetLanguage(lang);
      await _shoot(
        tester,
        '20_${lang}_gelen_kutusu',
        HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
      );
      await _shoot(
        tester,
        '21_${lang}_sohbet',
        ChatScreen(
          bridge: _DemoBridge(chat: direct),
          conversation: chatOf('Ayşe Yılmaz', 'com.whatsapp'),
        ),
      );
      await _shoot(
        tester,
        '22_${lang}_ayarlar',
        HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
        after: () async {
          await tester.tap(find.text(tr('Ayarlar')));
          await tester.pumpAndSettle();
        },
      );
      await _shoot(
        tester,
        '23_${lang}_servisler',
        HomeScreen(bridge: _DemoBridge(), web: _DemoWeb()),
        after: () async {
          await tester.tap(find.text(tr('Servisler')));
          await tester.pumpAndSettle();
        },
      );
      await _shoot(
        tester,
        '24_${lang}_ozet',
        SummaryScreen(bridge: _DemoBridge()),
      );
    }
    debugSetLanguage('tr');
  });
}
