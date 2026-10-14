import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/apps.dart';
import 'package:mesaj_merkezi/core/models.dart';

void main() {
  test('Conversation, yerel taraftaki harita biçimini okur', () {
    final c = Conversation.fromMap({
      'key': 'com.whatsapp|Ali',
      'package': 'com.whatsapp',
      'title': 'Ali',
      'isGroup': false,
      'lastText': 'Selam',
      'lastTime': 1760000000000,
      'unread': 2,
      'canReply': true,
    });
    expect(c.title, 'Ali');
    expect(c.unread, 2);
    expect(c.canReply, isTrue);
    expect(c.lastTime.millisecondsSinceEpoch, 1760000000000);
  });

  test('canReply yoksa false kabul edilir', () {
    final c = Conversation.fromMap({
      'key': 'k',
      'package': 'org.telegram.messenger',
      'title': 'Grup',
      'isGroup': true,
      'lastText': '',
      'lastTime': 0,
      'unread': 0,
    });
    expect(c.canReply, isFalse);
  });

  test('Message, gönderensiz (kendi) mesajı okur', () {
    final m = Message.fromMap({
      'id': 'out-1',
      'sender': null,
      'text': 'Tamam',
      'time': 1760000000000,
      'outgoing': true,
    });
    expect(m.sender, isNull);
    expect(m.outgoing, isTrue);
  });

  test('Message görsel alanlarını okur', () {
    final m = Message.fromMap({
      'id': 'x',
      'sender': 'Ali',
      'text': 'Çıkartma',
      'time': 0,
      'outgoing': false,
      'mediaPath': '/data/media/a.webp',
      'mediaMime': 'image/webp',
    });
    expect(m.mediaPath, '/data/media/a.webp');
    expect(m.mediaMime, 'image/webp');
    expect(m.textIsMediaLabel, isTrue);
  });

  test('görsel etiketi ile gerçek metin ayrılır', () {
    Message text(String t) => Message(
      id: 'x',
      sender: null,
      text: t,
      time: DateTime(0),
      outgoing: false,
    );
    expect(text('GIF').textIsMediaLabel, isTrue);
    expect(text('📷 Fotoğraf').textIsMediaLabel, isTrue);
    expect(text('😀 Çıkartma').textIsMediaLabel, isTrue); // Telegram
    expect(
      text('📷 Fotoğraf: tatilden').textIsMediaLabel,
      isFalse,
    ); // altyazılı
    expect(text('çıkartma gönder').textIsMediaLabel, isFalse);
  });

  test('bilinmeyen paket adıyla gösterilir', () {
    expect(MessagingApp.of('com.whatsapp').name, 'WhatsApp');
    expect(MessagingApp.of('com.ornek.uygulama').name, 'com.ornek.uygulama');
  });
}
