import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/apps.dart';
import 'package:mesaj_merkezi/core/web_services.dart';
import 'package:mesaj_merkezi/screens/services_screen.dart';

class _FakeWeb implements WebBridge {
  _FakeWeb([List<WebService> services = const [], this.apps_ = const []])
    : services_ = [...services];

  final List<WebService> services_;
  final List<InstalledApp> apps_;
  final openedApps = <String>[];
  final added = <String>[];
  final opened = <String>[];
  final updates = <Map<String, Object?>>[];
  final removed = <String>[];

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<WebService>> services() async {
    WebRegistry.update(services_);
    return List.of(services_);
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
    WebCatalogItem(id: 'snapchat', name: 'Snapchat', color: Color(0xFFE6C800)),
  ];

  @override
  Future<bool> profilesSupported() async => true;

  @override
  Future<List<InstalledApp>> apps() async => apps_;

  @override
  Future<bool> openApp(String packageName) async {
    openedApps.add(packageName);
    return true;
  }

  @override
  Future<String> add(String catalogId) async {
    added.add(catalogId);
    services_.add(
      WebService(
        id: catalogId,
        catalogId: catalogId,
        name: catalogId,
        url: 'https://example.com',
        color: const Color(0xFF5865F2),
      ),
    );
    return catalogId;
  }

  @override
  Future<String> addCustom(String name, String url) async {
    if (!url.contains('.')) throw const InvalidWebUrlException();
    added.add('site:$url');
    return 'site-1';
  }

  @override
  Future<void> open(String id) async => opened.add(id);

  @override
  Future<void> update(
    String id, {
    String? name,
    bool? background,
    bool? notify,
    bool? autoplay,
  }) async => updates.add({
    'id': id,
    'name': name,
    'background': background,
    'notify': notify,
    'autoplay': ?autoplay,
  });

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    services_.removeWhere((s) => s.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _discord = WebService(
  id: 'discord',
  catalogId: 'discord',
  name: 'Discord',
  url: 'https://discord.com/app',
  color: Color(0xFF5865F2),
  unread: 3,
);

const _slack = WebService(
  id: 'slack',
  catalogId: 'slack',
  name: 'Slack',
  url: 'https://app.slack.com/client',
  color: Color(0xFF611F69),
  unread: WebService.unreadDot,
  background: false,
);

Future<void> _pump(WidgetTester tester, WebBridge bridge) async {
  await tester.pumpWidget(MaterialApp(home: ServicesScreen(bridge: bridge)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boş listede servis ekleme ve hızlı ekleme çipleri', (
    tester,
  ) async {
    final web = _FakeWeb();
    await _pump(tester, web);

    expect(find.text('Henüz web servisi yok'), findsOneWidget);
    // Uygulaması kurulu olan (Instagram) hızlı eklemede önerilmez.
    expect(find.widgetWithText(ActionChip, 'Discord'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Instagram'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, 'Discord'));
    await tester.pumpAndSettle();
    expect(web.added, ['discord']);
    // Eklenen servis giriş yapılsın diye hemen açılır.
    expect(web.opened, ['discord']);
  });

  testWidgets('ekleme listesi katalogu, kurulu uygulamayı ve notu gösterir', (
    tester,
  ) async {
    final web = _FakeWeb([_discord]);
    await _pump(tester, web);

    await tester.tap(find.text('Servis ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Snapchat'), findsOneWidget);
    expect(find.text('Ekli · ikinci hesap eklenir'), findsOneWidget);
    expect(
      find.text('Uygulaması kurulu, bildirimleri zaten geliyor'),
      findsOneWidget,
    );
    expect(find.textContaining('KakaoTalk'), findsOneWidget);

    await tester.tap(find.text('Snapchat'));
    await tester.pumpAndSettle();
    expect(web.added, ['snapchat']);
    expect(web.opened, ['snapchat']);
  });

  testWidgets('servis kutusu okunmamış sayısını ve durumu gösterir', (
    tester,
  ) async {
    final web = _FakeWeb([_discord, _slack]);
    await _pump(tester, web);

    expect(find.text('3 okunmamış'), findsWidgets);
    expect(find.text('Okunmamış var'), findsOneWidget);

    await tester.tap(find.text('Discord'));
    await tester.pumpAndSettle();
    expect(web.opened, ['discord']);
  });

  testWidgets('ayarlarda arka plan kapatılır ve servis kaldırılır', (
    tester,
  ) async {
    final web = _FakeWeb([_discord]);
    await _pump(tester, web);

    await tester.tap(find.byTooltip('Discord ayarları'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arka planda bağlı kalsın'));
    await tester.pumpAndSettle();
    expect(web.updates.single, {
      'id': 'discord',
      'name': null,
      'background': false,
      'notify': null,
    });

    await tester.tap(find.text('Kaldır'));
    await tester.pumpAndSettle();
    expect(find.text('Discord kaldırılsın mı?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Kaldır'));
    await tester.pumpAndSettle();
    expect(web.removed, ['discord']);
    expect(find.text('Henüz web servisi yok'), findsOneWidget);
  });

  testWidgets('başka site eklerken geçersiz adres reddedilir', (tester) async {
    final web = _FakeWeb([_discord]);
    await _pump(tester, web);

    await tester.tap(find.text('Servis ekle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Başka bir site'));
    await tester.tap(find.text('Başka bir site'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Adres'), 'site');
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
    await tester.pumpAndSettle();
    expect(
      find.text('https ile açılan geçerli bir site adresi yazın.'),
      findsOneWidget,
    );
    expect(web.added, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Adres'),
      'vk.com/im',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
    await tester.pumpAndSettle();
    expect(web.added, ['site:vk.com/im']);
    expect(web.opened, ['site-1']);
  });

  testWidgets('telefondaki uygulamalar okunmamışlarıyla görünür ve açılır', (
    tester,
  ) async {
    final web = _FakeWeb(const [], const [
      InstalledApp(
        packageName: 'com.whatsapp',
        name: 'WhatsApp',
        color: Color(0xFF25D366),
        unread: 4,
      ),
      InstalledApp(
        packageName: 'com.instagram.android',
        name: 'Instagram',
        color: Color(0xFFE1306C),
      ),
    ]);
    await _pump(tester, web);

    expect(find.text('Uygulamalar'), findsOneWidget);
    expect(find.text('Web servisleri'), findsOneWidget);
    expect(find.text('4 okunmamış'), findsOneWidget);
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(web.openedApps, ['com.whatsapp']);
  });

  testWidgets('ayarlardan videolar kapatılır', (tester) async {
    final web = _FakeWeb([_discord]);
    await _pump(tester, web);

    await tester.tap(find.byTooltip('Discord ayarları'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Videolar kendiliğinden oynasın'));
    await tester.pumpAndSettle();
    expect(web.updates.single['autoplay'], isFalse);
  });

  test('web sohbetinin uygulama adı servis listesinden gelir', () {
    WebRegistry.update(const [
      WebService(
        id: 'discord-2',
        catalogId: 'discord',
        name: 'Discord (iş)',
        url: 'https://discord.com/app',
        color: Color(0xFF5865F2),
      ),
    ]);
    expect(MessagingApp.of('web:discord-2').name, 'Discord (iş)');
    // Liste henüz okunmadıysa katalogdaki ad.
    expect(MessagingApp.of('web:slack').name, 'Slack');
    expect(MessagingApp.of('web:slack-3').name, 'Slack');
    expect(MessagingApp.of('web:site-abc').name, 'Web');
    expect(MessagingApp.isWeb('web:x'), isTrue);
    expect(MessagingApp.isWeb('com.whatsapp'), isFalse);
    expect(MessagingApp.of('com.kakao.talk').name, 'KakaoTalk');
  });

  testWidgets('kurulu olmayan katalog servisi kendi simgesiyle görünür', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WebServiceIcon(
            name: 'Slack',
            color: Color(0xFF611F69),
            catalogId: 'slack',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(
      (provider.imageProvider as AssetImage).assetName,
      'assets/web_icons/slack.png',
    );
    expect(find.text('S'), findsNothing);
  });
}
