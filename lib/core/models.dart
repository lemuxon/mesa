/// Yerel taraftaki (Kotlin) MessageStore'un döndürdüğü kayıtların Dart karşılıkları.
library;

import '../l10n/l10n.dart';

class Conversation {
  const Conversation({
    required this.key,
    required this.packageName,
    required this.title,
    required this.isGroup,
    required this.lastText,
    required this.lastTime,
    required this.unread,
    this.important = false,
    this.pinned = false,
    this.archived = false,
    this.avatarPath,
    required this.canReply,
    this.reminded = false,
    this.personId,
    this.personName,
  });

  factory Conversation.fromMap(Map<Object?, Object?> m) => Conversation(
    key: m['key']! as String,
    packageName: m['package']! as String,
    title: m['title']! as String,
    isGroup: m['isGroup']! as bool,
    lastText: m['lastText']! as String,
    lastTime: DateTime.fromMillisecondsSinceEpoch(m['lastTime']! as int),
    unread: m['unread']! as int,
    important: m['important'] as bool? ?? false,
    pinned: m['pinned'] as bool? ?? false,
    archived: m['archived'] as bool? ?? false,
    avatarPath: m['avatarPath'] as String?,
    canReply: m['canReply'] as bool? ?? false,
    reminded: m['reminded'] as bool? ?? false,
    personId: m['personId'] as int?,
    personName: m['personName'] as String?,
  );

  final String key;
  final String packageName;
  final String title;
  final bool isGroup;
  final String lastText;
  final DateTime lastTime;
  final int unread;

  /// "Önemli işaretle" kuralı çalıştı; sohbet açılana kadar listenin en üstünde.
  final bool important;

  /// "Sonra hatırlat" zamanı geldi; açılana kadar en üstte ⏰ ile.
  final bool reminded;

  /// Gelen kutusunun en üstünde sabit.
  final bool pinned;

  /// Gelen kutusunda görünmez; Arşiv ekranında listelenir.
  final bool archived;

  /// Kişi ya da grup fotoğrafı (bildirimden ya da Telegram'dan); yoksa null.
  final String? avatarPath;

  /// Kaynak uygulamanın bildiriminden alınmış, hâlâ geçerli bir yanıt yolu var mı.
  final bool canReply;

  /// Kullanıcının birleştirdiği kişi (aynı kişinin başka uygulamalardaki
  /// sohbetleriyle birlikte); yoksa null.
  final int? personId;
  final String? personName;
}

/// Alınan ya da geri yüklenen yedeğin özeti.
class BackupResult {
  const BackupResult({
    required this.messages,
    required this.files,
    required this.bytes,
  });

  factory BackupResult.fromMap(Map<Object?, Object?> m) => BackupResult(
    messages: (m['messages'] as num?)?.toInt() ?? 0,
    files: (m['files'] as num?)?.toInt() ?? 0,
    bytes: (m['bytes'] as num?)?.toInt() ?? 0,
  );

  final int messages;

  /// Fotoğraf ve profil resmi sayısı.
  final int files;

  /// Şifreli dosyanın boyutu (geri yüklemede 0).
  final int bytes;
}

/// Galerideki bir fotoğraf/video ve ait olduğu sohbet.
class MediaItem {
  const MediaItem({required this.key, required this.message});

  factory MediaItem.fromMap(Map<Object?, Object?> m) =>
      MediaItem(key: m['key']! as String, message: Message.fromMap(m));

  final String key;
  final Message message;
}

/// "Aynı kişi mi?" önerisi: farklı uygulamalardaki iki sohbet.
class PersonSuggestion {
  const PersonSuggestion({
    required this.a,
    required this.b,
    required this.reason,
  });

  factory PersonSuggestion.fromMap(Map<Object?, Object?> m) => PersonSuggestion(
    a: m['a']! as String,
    b: m['b']! as String,
    reason: m['reason'] as String? ?? 'name',
  );

  final String a;
  final String b;

  /// "name" (ad aynı) ya da "phone" (numara aynı).
  final String reason;
}

/// İndirilmiş tam boy medya.
class MediaFile {
  const MediaFile({required this.path, this.kind});

  factory MediaFile.fromMap(Map<Object?, Object?> m) =>
      MediaFile(path: m['path']! as String, kind: m['kind'] as String?);

  final String path;

  /// photo, video, animation.
  final String? kind;

  bool get isVideo => kind == 'video' || kind == 'animation';
}

/// Arama sonucu: eşleşen mesaj ve ait olduğu sohbet.
class SearchHit {
  const SearchHit({
    required this.key,
    required this.packageName,
    required this.title,
    required this.text,
    required this.time,
    this.sender,
    this.outgoing = false,
  });

  factory SearchHit.fromMap(Map<Object?, Object?> m) => SearchHit(
    key: m['key']! as String,
    packageName: m['package']! as String,
    title: m['title']! as String,
    text: m['text']! as String,
    time: DateTime.fromMillisecondsSinceEpoch(m['time']! as int),
    sender: m['sender'] as String?,
    outgoing: m['outgoing'] as bool? ?? false,
  );

  final String key;
  final String packageName;
  final String title;
  final String text;
  final DateTime time;
  final String? sender;
  final bool outgoing;
}

/// Bildirim servisinin durumu: izin verildi mi, sistem servisi bağladı mı.
class ListenerStatus {
  const ListenerStatus({
    required this.enabled,
    required this.connected,
    this.xiaomi = false,
  });

  factory ListenerStatus.fromMap(Map<Object?, Object?> m) => ListenerStatus(
    enabled: m['enabled']! as bool,
    connected: m['connected']! as bool,
    xiaomi: m['xiaomi'] as bool? ?? false,
  );

  /// Kullanıcı bildirim erişimini verdi.
  final bool enabled;

  /// Sistem servisi bağladı; yalnızca o zaman mesajlar yakalanır.
  final bool connected;

  /// Xiaomi/Redmi/POCO: otomatik başlatma izni ayrıca gerekir.
  final bool xiaomi;

  ListenerStatus withConnected(bool value) =>
      ListenerStatus(enabled: enabled, connected: value, xiaomi: xiaomi);
}

class Message {
  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.outgoing,
    this.auto = false,
    this.mediaPath,
    this.mediaMime,
    this.mediaKind,
    this.downloadable = false,
    this.read = false,
    this.deleted = false,
    this.starred = false,
    this.mediaDuration,
    this.mediaSize,
    this.sendState,
    this.sendError,
  });

  factory Message.fromMap(Map<Object?, Object?> m) => Message(
    id: m['id']! as String,
    sender: m['sender'] as String?,
    text: m['text']! as String,
    time: DateTime.fromMillisecondsSinceEpoch(m['time']! as int),
    outgoing: m['outgoing']! as bool,
    auto: m['auto'] as bool? ?? false,
    mediaPath: m['mediaPath'] as String?,
    mediaMime: m['mediaMime'] as String?,
    mediaKind: m['mediaKind'] as String?,
    downloadable: m['downloadable'] as bool? ?? false,
    read: m['read'] as bool? ?? false,
    deleted: m['deleted'] as bool? ?? false,
    starred: m['starred'] as bool? ?? false,
    mediaDuration: m['mediaDuration'] as int?,
    mediaSize: m['mediaSize'] as int?,
    sendState: m['sendState'] as String?,
    sendError: m['sendError'] as String?,
  );

  /// Gönderdiğimiz mesajın durumu (Telegram): "pending", "failed" ya da null (gitti).
  final String? sendState;

  /// Gönderilemediyse sebebi.
  final String? sendError;

  bool get pending => sendState == 'pending';
  bool get failed => sendState == 'failed';

  /// Videonun, GIF'in, sesin süresi (saniye; Telegram); bilinmiyorsa null.
  final int? mediaDuration;

  /// Tam boy dosyanın boyutu (bayt; Telegram); bilinmiyorsa null.
  final int? mediaSize;

  /// Uygulamada büyük açılabilen fotoğraf ya da video (galeride kaydırılır).
  bool get viewable =>
      !deleted &&
      mediaKind != 'sticker' &&
      !isVoice &&
      (mediaPath != null ||
          (downloadable && (isVideo || mediaKind == 'photo')));

  final String id;
  final String? sender;
  final String text;
  final DateTime time;
  final bool outgoing;

  /// Bir otomatik yanıt kuralı tarafından gönderildi.
  final bool auto;

  /// Çıkartma, GIF ya da fotoğrafın uygulamadaki kopyası; yoksa null.
  final String? mediaPath;
  final String? mediaMime;

  /// photo, video, animation, sticker; bilinmiyorsa null.
  final String? mediaKind;

  /// Tam boy dosya (fotoğrafın aslı, video) indirilebilir mi (Telegram).
  final bool downloadable;

  /// Giden mesajı karşı taraf gördü (yalnızca Telegram bildirir).
  final bool read;

  /// Gönderen sildi; metin Mesa'da korunur.
  final bool deleted;

  /// Kaydedilenler'de (tüm uygulamalardan yıldızlı mesajlar).
  final bool starred;

  /// Sesli mesaj ya da ses dosyası (Telegram'da uygulamada dinlenir).
  bool get isVoice =>
      mediaKind == 'voice' ||
      mediaKind == 'audio' ||
      text.startsWith('🎤') ||
      text.startsWith('🎵');

  /// Video ya da hareketli GIF mi (oynatılır).
  bool get isVideo =>
      mediaKind == 'video' || mediaKind == 'animation' || text.startsWith('🎥');

  /// Önizlemesi yok ama dosyası indirilip açılabilir (Telegram videosu, sesi).
  bool get openableWithoutPreview => mediaPath == null && downloadable;

  /// Bildirimle görseli gelmeyen medya: yalnızca kaynak uygulamada açılabilir.
  bool get mediaOnlyInSourceApp =>
      mediaPath == null &&
      !downloadable &&
      const ['📷', '🎥', '🎤', '📄', '⏺'].any(text.startsWith);

  /// Metin, görselin yerine konmuş bir etiketten ibaret mi ("Çıkartma",
  /// "GIF"…). Görsel gösterilirken bu etiket tekrar yazılmaz.
  bool get textIsMediaLabel =>
      {tr('Çıkartma'), 'GIF', tr('📷 Fotoğraf')}.contains(text) ||
      text.endsWith(' Çıkartma');
}

/// Gönderilmek üzere seçilen fotoğraf, video, dosya ya da ses kaydı
/// (uygulamanın gönderim klasöründeki kopyası).
class OutgoingMedia {
  const OutgoingMedia({
    required this.path,
    required this.mime,
    required this.kind,
    required this.name,
    this.size = 0,
    this.duration = 0,
  });

  factory OutgoingMedia.fromMap(Map<Object?, Object?> m) => OutgoingMedia(
    path: m['path']! as String,
    mime: m['mime'] as String? ?? 'application/octet-stream',
    kind: m['kind'] as String? ?? 'file',
    name: m['name'] as String? ?? '',
    size: (m['size'] as num?)?.toInt() ?? 0,
    duration: (m['duration'] as num?)?.toInt() ?? 0,
  );

  final String path;
  final String mime;

  /// photo, video, voice, file
  final String kind;
  final String name;
  final int size;

  /// Saniye (video, ses).
  final int duration;

  Map<String, Object?> toMap() => {
    'path': path,
    'mime': mime,
    'kind': kind,
    'name': name,
    'duration': duration,
  };
}

/// Sohbete nasıl gönderilir (android/.../Hub.kt replyMode).
enum ReplyMode {
  /// Doğrudan: Telegram ya da bildirimin yanıt yolu.
  direct,

  /// Kaynak uygulamada sohbet hazır açılır, kullanıcı orada gönderir.
  app,

  /// Web servisinin sayfasından.
  web,
  none;

  static ReplyMode parse(String? value) =>
      ReplyMode.values.firstWhere((m) => m.name == value, orElse: () => none);
}

/// "Yazıyor…" ve çevrimiçi bilgisi (yalnızca Telegram).
class PresenceState {
  const PresenceState({
    required this.key,
    this.typing,
    this.online,
    this.lastSeen,
  });

  factory PresenceState.fromMap(Map<Object?, Object?> m) => PresenceState(
    key: m['key']! as String,
    typing: m['typing'] as String?,
    online: m['online'] as bool?,
    lastSeen: (m['lastSeen'] as num?) == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((m['lastSeen']! as num).toInt()),
  );

  final String key;
  final String? typing;
  final bool? online;
  final DateTime? lastSeen;
}

/// Mesajların eksiksiz gelmesi için gereken telefon ayarları.
class SystemHealth {
  const SystemHealth({
    required this.listenerEnabled,
    required this.listenerConnected,
    required this.notificationsAllowed,
    required this.batteryUnrestricted,
    required this.micAllowed,
    required this.xiaomi,
  });

  factory SystemHealth.fromMap(Map<Object?, Object?> m) => SystemHealth(
    listenerEnabled: m['listenerEnabled'] as bool? ?? false,
    listenerConnected: m['listenerConnected'] as bool? ?? false,
    notificationsAllowed: m['notificationsAllowed'] as bool? ?? false,
    batteryUnrestricted: m['batteryUnrestricted'] as bool? ?? false,
    micAllowed: m['micAllowed'] as bool? ?? false,
    xiaomi: m['xiaomi'] as bool? ?? false,
  );

  final bool listenerEnabled;
  final bool listenerConnected;
  final bool notificationsAllowed;
  final bool batteryUnrestricted;
  final bool micAllowed;
  final bool xiaomi;

  bool get listenerOk => listenerEnabled && listenerConnected;

  /// Mesaj akışını etkileyen eksikler (mikrofon yalnızca sesli mesaj için).
  int get problems => [
    listenerOk,
    notificationsAllowed,
    batteryUnrestricted,
  ].where((ok) => !ok).length;
}

/// Size yazıp yanıt bekleyen kişi (Sohbetler'in üstündeki şerit).
class WaitingPerson {
  const WaitingPerson({
    required this.key,
    required this.title,
    required this.packageName,
    required this.lastTime,
    required this.lastText,
    this.avatarPath,
  });

  factory WaitingPerson.fromMap(Map<Object?, Object?> m) => WaitingPerson(
    key: m['key']! as String,
    title: m['title']! as String,
    packageName: m['package']! as String,
    lastTime: DateTime.fromMillisecondsSinceEpoch(m['lastTime']! as int),
    lastText: m['lastText'] as String? ?? '',
    avatarPath: m['avatarPath'] as String?,
  );

  final String key;
  final String title;
  final String packageName;
  final DateTime lastTime;
  final String lastText;
  final String? avatarPath;
}

/// Kaydedilenler'deki mesaj.
class StarredMessage {
  const StarredMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.outgoing,
    required this.key,
    required this.title,
    required this.packageName,
    this.sender,
    this.mediaPath,
  });

  factory StarredMessage.fromMap(Map<Object?, Object?> m) => StarredMessage(
    id: m['id']! as String,
    sender: m['sender'] as String?,
    text: m['text']! as String,
    time: DateTime.fromMillisecondsSinceEpoch(m['time']! as int),
    outgoing: m['outgoing'] as bool? ?? false,
    key: m['key']! as String,
    title: m['title']! as String,
    packageName: m['package']! as String,
    mediaPath: m['mediaPath'] as String?,
  );

  final String id;
  final String? sender;
  final String text;
  final DateTime time;
  final bool outgoing;
  final String key;
  final String title;
  final String packageName;
  final String? mediaPath;
}

/// Ertelenmiş ("sonra hatırlat") sohbet.
class SnoozedConversation {
  const SnoozedConversation({
    required this.key,
    required this.title,
    required this.packageName,
    required this.until,
  });

  factory SnoozedConversation.fromMap(Map<Object?, Object?> m) =>
      SnoozedConversation(
        key: m['key']! as String,
        title: m['title']! as String,
        packageName: m['package']! as String,
        until: DateTime.fromMillisecondsSinceEpoch(m['until']! as int),
      );

  final String key;
  final String title;
  final String packageName;
  final DateTime until;
}

/// Planlı mesaj.
class ScheduledMessage {
  const ScheduledMessage({
    required this.id,
    required this.key,
    required this.text,
    required this.at,
    this.title,
    this.packageName,
  });

  factory ScheduledMessage.fromMap(Map<Object?, Object?> m) => ScheduledMessage(
    id: (m['id']! as num).toInt(),
    key: m['key']! as String,
    text: m['text']! as String,
    at: DateTime.fromMillisecondsSinceEpoch(m['at']! as int),
    title: m['title'] as String?,
    packageName: m['package'] as String?,
  );

  final int id;
  final String key;
  final String text;
  final DateTime at;
  final String? title;
  final String? packageName;
}

/// Haftalık özet.
class WeeklyStats {
  const WeeklyStats({
    required this.perDay,
    required this.perApp,
    required this.top,
    required this.incoming,
    required this.outgoing,
    required this.people,
    required this.deleted,
    this.busiestHour,
  });

  factory WeeklyStats.fromMap(Map<Object?, Object?> m) {
    List<Map<Object?, Object?>> list(String k) =>
        (m[k] as List<Object?>? ?? const []).cast<Map<Object?, Object?>>();
    return WeeklyStats(
      perDay: {
        for (final d in list('perDay'))
          d['day']! as String: (d['count']! as num).toInt(),
      },
      perApp: [
        for (final a in list('perApp'))
          (a['package']! as String, (a['count']! as num).toInt()),
      ],
      top: [
        for (final t in list('top'))
          (
            key: t['key']! as String,
            title: t['title']! as String,
            packageName: t['package']! as String,
            avatarPath: t['avatarPath'] as String?,
            isGroup: t['isGroup'] as bool? ?? false,
            count: (t['count']! as num).toInt(),
          ),
      ],
      incoming: (m['incoming'] as num?)?.toInt() ?? 0,
      outgoing: (m['outgoing'] as num?)?.toInt() ?? 0,
      people: (m['people'] as num?)?.toInt() ?? 0,
      deleted: (m['deleted'] as num?)?.toInt() ?? 0,
      busiestHour: (m['busiestHour'] as num?)?.toInt(),
    );
  }

  /// "2026-10-11" → mesaj sayısı.
  final Map<String, int> perDay;

  /// (paket, mesaj sayısı), çoktan aza.
  final List<(String, int)> perApp;

  final List<
    ({
      String key,
      String title,
      String packageName,
      String? avatarPath,
      bool isGroup,
      int count,
    })
  >
  top;
  final int incoming;
  final int outgoing;

  /// Yazıştığınız kişi sayısı (gruplar hariç).
  final int people;

  /// Gönderenin sildiği ama sizde kalan mesajlar.
  final int deleted;
  final int? busiestHour;

  int get total => incoming + outgoing;
}
