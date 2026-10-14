import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/format.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:mesaj_merkezi/screens/media_viewer.dart';

Message _photo(String id, int minute) => Message(
  id: id,
  sender: 'Ayşe',
  text: '📷 Fotoğraf',
  time: DateTime(2026, 10, 11, 12, minute),
  outgoing: false,
  mediaPath: '/yok/$id.jpg',
  mediaKind: 'photo',
);

class _FakeBridge implements CoreBridge {
  final download = Completer<MediaFile?>();
  double? progress;
  List<Message> chat = const [];

  @override
  Future<MediaFile?> downloadMedia(String messageId) => download.future;
  @override
  Future<double?> downloadProgress(String messageId) async => progress;

  // Sohbet ekranı.
  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Future<List<Message>> messages(String key) async => chat;
  @override
  Future<ReplyMode> replyMode(Conversation c) async => ReplyMode.app;
  @override
  Future<List<ScheduledMessage>> scheduledMessages({String? key}) async =>
      const [];
  @override
  Future<void> markRead(String key) async {}
  @override
  Future<void> setActiveConversation(String? key) async {}
  @override
  Future<AppSettings> settings() async => const AppSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('süre ve boyut biçimi', () {
    expect(formatDuration(const Duration(seconds: 42)), '0:42');
    expect(formatDuration(const Duration(minutes: 3, seconds: 5)), '3:05');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(formatSize(512), '512 B');
    expect(formatSize(850 * 1024), '850 KB');
    expect(formatSize((4.2 * 1024 * 1024).round()), '4,2 MB');
    expect(formatSize(15 * 1024 * 1024), '15 MB');
    expect(formatMediaInfo(seconds: 83, bytes: 4404019), '1:23 · 4,2 MB');
    expect(formatMediaInfo(), isNull);
  });

  testWidgets('galeride sağa-sola kaydırılır', (tester) async {
    final photos = [_photo('a', 1), _photo('b', 2), _photo('c', 3)];
    await tester.pumpWidget(
      MaterialApp(
        home: MediaViewer(
          bridge: _FakeBridge(),
          message: photos[1],
          gallery: photos,
          titleOf: (m) => m.sender!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2 / 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.textContaining('3 / 3'), findsOneWidget);
  });

  testWidgets('Telegram indirmesinde yüzde ve boyut', (tester) async {
    final bridge = _FakeBridge()..progress = 0.42;
    final video = Message(
      id: 'tg-1-2',
      sender: 'Ayşe',
      text: '🎥 Video',
      time: DateTime(2026, 10, 11),
      outgoing: false,
      mediaKind: 'video',
      downloadable: true,
      mediaSize: 10 * 1024 * 1024,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaViewer(bridge: bridge, message: video),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('İndiriliyor… %42'), findsOneWidget);
    expect(find.text('4,2 MB / 10 MB'), findsOneWidget);

    bridge.download.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Medya açılamadı.'), findsOneWidget);
  });

  testWidgets('video önizlemesinde süre ve boyut', (tester) async {
    final bridge = _FakeBridge()
      ..chat = [
        Message(
          id: 'tg-1-3',
          sender: 'Ayşe',
          text: '🎥 Video',
          time: DateTime(2026, 10, 11, 12),
          outgoing: false,
          mediaPath: '/yok/kapak.jpg',
          mediaKind: 'video',
          downloadable: true,
          mediaDuration: 83,
          mediaSize: 4404019,
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          bridge: bridge,
          conversation: Conversation(
            key: 'com.whatsapp|Ayşe',
            packageName: 'com.whatsapp',
            title: 'Ayşe',
            isGroup: false,
            lastText: '',
            lastTime: DateTime(2026, 10, 11),
            unread: 0,
            canReply: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1:23 · 4,2 MB'), findsOneWidget);
  });

  testWidgets('bildirim önizlemesinde "Tam boyut" kaynak uygulamayı açar', (
    tester,
  ) async {
    final opened = <String>[];
    final photo = _photo('ig1', 5);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaViewer(
          bridge: _FakeBridge(),
          message: photo,
          sourceAppOf: (_) => 'Instagram',
          onOpenInApp: (m) => opened.add(m.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tam boyut'));
    expect(opened, ['ig1']);
  });

  testWidgets('Telegram dosyasında "Tam boyut" yok', (tester) async {
    final video = Message(
      id: 'tg-1-9',
      sender: 'Ayşe',
      text: '🎥 Video',
      time: DateTime(2026, 10, 11),
      outgoing: false,
      mediaKind: 'video',
      downloadable: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaViewer(
          bridge: _FakeBridge(),
          message: video,
          sourceAppOf: (_) => 'Telegram',
          onOpenInApp: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tam boyut'), findsNothing);
  });
}
