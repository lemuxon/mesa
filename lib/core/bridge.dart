import 'package:flutter/services.dart';

import 'models.dart';
import 'rules.dart';
import 'settings.dart';
import 'telegram.dart';

/// Kaynak uygulama yanıt yolunu kapatmış; yeni bir bildirim gelene kadar
/// bu sohbete buradan yanıt verilemez.
class NoReplyActionException implements Exception {
  const NoReplyActionException();
}

/// MainActivity.kt'deki kanallara erişim.
class CoreBridge {
  CoreBridge();

  static const _channel = MethodChannel('mesaj_merkezi/core');
  static const _events = EventChannel('mesaj_merkezi/events');

  /// Değişen sohbetin anahtarı. Tek platform aboneliği paylaşılır; aksi halde
  /// her yeni dinleyici yerel taraftaki öncekinin yerine geçer.
  late final Stream<String> changes = _events
      .receiveBroadcastStream()
      .map((key) => key as String)
      .asBroadcastStream();

  /// Servis bağlandığında `true`, bağlantı koptuğunda `false`.
  late final Stream<bool> listenerStatusChanges = _listenerStatus
      .receiveBroadcastStream()
      .map((connected) => connected as bool)
      .asBroadcastStream();

  static const _listenerStatus = EventChannel('mesaj_merkezi/listener_status');

  /// İzin verilmiş ama bağlı değilse yerel taraf yeniden bağlanmayı da ister.
  Future<ListenerStatus> listenerStatus() async => ListenerStatus.fromMap(
    (await _channel.invokeMapMethod<Object?, Object?>('getListenerStatus'))!,
  );

  /// Servis bileşenini kapatıp açarak sistemi yeniden bağlamaya zorlar.
  Future<void> rebindListener() =>
      _channel.invokeMethod<void>('rebindListener');

  Future<void> openListenerSettings() =>
      _channel.invokeMethod<void>('openListenerSettings');

  /// Xiaomi'de otomatik başlatma listesi; bulunamazsa uygulama ayarları.
  Future<void> openAutostartSettings() =>
      _channel.invokeMethod<void>('openAutostartSettings');

  Future<void> openAppSettings() =>
      _channel.invokeMethod<void>('openAppSettings');

  Future<SystemHealth> health() async => SystemHealth.fromMap(
    (await _channel.invokeMapMethod<Object?, Object?>('health'))!,
  );

  /// Hazır yanıtlar bildirimde de tek dokunuşla gönderilebilsin (kopya).
  /// Bildirimler, ana ekran bileşeni ve web servisi ekranı da bu dilde
  /// olsun; null: telefonun dili.
  Future<void> setLanguage(String? code) =>
      _channel.invokeMethod<void>('setLanguage', {'code': code});

  Future<void> setQuickReplies(List<String> replies) =>
      _channel.invokeMethod<void>('setQuickReplies', {'replies': replies});

  /// Şifreli yedek: kullanıcı dosyanın yerini seçer; vazgeçerse null.
  Future<BackupResult?> createBackup(String password) async {
    final m = await _channel.invokeMapMethod<Object?, Object?>('createBackup', {
      'password': password,
    });
    return m == null ? null : BackupResult.fromMap(m);
  }

  /// Geri yüklenecek yedek dosyası (içerik adresi); vazgeçilirse null.
  Future<String?> pickBackupFile() =>
      _channel.invokeMethod<String>('pickBackupFile');

  /// Yedeği geri yükler. Hata kodları: WRONG_PASSWORD, CORRUPT, RESTORE.
  Future<BackupResult> restoreBackup(String uri, String password) async =>
      BackupResult.fromMap(
        (await _channel.invokeMapMethod<Object?, Object?>('restoreBackup', {
          'uri': uri,
          'password': password,
        }))!,
      );

  /// Kategoriye göre kaplanan yer (bayt): database, media, telegram, web, temporary.
  Future<Map<String, int>> storageUsage() async {
    final raw =
        await _channel.invokeMapMethod<String, Object?>('storageUsage') ??
        const {};
    return {for (final e in raw.entries) e.key: (e.value as num).toInt()};
  }

  /// Önbelleği temizler; açılan yer (bayt).
  Future<int> cleanStorage() async =>
      (await _channel.invokeMethod<num>('cleanStorage'))?.toInt() ?? 0;

  /// Ana ekran bileşenini ekleme penceresi; başlatıcı desteklemiyorsa false.
  Future<bool> pinWidget() async =>
      await _channel.invokeMethod<bool>('pinWidget') ?? false;

  /// Pil kısıtlamasını kaldırma onayı (sistem penceresi).
  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  Future<void> openNotificationSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');

  /// Gelen kutusu; [archived] ise yalnızca arşivlenenler.
  Future<List<Conversation>> conversations({bool archived = false}) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'getConversations',
          {'archived': archived},
        ) ??
        const [];
    return raw.map(Conversation.fromMap).toList();
  }

  Future<int> archivedCount() async =>
      await _channel.invokeMethod<int>('archivedCount') ?? 0;

  Future<void> setPinned(String key, bool value) =>
      _channel.invokeMethod<void>('setPinned', {'key': key, 'value': value});

  Future<void> setArchived(String key, bool value) =>
      _channel.invokeMethod<void>('setArchived', {'key': key, 'value': value});

  Future<void> markAllRead() => _channel.invokeMethod<void>('markAllRead');

  /// Tüm mesajlarda arama; Türkçe büyük/küçük harf duyarsız.
  Future<List<SearchHit>> search(String query) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('search', {
          'query': query,
        }) ??
        const [];
    return raw.map(SearchHit.fromMap).toList();
  }

  Future<AppSettings> settings() async => AppSettings.fromMap(
    (await _channel.invokeMapMethod<Object?, Object?>('getSettings'))!,
  );

  Future<void> updateSettings(AppSettings settings) =>
      _channel.invokeMethod<void>('updateSettings', settings.toMap());

  /// Uygulama kilidi açıldı/kapatıldı: yerel ekranlar da uysun.
  Future<void> appLockSetEnabled(bool value) =>
      _channel.invokeMethod<void>('appLockSetEnabled', {'value': value});

  /// Yerel tarafa göre uygulama kilitli mi (web servisi ekranında açılmış olabilir).
  Future<bool> appLockIsLocked() async =>
      await _channel.invokeMethod<bool>('appLockIsLocked') ?? true;

  /// Flutter'daki kilit ekranı açıldı ya da kapandı.
  Future<void> appLockChanged({required bool locked}) =>
      _channel.invokeMethod<void>('appLockChanged', {'locked': locked});

  /// Android 13+: önemli mesaj bildirimleri için izin ister.
  Future<void> requestNotificationPermission() =>
      _channel.invokeMethod<void>('requestNotificationPermission');

  /// Tam boy medyayı (Telegram) indirir; indirilemezse null.
  Future<MediaFile?> downloadMedia(String messageId) async {
    final m = await _channel.invokeMapMethod<Object?, Object?>(
      'downloadMedia',
      {'id': messageId},
    );
    return m == null ? null : MediaFile.fromMap(m);
  }

  /// Gönderilemeyen Telegram mesajını yeniden gönderir; kabul edildiyse true.
  Future<bool> telegramResend(String messageId) async =>
      await _channel.invokeMethod<bool>('telegramResend', {'id': messageId}) ??
      false;

  /// Gönderilemeyen Telegram mesajını siler (karşıya hiç gitmedi).
  Future<void> telegramDeleteFailed(String messageId) =>
      _channel.invokeMethod<void>('telegramDeleteFailed', {'id': messageId});

  /// Gönderilen Telegram medyası yükleniyorsa ilerleme (0..1); değilse null.
  Future<double?> uploadProgress(String messageId) =>
      _channel.invokeMethod<double>('uploadProgress', {'id': messageId});

  /// Telegram dosyası indiriliyorsa ilerleme (0..1); bilinmiyorsa null.
  Future<double?> downloadProgress(String messageId) =>
      _channel.invokeMethod<double>('downloadProgress', {'id': messageId});

  /// Uygulama, birleşik bildirime dokunularak açıldıysa o sohbetin anahtarı (bir kez).
  Future<String?> takeLaunchConversation() =>
      _channel.invokeMethod<String>('takeLaunchConversation');

  /// Uygulama açıkken birleşik bildirime dokunuldu: açılacak sohbetin anahtarı.
  late final Stream<String> openRequests = const EventChannel(
    'mesaj_merkezi/open',
  ).receiveBroadcastStream().map((key) => key as String).asBroadcastStream();

  /// Açık sohbet: bildirimi kaldırılır ve açıkken yeni bildirim gösterilmez.
  Future<void> setActiveConversation(String? key) =>
      _channel.invokeMethod<void>('setActiveConversation', {'key': key});

  /// Kişi ekranı: kişinin tüm sohbetleri açık sayılır (bildirim gösterilmez).
  Future<void> setActiveConversations(List<String> keys) =>
      _channel.invokeMethod<void>('setActiveConversation', {'keys': keys});

  /// Sohbetlerde paylaşılan fotoğraf ve videolar (yeniden eskiye).
  Future<List<MediaItem>> media(List<String> keys) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('media', {
          'keys': keys,
        }) ??
        const [];
    return raw.map(MediaItem.fromMap).toList();
  }

  /// "Aynı kişi mi?" önerileri (en son yazışılanlar önce).
  Future<List<PersonSuggestion>> personSuggestions() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'personSuggestions',
        ) ??
        const [];
    return raw.map(PersonSuggestion.fromMap).toList();
  }

  /// Sohbetleri tek kişide toplar; kişinin kimliği.
  Future<int> mergePeople(List<String> keys, {String? name}) async =>
      (await _channel.invokeMethod<int>('mergePeople', {
        'keys': keys,
        'name': name,
      }))!;

  /// Sohbeti kişiden ayırır (aynı çift yeniden önerilmez).
  Future<void> unmergePerson(String key) =>
      _channel.invokeMethod<void>('unmergePerson', {'key': key});

  Future<void> renamePerson(int id, String name) =>
      _channel.invokeMethod<void>('renamePerson', {'id': id, 'name': name});

  /// "Farklı kişiler": bu çift yeniden önerilmez.
  Future<void> dismissPersonSuggestion(String a, String b) =>
      _channel.invokeMethod<void>('dismissPersonSuggestion', {'a': a, 'b': b});

  /// Sohbeti kaynak uygulamada açar; açılamazsa false.
  Future<bool> openInSourceApp(Conversation c) async =>
      await _channel.invokeMethod<bool>('openInSourceApp', {
        'key': c.key,
        'package': c.packageName,
      }) ??
      false;

  Future<List<Message>> messages(String key) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('getMessages', {
          'key': key,
        }) ??
        const [];
    return raw.map(Message.fromMap).toList();
  }

  /// Sohbete nasıl gönderilir (doğrudan / uygulamada / web / hiç).
  Future<ReplyMode> replyMode(Conversation c) async => ReplyMode.parse(
    await _channel.invokeMethod<String>('replyMode', {
      'key': c.key,
      'package': c.packageName,
    }),
  );

  /// Uygulamanın paylaşımla kabul ettiği türler: photo, video, voice, file.
  Future<Set<String>> shareKinds(String packageName) async =>
      (await _channel.invokeListMethod<String>('shareKinds', {
                'package': packageName,
              }) ??
              const [])
          .toSet();

  /// Kaynak uygulamada gönderilen metni bu sohbete de yazar; kaydın kimliği.
  Future<String?> recordSentViaApp(String key, String text) => _channel
      .invokeMethod<String>('recordSentViaApp', {'key': key, 'text': text});

  /// Tek mesajı yalnızca bu uygulamadan siler.
  Future<void> deleteMessage(String key, String id) =>
      _channel.invokeMethod<void>('deleteMessage', {'key': key, 'id': id});

  /// Kaynak uygulamada sohbeti metin hazır açar; kullanıcı orada gönderir.
  Future<bool> sendViaApp(Conversation c, String text) async =>
      await _channel.invokeMethod<bool>('sendViaApp', {
        'key': c.key,
        'package': c.packageName,
        'text': text,
      }) ??
      false;

  /// [source]: gallery, camera, file. Vazgeçilirse boş liste.
  Future<List<OutgoingMedia>> pickMedia(String source) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('pickMedia', {
          'source': source,
        }) ??
        const [];
    return raw.map(OutgoingMedia.fromMap).toList();
  }

  /// Telegram'a doğrudan gönderilirse "sent", uygulamada hazır açılırsa
  /// "shared", olmazsa "failed".
  Future<String> sendMedia(
    Conversation c,
    List<OutgoingMedia> items, {
    String? caption,
  }) async =>
      await _channel.invokeMethod<String>('sendMedia', {
        'key': c.key,
        'package': c.packageName,
        'items': [for (final i in items) i.toMap()],
        'caption': caption,
      }) ??
      'failed';

  /// Mikrofon izni (yoksa sorulur).
  Future<bool> micPermission() async =>
      await _channel.invokeMethod<bool>('micPermission') ?? false;

  Future<bool> startRecording() async =>
      await _channel.invokeMethod<bool>('startRecording') ?? false;

  /// Kaydı bitirir; [cancel] ya da çok kısa kayıtta null.
  Future<OutgoingMedia?> stopRecording({bool cancel = false}) async {
    final m = await _channel.invokeMapMethod<Object?, Object?>(
      'stopRecording',
      {'cancel': cancel},
    );
    return m == null ? null : OutgoingMedia.fromMap(m);
  }

  /// Telegram'da karşı tarafa "yazıyor…" gösterilir.
  Future<void> telegramTyping(String key) =>
      _channel.invokeMethod<void>('telegramTyping', {'key': key});

  /// Şu anki yazıyor/çevrimiçi durumları.
  Future<List<PresenceState>> presence() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('presence') ??
        const [];
    return raw.map(PresenceState.fromMap).toList();
  }

  late final Stream<PresenceState> presenceChanges =
      const EventChannel('mesaj_merkezi/presence')
          .receiveBroadcastStream()
          .map((m) => PresenceState.fromMap(m as Map<Object?, Object?>))
          .asBroadcastStream();

  // ---- Kaydedilenler, yanıt bekleyenler, hatırlatma, planlı mesaj, özet ----

  Future<void> starMessage(String id, bool value) =>
      _channel.invokeMethod<void>('starMessage', {'id': id, 'value': value});

  Future<List<StarredMessage>> starred() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('starred') ??
        const [];
    return raw.map(StarredMessage.fromMap).toList();
  }

  Future<List<WaitingPerson>> waiting() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('waiting') ??
        const [];
    return raw.map(WaitingPerson.fromMap).toList();
  }

  /// "Yanıt gerekmez": yeni mesaj gelene kadar şeritte görünmez.
  Future<void> dismissWaiting(String key) =>
      _channel.invokeMethod<void>('dismissWaiting', {'key': key});

  /// Sohbet [until] anına kadar gelen kutusundan kalkar, o an hatırlatılır.
  Future<void> snooze(String key, DateTime until) =>
      _channel.invokeMethod<void>('snooze', {
        'key': key,
        'until': until.millisecondsSinceEpoch,
      });

  Future<void> unsnooze(String key) =>
      _channel.invokeMethod<void>('unsnooze', {'key': key});

  Future<List<SnoozedConversation>> snoozed() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('snoozed') ??
        const [];
    return raw.map(SnoozedConversation.fromMap).toList();
  }

  /// Telegram'da sunucuda bekler; diğerlerinde zamanı gelince gönderilir.
  Future<void> scheduleMessage(String key, String text, DateTime at) =>
      _channel.invokeMethod<void>('scheduleMessage', {
        'key': key,
        'text': text,
        'at': at.millisecondsSinceEpoch,
      });

  Future<List<ScheduledMessage>> scheduledMessages({String? key}) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'scheduledMessages',
          {'key': key},
        ) ??
        const [];
    return raw.map(ScheduledMessage.fromMap).toList();
  }

  Future<void> cancelScheduled(int id) =>
      _channel.invokeMethod<void>('cancelScheduled', {'id': id});

  Future<WeeklyStats> stats({int days = 7}) async => WeeklyStats.fromMap(
    (await _channel.invokeMapMethod<Object?, Object?>('stats', {
      'days': days,
    }))!,
  );

  Future<bool> canReply(String key) async =>
      await _channel.invokeMethod<bool>('canReply', {'key': key}) ?? false;

  Future<void> markRead(String key) =>
      _channel.invokeMethod<void>('markRead', {'key': key});

  /// Sohbeti yalnızca Mesa'dan siler; kaynak uygulamaya dokunmaz.
  Future<void> deleteConversation(String key) =>
      _channel.invokeMethod<void>('deleteConversation', {'key': key});

  Future<void> sendReply(String key, String text) async {
    try {
      await _channel.invokeMethod<void>('sendReply', {
        'key': key,
        'text': text,
      });
    } on PlatformException catch (e) {
      if (e.code == 'NO_REPLY_ACTION') throw const NoReplyActionException();
      rethrow;
    }
  }

  // ---- Telegram (TDLib) ----

  static const _telegramEvents = EventChannel('mesaj_merkezi/telegram');

  late final Stream<TelegramStatus> telegramChanges = _telegramEvents
      .receiveBroadcastStream()
      .map((m) => TelegramStatus.fromMap(m as Map<Object?, Object?>))
      .asBroadcastStream();

  Future<TelegramStatus> telegramStatus() async => TelegramStatus.fromMap(
    (await _channel.invokeMapMethod<Object?, Object?>('telegramStatus'))!,
  );

  /// Bağlantıyı açar: ön plan servisini başlatır, bildirim izni ister.
  Future<void> telegramConnect() =>
      _channel.invokeMethod<void>('telegramConnect');

  /// Giriş adımına değer gönderir; hata metni ya da başarıda null döner.
  Future<String?> telegramSubmit(TelegramState state, String value) =>
      _channel.invokeMethod<String>('telegramSubmit', {
        'step': state.step,
        'value': value,
      });

  /// Hata metni ya da başarıda null.
  Future<String?> telegramLogout() =>
      _channel.invokeMethod<String>('telegramLogout');

  Future<List<StickerSetInfo>> telegramStickerSets() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'telegramStickerSets',
        ) ??
        const [];
    return raw.map(StickerSetInfo.fromMap).toList();
  }

  Future<List<PickItem>> telegramStickers(String setId) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'telegramStickers',
          {'setId': setId},
        ) ??
        const [];
    return raw.map(PickItem.fromMap).toList();
  }

  /// Boş sorgu: kaydedilmiş GIF'ler; dolu: Telegram'ın @gif aramasıyla.
  Future<List<PickItem>> telegramGifs(String key, String query) async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('telegramGifs', {
          'key': key,
          'query': query,
        }) ??
        const [];
    return raw.map(PickItem.fromMap).toList();
  }

  /// Seçilen çıkartmayı/GIF'i gönderir; başarısızsa false.
  Future<bool> telegramSendPick(String key, String token) async =>
      await _channel.invokeMethod<bool>('telegramSendPick', {
        'key': key,
        'token': token,
      }) ??
      false;

  /// Sohbetin son mesajlarını Telegram'dan indirir; gelince `changes` tetiklenir.
  Future<void> telegramLoadHistory(String key) =>
      _channel.invokeMethod<void>('telegramLoadHistory', {'key': key});

  Future<List<Rule>> rules() async {
    final raw =
        await _channel.invokeListMethod<Map<Object?, Object?>>('getRules') ??
        const [];
    return raw.map(Rule.fromMap).toList();
  }

  /// Kuralı ekler ya da günceller; kuralın kimliğini döner.
  Future<int> saveRule(Rule rule) async =>
      (await _channel.invokeMethod<int>('saveRule', rule.toMap()))!;

  Future<void> deleteRule(int id) =>
      _channel.invokeMethod<void>('deleteRule', {'id': id});
}
