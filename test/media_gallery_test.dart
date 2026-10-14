import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/screens/media_gallery_screen.dart';

Conversation _c(String key, String package) => Conversation(
  key: key,
  packageName: package,
  title: 'Yağız Arda',
  isGroup: false,
  lastText: '',
  lastTime: DateTime(2026, 10, 11),
  unread: 0,
  canReply: false,
);

MediaItem _item(String id, String key, DateTime time, {String? kind}) =>
    MediaItem(
      key: key,
      message: Message(
        id: id,
        sender: 'Yağız Arda',
        text: kind == 'video' ? '🎥 Video' : '📷 Fotoğraf',
        time: time,
        outgoing: false,
        // Testte dosya yok: kare "çözülemedi" simgesiyle çizilir.
        mediaPath: '/yok/$id.jpg',
        mediaKind: kind ?? 'photo',
      ),
    );

class _FakeBridge implements CoreBridge {
  _FakeBridge(this.items);

  final List<MediaItem> items;
  List<String>? askedKeys;
  final starCalls = <String, bool>{};

  @override
  Future<List<MediaItem>> media(List<String> keys) async {
    askedKeys = keys;
    return items;
  }

  @override
  Future<void> starMessage(String id, bool value) async =>
      starCalls[id] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final wa = _c('com.whatsapp|Yağız Arda', 'com.whatsapp');
  final ig = _c('com.instagram.android|yagiz.arda', 'com.instagram.android');

  Future<_FakeBridge> pump(
    WidgetTester tester,
    List<MediaItem> items, {
    List<Conversation>? members,
  }) async {
    final bridge = _FakeBridge(items);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaGalleryScreen(
          bridge: bridge,
          title: 'Yağız Arda',
          members: members ?? [wa, ig],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bridge;
  }

  testWidgets('kişinin tüm uygulamalarındaki medya aylara göre', (
    tester,
  ) async {
    final bridge = await pump(tester, [
      _item('a', wa.key, DateTime(2026, 10, 9)),
      _item('b', ig.key, DateTime(2026, 10, 2), kind: 'video'),
      _item('c', wa.key, DateTime(2026, 9, 20)),
    ]);
    expect(bridge.askedKeys, [wa.key, ig.key]);
    expect(find.text('Ekim 2026'), findsOneWidget);
    expect(find.text('Eylül 2026'), findsOneWidget);
    // İki uygulama var: karede hangi uygulamadan geldiği gösterilir.
    expect(find.byTooltip('Instagram'), findsOneWidget);
    expect(find.byTooltip('WhatsApp'), findsNWidgets(2));
  });

  testWidgets('videolar süzülür', (tester) async {
    await pump(tester, [
      _item('a', wa.key, DateTime(2026, 10, 9)),
      _item('b', ig.key, DateTime(2026, 10, 2), kind: 'video'),
    ]);
    expect(find.byKey(const ValueKey('media-a')), findsOneWidget);
    await tester.tap(find.text('Videolar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('media-a')), findsNothing);
    expect(find.byKey(const ValueKey('media-b')), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
  });

  testWidgets('basılı tutunca kaydedilir', (tester) async {
    final bridge = await pump(tester, [
      _item('a', wa.key, DateTime(2026, 10, 9)),
    ]);
    await tester.longPress(find.byKey(const ValueKey('media-a')));
    await tester.pumpAndSettle();
    expect(bridge.starCalls['a'], isTrue);
  });

  testWidgets('medya yoksa açıklama', (tester) async {
    await pump(tester, const [], members: [wa]);
    expect(find.text('Henüz fotoğraf ya da video yok'), findsOneWidget);
  });
}
