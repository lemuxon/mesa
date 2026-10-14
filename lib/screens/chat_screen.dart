import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../ui/bidi.dart';
import '../l10n/stored_labels.dart';
import '../core/app_scope.dart';
import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/presence.dart';
import '../core/settings.dart';
import '../core/telegram.dart';
import '../ui/avatars.dart';
import '../ui/text_dialog.dart';
import '../ui/theme.dart';
import 'engagement.dart';
import 'media_gallery_screen.dart';
import 'media_viewer.dart';
import 'setup_checklist.dart';
import 'telegram_picker_sheet.dart';

/// Tek sohbetin (ya da bir kişinin tüm sohbetlerinin) mesajları; yazı,
/// fotoğraf, video, dosya ve sesli mesaj gönderme. Telegram'a doğrudan,
/// diğer uygulamalara bildirimin yanıt yoluyla ya da sohbet o uygulamada
/// hazır açılarak gönderilir.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.bridge,
    required this.conversation,
    this.members = const [],
  });

  final CoreBridge bridge;

  /// Açılan sohbet; kişi ekranında yanıtın varsayılan uygulaması.
  final Conversation conversation;

  /// Kişi ekranı: aynı kişinin farklı uygulamalardaki sohbetleri (en az iki).
  /// Mesajlar tek zaman çizgisinde birleşir; yanıt seçilen uygulamadan gider.
  final List<Conversation> members;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  List<Message> _messages = const [];

  /// Yanıtın gideceği sohbet (kişi ekranında üstteki şeritten seçilir).
  late Conversation _active = widget.conversation;
  late ReplyMode _mode = _initialMode(_active);
  bool _sending = false;
  bool _showEmoji = false;
  StreamSubscription<String>? _changes;

  /// Ses kaydı sürüyor (başlangıç anı).
  DateTime? _recordingSince;
  Timer? _recordingTicker;

  /// Mikrofona basılı tutularak kaydediliyor (bırakınca gönderilir).
  bool _holdRecording = false;
  Future<void>? _recordingStarting;

  /// Telegram'a en son "yazıyor" bildirildiği an.
  DateTime _typingSent = DateTime(0);

  /// Bu sohbetin planlı mesajları.
  List<ScheduledMessage> _scheduled = const [];

  /// Telegram'da gizli okuma açık ("görüldü" gönderilmez).
  bool _telegramGhost = false;

  /// Ayarlar (birleşik bildirim, kendi bildirimi kalanlar): öneri bandı için.
  AppSettings? _settings;

  String get _key => _active.key;

  bool get _isPerson => widget.members.length > 1;

  List<Conversation> get _members =>
      _isPerson ? widget.members : [widget.conversation];

  late final Set<String> _memberKeys = {for (final m in _members) m.key};

  /// Kişi ekranında: mesaj kimliği → geldiği uygulama (balonda gösterilir).
  Map<String, String> _sourceOf = const {};

  String get _title => _isPerson
      ? (widget.conversation.personName ?? widget.conversation.title)
      : widget.conversation.title;

  static ReplyMode _initialMode(Conversation c) =>
      MessagingApp.isWeb(c.packageName)
      ? ReplyMode.web
      : c.canReply
      ? ReplyMode.direct
      : ReplyMode.app;

  /// Bu sohbet (kişi ekranında kişinin tüm sohbetleri) açıkken bildirimi
  /// gösterilmez.
  void _setActive(bool active) {
    if (_isPerson) {
      widget.bridge.setActiveConversations(
        active ? _memberKeys.toList() : const [],
      );
    } else {
      widget.bridge.setActiveConversation(active ? _key : null);
    }
  }

  /// Gönderince kaynak uygulama açılıyor (yanıt yolu yok) ama "kendi
  /// bildirimi de kalsın" kapalı: tek dokunuşla açılması önerilir.
  bool _showKeepNudge(MessagingApp app) {
    final settings = _settings;
    final prefs = AppScope.maybeOf(context)?.prefs;
    final package = _active.packageName;
    return settings != null &&
        prefs != null &&
        _mode == ReplyMode.app &&
        !_telegram &&
        !MessagingApp.isWeb(package) &&
        settings.unifiedNotifications &&
        !settings.keepSourcePackages.contains(package) &&
        !prefs.keepNudgeDismissed.contains(package);
  }

  Future<void> _enableKeepSource() async {
    await keepSourceFor(widget.bridge, _active.packageName);
    final settings = await widget.bridge.settings();
    if (!mounted) return;
    setState(() => _settings = settings);
    _snack(
      tr(
        'Açıldı. Bu sohbetten yeni mesaj gelince yanıtlarınız {appName} açılmadan, doğrudan gider.',
        {'appName': _appName},
      ),
      long: true,
    );
  }

  /// Kişi ekranında yanıtın gideceği uygulamayı değiştirir.
  void _select(Conversation member) {
    if (member.key == _active.key) return;
    setState(() {
      _active = member;
      _mode = _initialMode(member);
      _shareKinds = null;
    });
    _load();
    _loadShareKinds();
  }

  bool get _telegram => isTelegramKey(_key);

  /// Fotoğraf, video, ses gönderilebilir mi (web servislerinde sayfadan).
  bool get _canAttach => _mode == ReplyMode.direct || _mode == ReplyMode.app;

  /// Kaynak uygulamanın paylaşımla kabul ettiği türler (photo, video, voice,
  /// file); null: bilinmiyor ya da Telegram (hepsi gider).
  Set<String>? _shareKinds;

  bool _accepts(String kind) =>
      _telegram || (_shareKinds?.contains(kind) ?? true);

  /// Instagram gibi ses ya da belge almayan uygulamada o düğmeler gizlenir.
  Future<void> _loadShareKinds() async {
    final package = _active.packageName;
    if (_telegram || MessagingApp.isWeb(package)) return;
    try {
      final kinds = await widget.bridge.shareKinds(package);
      if (mounted && _active.packageName == package) {
        setState(() => _shareKinds = kinds);
      }
    } catch (_) {
      // Eski yerel taraf ya da test: hepsi gösterilir.
    }
  }

  @override
  void initState() {
    super.initState();
    _changes = widget.bridge.changes.where(_memberKeys.contains).listen((_) {
      _load();
    });
    _input.addListener(_onInputChanged);
    WidgetsBinding.instance.addObserver(this);
    _load();
    _loadShareKinds();
    _setActive(true);
    // Telegram sohbetlerinde son mesajlar sunucudan indirilir; gelince
    // değişiklik olayı listeyi yeniler.
    for (final key in _memberKeys) {
      if (isTelegramKey(key)) widget.bridge.telegramLoadHistory(key);
    }
    widget.bridge
        .settings()
        .then((s) {
          if (mounted) {
            setState(() {
              _telegramGhost = s.telegramGhostRead;
              _settings = s;
            });
          }
        })
        .catchError((_) {});
  }

  /// Burada okumak karşı tarafa "görüldü" göndermiyor mu.
  bool get _readsSilently =>
      _telegram ? _telegramGhost : _mode != ReplyMode.web;

  /// Uygulama arka plandayken sohbet "açık" sayılmaz: yeni mesajlar bildirim
  /// gösterir ve okunmamış kalır. Ön plana dönünce yeniden açık sayılır.
  bool _foreground = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _setActive(foreground);
    if (foreground) {
      _load();
      _confirmHandoff();
    }
  }

  /// Kaynak uygulamada gönderilmek üzere açılan son mesaj: (sohbet, kayıt).
  (String, String)? _handoff;

  /// Kullanıcı mesajı kaynak uygulamada gönderecek: sohbet geçmişi eksik
  /// kalmasın diye buraya da yazılır. Gönderilmediyse dönüşte geri alınır.
  Future<void> _recordHandoff(String text) async {
    final key = _active.key;
    try {
      final id = await widget.bridge.recordSentViaApp(key, text);
      if (id != null) _handoff = (key, id);
    } catch (_) {
      // Eski yerel taraf ya da test: kaydedilmez.
    }
  }

  void _confirmHandoff() {
    final handoff = _handoff;
    if (handoff == null || !mounted) return;
    _handoff = null;
    final (key, id) = handoff;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(tr('Mesajınız bu sohbete de kaydedildi.')),
          action: SnackBarAction(
            label: tr('Gönderilmedi'),
            onPressed: () => widget.bridge.deleteMessage(key, id),
          ),
        ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setActive(false);
    _changes?.cancel();
    _recordingTicker?.cancel();
    if (_recordingSince != null) widget.bridge.stopRecording(cancel: true);
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
    // Telegram'da karşı taraf "yazıyor…" görsün (en fazla 4 sn'de bir).
    if (_telegram && _input.text.isNotEmpty) {
      final now = DateTime.now();
      if (now.difference(_typingSent) > const Duration(seconds: 4)) {
        _typingSent = now;
        widget.bridge.telegramTyping(_key).catchError((_) {});
      }
    }
  }

  Future<void> _load() async {
    var messages = <Message>[];
    var sources = const <String, String>{};
    if (_isPerson) {
      // Kişinin tüm sohbetleri tek zaman çizgisinde.
      final lists = await Future.wait(
        _members.map((m) => widget.bridge.messages(m.key)),
      );
      final sourceOf = <String, String>{};
      for (final (i, list) in lists.indexed) {
        for (final m in list) {
          messages.add(m);
          sourceOf[m.id] = _members[i].packageName;
        }
      }
      messages.sort((a, b) => a.time.compareTo(b.time));
      sources = sourceOf;
    } else {
      messages = await widget.bridge.messages(_key);
    }
    final active = _active;
    var mode = _mode;
    try {
      mode = await widget.bridge.replyMode(active);
    } catch (_) {
      // Eski yerel taraf ya da test: yalnızca doğrudan yanıt bilinir.
      mode = await widget.bridge.canReply(active.key) ? ReplyMode.direct : mode;
    }
    var scheduled = _scheduled;
    try {
      scheduled = [
        for (final key in _memberKeys)
          ...await widget.bridge.scheduledMessages(key: key),
      ]..sort((a, b) => a.at.compareTo(b.at));
    } catch (_) {
      // Eski yerel taraf ya da test.
    }
    // Arka plandayken gelen mesaj okunmuş sayılmasın.
    if (_foreground) {
      for (final key in _memberKeys) {
        await widget.bridge.markRead(key);
      }
    }
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _sourceOf = sources;
      // Bu sırada başka uygulama seçildiyse onun kipi ayrıca yüklenir.
      if (identical(active, _active)) _mode = mode;
      _scheduled = scheduled;
    });
  }

  /// Mesaja basılı tutunca: kaydet / kaydedilenlerden çıkar, kopyala.
  Future<void> _messageActions(Message m) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.failed) ...[
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(tr('Tekrar gönder')),
                subtitle: Text(m.sendError ?? tr('Mesaj gönderilemedi')),
                onTap: () => Navigator.of(context).pop('resend'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(tr('Sil')),
                subtitle: Text(tr('Karşı tarafa hiç gitmedi')),
                onTap: () => Navigator.of(context).pop('deleteFailed'),
              ),
              const Divider(height: 8),
            ],
            ListTile(
              leading: Icon(
                m.starred
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
              ),
              title: Text(
                m.starred ? tr('Kaydedilenlerden çıkar') : tr('Kaydet'),
              ),
              subtitle: m.starred
                  ? null
                  : Text(tr('Tüm uygulamalardan kaydedilenler tek listede')),
              onTap: () => Navigator.of(context).pop('star'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(tr('Kopyala')),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
          ],
        ),
      ),
    );
    switch (choice) {
      case 'star':
        await widget.bridge.starMessage(m.id, !m.starred);
        _snack(
          m.starred ? tr('Kaydedilenlerden çıkarıldı.') : tr('Kaydedildi ⭐'),
        );
        await _load();
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.text));
        _snack(tr('Kopyalandı.'));
      case 'resend':
        final ok = await widget.bridge.telegramResend(m.id);
        _snack(
          ok
              ? tr('Yeniden gönderiliyor…')
              : tr('Gönderilemedi. Bağlantıyı kontrol edin.'),
        );
        await _load();
      case 'deleteFailed':
        await widget.bridge.telegramDeleteFailed(m.id);
        await _load();
    }
  }

  /// Gönder düğmesine basılı tutunca: mesajı ileri bir zamana planlar.
  Future<void> _schedule() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final at = await pickLaterTime(context, title: tr('Ne zaman gönderilsin?'));
    if (at == null) return;
    await widget.bridge.scheduleMessage(_key, text, at);
    _input.clear();
    final when = formatWhen(at, DateTime.now());
    if (_telegram) {
      _snack(tr('⏰ {when} Telegram\'dan gönderilecek.', {'when': when}));
    } else if (_mode == ReplyMode.direct) {
      _snack(tr('⏰ {when} kendiliğinden gönderilecek.', {'when': when}));
    } else {
      _snack(
        tr(
          '⏰ {when} bildirim gelecek: dokununca {appName} mesaj yazılmış olarak açılır, ➤ ile gönderirsiniz. {viaAppNote}',
          {'when': when, 'appName': _appName, 'viaAppNote': _viaAppNote},
        ),
        long: true,
      );
    }
    await _load();
  }

  /// Bildirimin yanıt yolu yokken planlı mesajın nasıl gideceği.
  static String get _viaAppNote =>
      tr('O zamana kadar bu sohbetten yeni mesaj gelirse kendiliğinden gider.');

  Future<void> _showScheduled() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tr('Planlı mesajlar'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final m in _scheduled)
              ListTile(
                leading: const Icon(Icons.schedule_send_rounded),
                title: Text(
                  localizeStored(m.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatWhen(m.at, DateTime.now())),
                trailing: IconButton(
                  onPressed: () async {
                    await widget.bridge.cancelScheduled(m.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: tr('İptal et'),
                ),
              ),
            if (!_telegram && _mode != ReplyMode.direct)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Text(
                  tr(
                    '{appName} bu sohbet için şu an doğrudan gönderme yolu vermiyor: zamanı gelince bildirime dokunup {appName} içinde gönderirsiniz. {viaAppNote}',
                    {'appName': _appName, 'viaAppNote': _viaAppNote},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
    await _load();
  }

  void _snack(String text, {bool long = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: Duration(seconds: long ? 8 : 4),
        ),
      );
  }

  String get _appName => MessagingApp.of(_active.packageName).name;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      if (_mode == ReplyMode.direct) {
        try {
          await widget.bridge.sendReply(_key, text);
          _input.clear();
          return;
        } on NoReplyActionException {
          // Yanıt yolu kapandı (bildirim gitti): uygulamada hazır açılır.
          if (mounted) setState(() => _mode = ReplyMode.app);
          if (_telegram) {
            _snack(tr('Telegram bağlantısı açık değil.'));
            return;
          }
        }
      }
      if (_mode == ReplyMode.app) {
        if (await widget.bridge.sendViaApp(_active, text)) {
          _input.clear();
          await _recordHandoff(text);
        } else {
          _snack(tr('{appName} açılamadı.', {'appName': _appName}));
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMedia(List<OutgoingMedia> items, {String? caption}) async {
    final result = await widget.bridge.sendMedia(
      _active,
      items,
      caption: caption,
    );
    switch (result) {
      case 'sent':
        _snack(
          items.length > 1
              ? tr('Gönderiliyor…')
              : tr('{kind} gönderiliyor…', {'kind': _kindLabel(items.first)}),
        );
      case 'shared':
        _snack(
          tr('{appName} açıldı; göndermek için orada ➤ düğmesine dokunun.', {
            'appName': _appName,
          }),
        );
      case 'unsupported':
        _snack(
          tr('{appName} dışarıdan {kind} kabul etmiyor.', {
            'appName': _appName,
            'kind': _kindLabel(items.first).toLowerCase(),
          }),
        );
      default:
        _snack(tr('Gönderilemedi.'));
    }
  }

  static String _kindLabel(OutgoingMedia m) => switch (m.kind) {
    'photo' => tr('Fotoğraf'),
    'video' => tr('Video'),
    'voice' => tr('Sesli mesaj'),
    _ => tr('Dosya'),
  };

  Future<void> _attach() async {
    _inputFocus.unfocus();
    setState(() => _showEmoji = false);
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _AttachSheet(
        media: _accepts('photo') || _accepts('video'),
        camera: _accepts('photo'),
        files: _accepts('file'),
      ),
    );
    if (source == null || !mounted) return;
    if (source == 'schedule') {
      await _scheduleWithPrompt();
      return;
    }
    await _pickAndSend(source);
  }

  /// Yazma alanı boşsa önce planlanacak mesaj istenir.
  Future<void> _scheduleWithPrompt() async {
    if (_input.text.trim().isEmpty) {
      final text = await showTextDialog(
        context,
        title: tr('Planlı mesaj'),
        confirmLabel: tr('Zaman seç'),
        hint: tr('Gönderilecek mesaj'),
        maxLines: 5,
      );
      if (text == null || text.trim().isEmpty || !mounted) return;
      _input.text = text.trim();
    }
    await _schedule();
  }

  Future<void> _pickAndSend(String source) async {
    final items = await widget.bridge.pickMedia(source);
    if (items.isEmpty || !mounted) return;
    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SendPreviewSheet(
        items: items,
        appName: _appName,
        direct: _telegram && _mode == ReplyMode.direct,
      ),
    );
    if (caption == null) return;
    await _sendMedia(items, caption: caption);
  }

  // ---- Sesli mesaj ----

  Future<void> _startRecording({bool hold = false}) async {
    if (_recordingSince != null) {
      // Basılı tutma algılanamadıysa (izin penceresi vb.) mikrofona dokunmak bitirir.
      if (_holdRecording) await _stopRecording(send: true);
      return;
    }
    _holdRecording = hold;
    if (!await widget.bridge.micPermission()) {
      _snack(tr('Sesli mesaj için mikrofon izni gerekli.'));
      return;
    }
    if (!await widget.bridge.startRecording()) {
      _snack(tr('Kayıt başlatılamadı.'));
      return;
    }
    HapticFeedback.mediumImpact();
    if (_telegram) widget.bridge.telegramTyping(_key).catchError((_) {});
    setState(() => _recordingSince = DateTime.now());
    _recordingTicker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
  }

  /// Basılı tutma bitti: kayıt henüz başlıyorsa önce başlaması beklenir.
  Future<void> _endHold({required bool send}) async {
    await _recordingStarting;
    if (_recordingSince != null && _holdRecording) {
      await _stopRecording(send: send);
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    if (_recordingSince == null) return;
    _holdRecording = false;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    setState(() => _recordingSince = null);
    final voice = await widget.bridge.stopRecording(cancel: !send);
    if (!send) return;
    if (voice == null) {
      _snack(tr('Kayıt çok kısa.'));
      return;
    }
    await _sendMedia([voice]);
  }

  Future<void> _openInApp() async {
    final opened = await widget.bridge.openInSourceApp(_active);
    if (!opened) _snack(tr('Uygulama açılamadı.'));
  }

  /// Mesajın geldiği sohbet (kişi ekranında o uygulamanınki).
  Conversation _memberOf(Message m) {
    final source = _sourceOf[m.id];
    if (source == null) return _active;
    return _members.firstWhere(
      (c) => c.packageName == source,
      orElse: () => _active,
    );
  }

  void _openMedia(Message message) {
    if (message.mediaOnlyInSourceApp) {
      _openInApp();
      return;
    }
    // Sohbetteki diğer fotoğraf ve videolara sağa-sola kaydırılır.
    final gallery = _messages.where((m) => m.viewable).toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaViewer(
          bridge: widget.bridge,
          message: message,
          gallery: gallery.any((m) => m.id == message.id) ? gallery : const [],
          titleOf: (m) => m.outgoing ? tr('Siz') : (m.sender ?? _title),
          sourceAppOf: (m) {
            final member = _memberOf(m);
            return isTelegramKey(member.key)
                ? null
                : MessagingApp.of(member.packageName).name;
          },
          onOpenInApp: (m) => widget.bridge.openInSourceApp(_memberOf(m)),
        ),
      ),
    );
  }

  Future<void> _pickQuickReply(List<String> replies) async {
    final reply = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                tr('Hazır yanıtlar'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final reply in replies)
              ListTile(
                leading: const Icon(Icons.bolt_rounded),
                title: Text(reply),
                onTap: () => Navigator.of(context).pop(reply),
              ),
          ],
        ),
      ),
    );
    if (reply == null || !mounted) return;
    _input.value = TextEditingValue(
      text: reply,
      selection: TextSelection.collapsed(offset: reply.length),
    );
    _inputFocus.requestFocus();
  }

  Future<void> _openTelegramPicker() async {
    _inputFocus.unfocus();
    setState(() => _showEmoji = false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          TelegramPickerSheet(bridge: widget.bridge, conversationKey: _key),
    );
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _inputFocus.requestFocus();
    } else {
      _inputFocus.unfocus();
      setState(() => _showEmoji = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = MessagingApp.of(_active.packageName);
    final theme = Theme.of(context);
    // Emoji paneli açıkken geri tuşu önce paneli kapatır.
    return PopScope(
      canPop: !_showEmoji,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showEmoji = false);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          shape: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          title: Row(
            children: [
              ConversationAvatar(
                title: _title,
                packageName: _active.packageName,
                avatarPath: _members
                    .map((m) => m.avatarPath)
                    .whereType<String>()
                    .firstOrNull,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    _PresenceLine(conversationKey: _key, appName: app.name),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (_readsSilently)
              IconButton(
                onPressed: () => _snack(
                  _telegram
                      ? tr(
                          'Gizli okuma açık: Telegram\'da "görüldü" ve "yazıyor" gitmez.',
                        )
                      : tr(
                          'Burada okumak {name}\'ta "görüldü" göndermez. Yanıt verirseniz gider.',
                          {'name': app.name},
                        ),
                ),
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: tr('Görüldü gönderilmez'),
              ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MediaGalleryScreen(
                    bridge: widget.bridge,
                    title: _title,
                    members: _members,
                  ),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: tr('Medya'),
            ),
            IconButton(
              onPressed: _openInApp,
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: tr('{name} uygulamasında aç', {'name': app.name}),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isPerson)
              _PersonSwitcher(
                members: _members,
                active: _active,
                onSelect: _select,
              ),
            if (_readsSilently &&
                !_telegram &&
                !(AppScope.maybeOf(context)?.prefs.ghostHintSeen ?? true))
              _GhostHint(
                appName: app.name,
                onDismiss: () async {
                  await AppScope.maybeOf(context)?.prefs.dismissGhostHint();
                  if (mounted) setState(() {});
                },
              ),
            Expanded(
              child: Stack(
                children: [
                  // Duvar kâğıdı kaydırmada yeniden çizilmesin.
                  const Positioned.fill(
                    child: RepaintBoundary(child: _Wallpaper()),
                  ),
                  _messageList(app),
                ],
              ),
            ),
            if (_showKeepNudge(app))
              _KeepNudge(
                appName: app.name,
                onEnable: _enableKeepSource,
                onDismiss: () async {
                  await AppScope.maybeOf(
                    context,
                  )?.prefs.dismissKeepNudge(_active.packageName);
                  if (mounted) setState(() {});
                },
              ),
            switch (_mode) {
              ReplyMode.direct || ReplyMode.app => _composer(app),
              _ => _noReplyNotice(app),
            },
          ],
        ),
      ),
    );
  }

  Widget _messageList(MessagingApp app) {
    return ValueListenableBuilder<Map<String, PresenceState>>(
      valueListenable: PresenceHub.instance,
      builder: (context, presence, _) {
        final typing = _members
            .map((m) => presence[m.key]?.typing)
            .whereType<String>()
            .firstOrNull;
        if (_messages.isEmpty && typing == null) {
          return Center(
            child: Text(
              tr('Bu sohbette henüz mesaj yok.'),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          );
        }
        final now = DateTime.now();
        final extra = typing == null ? 0 : 1;
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          itemCount: _messages.length + extra,
          itemBuilder: (context, i) {
            if (extra == 1 && i == 0) return _TypingBubble(text: typing!);
            // Liste ters: i = 0 en yeni mesaj.
            final index = _messages.length - 1 - (i - extra);
            final m = _messages[index];
            final previous = index > 0 ? _messages[index - 1] : null;
            final next = index < _messages.length - 1
                ? _messages[index + 1]
                : null;
            final newDay =
                previous == null || !isSameDay(previous.time, m.time);
            final groupStart =
                newDay ||
                previous.outgoing != m.outgoing ||
                previous.sender != m.sender;
            final groupEnd =
                next == null ||
                !isSameDay(next.time, m.time) ||
                next.outgoing != m.outgoing ||
                next.sender != m.sender;
            return Column(
              children: [
                if (newDay) _DayChip(label: formatDayLabel(m.time, now)),
                _Bubble(
                  key: ValueKey(m.id),
                  message: m,
                  bridge: widget.bridge,
                  showSender:
                      _active.isGroup &&
                      !_isPerson &&
                      groupStart &&
                      !m.outgoing,
                  groupStart: groupStart,
                  groupEnd: groupEnd,
                  appName: app.name,
                  // Okundu bilgisini yalnızca Telegram verir.
                  showTicks: _isPerson ? m.id.startsWith('tg-') : _telegram,
                  sourcePackage: _isPerson ? _sourceOf[m.id] : null,
                  onOpenMedia: () => _openMedia(m),
                  onLongPress: () => _messageActions(m),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _composer(MessagingApp app) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final replies = AppScope.maybeOf(context)?.prefs.quickReplies;
    final hasText = _input.text.trim().isNotEmpty;
    final recording = _recordingSince;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_scheduled.isNotEmpty && recording == null)
              InkWell(
                onTap: _showScheduled,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_send_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('{count} planlı mesaj · ilki {when}', {
                            'count': _scheduled.length,
                            'when': formatWhen(
                              _scheduled.first.at,
                              DateTime.now(),
                            ),
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            if (_mode == ReplyMode.app && recording == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(
                          'Mesajınız {name}\'ta hazır açılır; orada ➤ ile gönderin.',
                          {'name': app.name},
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              // Kayıt sırasında da satır aynı kalır: basılı tutulan mikrofon
              // düğmesi yerinden çıkarsa parmağın kalktığı algılanamaz.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: recording != null
                        ? _RecordingStatus(
                            since: recording,
                            hold: _holdRecording,
                            onCancel: () => _stopRecording(send: false),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: _toggleEmoji,
                                  icon: Icon(
                                    _showEmoji
                                        ? Icons.keyboard_outlined
                                        : Icons.emoji_emotions_outlined,
                                  ),
                                  tooltip: _showEmoji
                                      ? tr('Klavye')
                                      : tr('Emoji'),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _input,
                                    focusNode: _inputFocus,
                                    onTap: () {
                                      if (_showEmoji) {
                                        setState(() => _showEmoji = false);
                                      }
                                    },
                                    minLines: 1,
                                    maxLines: 5,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                      hintText: _isPerson
                                          ? tr('{appName} ile yaz', {
                                              'appName': _appName,
                                            })
                                          : tr('Mesaj yaz'),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (replies != null &&
                                    replies.isNotEmpty &&
                                    !hasText)
                                  IconButton(
                                    onPressed: () => _pickQuickReply(replies),
                                    icon: const Icon(Icons.bolt_outlined),
                                    tooltip: tr('Hazır yanıtlar'),
                                  ),
                                if (_telegram && !hasText)
                                  IconButton(
                                    onPressed: _openTelegramPicker,
                                    icon: const Icon(Icons.gif_box_outlined),
                                    tooltip: tr('Çıkartma ve GIF'),
                                  ),
                                if (_canAttach)
                                  IconButton(
                                    onPressed: _attach,
                                    icon: const Icon(Icons.attach_file_rounded),
                                    tooltip: tr('Fotoğraf, video, dosya'),
                                  ),
                                // Planlı mesaj: yazmaya başlayınca görünür.
                                if (hasText && _canAttach)
                                  IconButton(
                                    onPressed: _sending ? null : _schedule,
                                    icon: const Icon(
                                      Icons.schedule_send_outlined,
                                    ),
                                    tooltip: tr('Zamanla'),
                                  ),
                                if (_canAttach && !hasText && _accepts('photo'))
                                  IconButton(
                                    onPressed: () => _pickAndSend('camera'),
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                    ),
                                    tooltip: tr('Kamera'),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 6),
                  if (recording != null && !_holdRecording)
                    _ActionButton(
                      icon: Icons.send_rounded,
                      tooltip: tr('Sesli mesajı gönder'),
                      onPressed: () => _stopRecording(send: true),
                    )
                  else if (hasText || !_canAttach || !_accepts('voice'))
                    _ActionButton(
                      icon: Icons.send_rounded,
                      tooltip: tr('Gönder (basılı tutun: zamanla)'),
                      onPressed: _sending || !hasText ? null : _send,
                      onLongPress: _sending || !hasText ? null : _schedule,
                    )
                  else
                    _MicButton(
                      recording: recording != null,
                      onTap: _startRecording,
                      onHoldStart: () =>
                          _recordingStarting = _startRecording(hold: true),
                      onHoldEnd: () => _endHold(send: true),
                      onHoldCancel: () => _endHold(send: false),
                    ),
                ],
              ),
            ),
            if (_showEmoji)
              EmojiPicker(
                textEditingController: _input,
                config: const Config(height: 280),
              ),
          ],
        ),
      ),
    );
  }

  Widget _noReplyNotice(MessagingApp app) => SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _mode == ReplyMode.web
                ? tr(
                    'Web servislerine yanıt, servisin kendi sayfasından yazılır.',
                  )
                : _telegram
                ? tr('Telegram bağlantısı açık değil.')
                : tr('{name} telefonda kurulu değil.', {'name': app.name}),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: _openInApp,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _mode == ReplyMode.web
                  ? tr('{name} sayfasında yanıtla', {'name': app.name})
                  : tr('{name} uygulamasında aç', {'name': app.name}),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Başlığın altındaki satır: yazıyor > çevrimiçi > son görülme > uygulama adı.
class _PresenceLine extends StatelessWidget {
  const _PresenceLine({required this.conversationKey, required this.appName});

  final String conversationKey;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Map<String, PresenceState>>(
      valueListenable: PresenceHub.instance,
      builder: (context, presence, _) {
        final state = presence[conversationKey];
        final (text, color) = switch (state) {
          PresenceState(typing: final typing?) => (typing, AppTheme.online),
          PresenceState(online: true) => (tr('çevrimiçi'), AppTheme.online),
          PresenceState(lastSeen: final seen?) => (
            tr('son görülme {seen}', {'seen': _lastSeen(seen)}),
            theme.colorScheme.outline,
          ),
          _ => (appName, theme.colorScheme.outline),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            text,
            key: ValueKey(text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: color == AppTheme.online ? FontWeight.w600 : null,
            ),
          ),
        );
      },
    );
  }

  static String _lastSeen(DateTime t) {
    final now = DateTime.now();
    if (isSameDay(t, now)) return tr('bugün {time}', {'time': formatClock(t)});
    if (isSameDay(t, now.subtract(const Duration(days: 1)))) {
      return tr('dün {time}', {'time': formatClock(t)});
    }
    return '${formatDayLabel(t, now)} ${formatClock(t)}';
  }
}

/// Sohbet arka planı: hafif degrade ve seyrek noktalar.
class _Wallpaper extends StatelessWidget {
  const _Wallpaper();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.chatBackground(brightness)),
      child: CustomPaint(
        painter: _DotsPainter(
          (brightness == Brightness.dark ? Colors.white : AppTheme.brand)
              .withValues(alpha: brightness == Brightness.dark ? 0.035 : 0.06),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 26.0;
    for (var y = 0.0, row = 0; y < size.height; y += step, row++) {
      for (var x = row.isEven ? 0.0 : step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled ? AppTheme.brandGradient : null,
            color: enabled
                ? null
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: enabled
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ses kaydı sürerken yazma alanının içi: süre, iptal (basılı tutarken sola kaydırma).
class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus({
    required this.since,
    required this.hold,
    required this.onCancel,
  });

  final DateTime since;
  final bool hold;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(since);
    final label =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            tooltip: tr('Kaydı sil'),
          ),
          // Yanıp sönen kayıt noktası.
          TweenAnimationBuilder<double>(
            key: ValueKey(elapsed.inSeconds),
            tween: Tween(begin: 1, end: 0.3),
            duration: const Duration(milliseconds: 900),
            builder: (_, v, _) => Opacity(
              opacity: v,
              child: const Icon(
                Icons.fiber_manual_record,
                color: Colors.red,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hold ? tr('◀ İptal için kaydırın') : 'Kaydediliyor…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mikrofon: dokununca kayıt başlar (gönder düğmesiyle biter); WhatsApp'taki
/// gibi basılı tutunca kaydeder, bırakınca gönderir, sola kaydırınca iptal eder.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.recording,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onHoldCancel,
  });

  final bool recording;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final VoidCallback onHoldCancel;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _cancelled = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tr('Sesli mesaj: dokunun ya da basılı tutun'),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: (_) {
          _cancelled = false;
          HapticFeedback.mediumImpact();
          widget.onHoldStart();
        },
        onLongPressMoveUpdate: (details) {
          if (!_cancelled && details.offsetFromOrigin.dx < -90) {
            _cancelled = true;
            HapticFeedback.lightImpact();
            widget.onHoldCancel();
          }
        },
        onLongPressEnd: (_) {
          if (!_cancelled) widget.onHoldEnd();
        },
        child: AnimatedScale(
          scale: widget.recording ? 1.25 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.recording
                  ? const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD81B60)],
                    )
                  : AppTheme.brandGradient,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Ek seçimi: galeri, kamera, dosya.
class _AttachSheet extends StatelessWidget {
  const _AttachSheet({
    this.media = true,
    this.camera = true,
    this.files = true,
  });

  /// Kaynak uygulama kabul ediyorsa: galeri, kamera, dosya.
  final bool media;
  final bool camera;
  final bool files;

  @override
  Widget build(BuildContext context) {
    Widget option(String source, IconData icon, String label, Color color) =>
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(source),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(label),
                ],
              ),
            ),
          ),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            if (media)
              option(
                'gallery',
                Icons.photo_library_rounded,
                tr('Galeri'),
                const Color(0xFF7C4DFF),
              ),
            if (camera)
              option(
                'camera',
                Icons.photo_camera_rounded,
                tr('Kamera'),
                const Color(0xFFE91E63),
              ),
            if (files)
              option(
                'file',
                Icons.insert_drive_file_rounded,
                tr('Dosya'),
                const Color(0xFF1E88E5),
              ),
            option(
              'schedule',
              Icons.schedule_send_rounded,
              tr('Zamanla'),
              const Color(0xFFFF8F00),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçilenlerin önizlemesi ve açıklama; Gönder açıklamayı (boş olabilir) döner.
class _SendPreviewSheet extends StatefulWidget {
  const _SendPreviewSheet({
    required this.items,
    required this.appName,
    required this.direct,
  });

  final List<OutgoingMedia> items;
  final String appName;

  /// Telegram'a doğrudan gider; değilse uygulama hazır açılır.
  final bool direct;

  @override
  State<_SendPreviewSheet> createState() => _SendPreviewSheetState();
}

class _SendPreviewSheetState extends State<_SendPreviewSheet> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = widget.items[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 150,
                    child: item.kind == 'photo'
                        ? Image.file(
                            File(item.path),
                            fit: BoxFit.cover,
                            cacheWidth: (150 * dpr).round(),
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHigh,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.kind == 'video'
                                      ? Icons.movie_rounded
                                      : Icons.insert_drive_file_rounded,
                                  size: 40,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caption,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: tr('Açıklama ekle'),
                      helperText: widget.direct
                          ? null
                          : tr('{appName} hazır açılır; orada gönderin', {
                              'appName': widget.appName,
                            }),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.send_rounded,
                  tooltip: tr('Gönder'),
                  onPressed: () => Navigator.of(context).pop(_caption.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Karşı taraf yazıyor: üç zıplayan nokta ve metin.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.text});

  final String text;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.incomingBubble(brightness),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
                  final lift = t < 0.5 ? t * 2 : (1 - t) * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    transform: Matrix4.translationValues(0, -4 * lift, 0),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.online.withValues(alpha: 0.5 + lift / 2),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            const SizedBox(width: 8),
            Text(
              widget.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.online,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.bridge,
    required this.showSender,
    required this.groupStart,
    required this.groupEnd,
    required this.appName,
    required this.showTicks,
    required this.onOpenMedia,
    required this.onLongPress,
    this.sourcePackage,
  });

  final VoidCallback onLongPress;

  /// Kişi ekranında mesajın geldiği (ya da gittiği) uygulama.
  final String? sourcePackage;
  final Message message;
  final CoreBridge bridge;
  final bool showSender;
  final bool groupStart;
  final bool groupEnd;
  final String appName;

  /// Giden mesajda ✓ / ✓✓ (yalnızca Telegram okundu bilgisi verir).
  final bool showTicks;
  final VoidCallback onOpenMedia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final mine = message.outgoing;
    final textColor = mine ? Colors.white : scheme.onSurface;
    const big = Radius.circular(20);
    const small = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: !mine && !groupStart ? small : big,
      bottomLeft: !mine && !groupEnd ? small : big,
      topRight: mine && !groupStart ? small : big,
      bottomRight: mine && !groupEnd ? small : big,
    );
    final sticker = message.mediaKind == 'sticker' && message.mediaPath != null;
    final voice = message.isVoice && message.downloadable;
    final showText =
        !(message.mediaPath != null && message.textIsMediaLabel) &&
        !(voice && message.textIsVoiceLabel);
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.deleted) ...[
          Icon(
            Icons.delete_forever_rounded,
            size: 13,
            color: mine ? textColor.withValues(alpha: 0.8) : scheme.error,
          ),
          const SizedBox(width: 2),
          Text(
            'silindi · ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: mine ? textColor.withValues(alpha: 0.8) : scheme.error,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (sourcePackage case final source?) ...[
          AppIcon(packageName: source, size: 13),
          const SizedBox(width: 4),
        ],
        if (message.starred) ...[
          Icon(
            Icons.bookmark_rounded,
            size: 13,
            color: mine ? textColor.withValues(alpha: 0.85) : AppTheme.brandEnd,
          ),
          const SizedBox(width: 3),
        ],
        Text(
          message.auto
              ? '${formatClock(message.time)} · otomatik'
              : formatClock(message.time),
          style: theme.textTheme.labelSmall?.copyWith(
            color: sticker ? scheme.outline : textColor.withValues(alpha: 0.72),
          ),
        ),
        if (mine && message.failed) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.error_rounded,
            size: 15,
            color: const Color(0xFFFFB4AB),
            semanticLabel: tr('Gönderilemedi'),
          ),
          const SizedBox(width: 2),
          Text(
            tr('Gönderilemedi'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFFFB4AB),
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else if (mine && message.pending) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: textColor.withValues(alpha: 0.72),
            semanticLabel: tr('Gönderiliyor'),
          ),
        ] else if (mine && showTicks) ...[
          const SizedBox(width: 3),
          Icon(
            message.read ? Icons.done_all_rounded : Icons.done_rounded,
            size: 15,
            color: message.read
                ? const Color(0xFF8CF0C8)
                : textColor.withValues(alpha: 0.72),
            semanticLabel: message.read ? tr('Görüldü') : tr('Gönderildi'),
          ),
        ],
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSender && message.sender != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              message.sender!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.senderColor(message.sender!, brightness),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (message.mediaPath != null)
          _MediaPreview(message: message, onTap: onOpenMedia)
        else if (voice)
          _VoiceBubble(message: message, bridge: bridge, color: textColor)
        else if (message.openableWithoutPreview)
          _OpenableMedia(
            message: message,
            color: textColor,
            onTap: onOpenMedia,
          ),
        if (message.mediaOnlyInSourceApp)
          _SourceOnlyMedia(
            message: message,
            appName: appName,
            color: textColor,
            onTap: onOpenMedia,
          )
        else if (showText && !message.openableWithoutPreview)
          Padding(
            padding: EdgeInsets.only(top: message.mediaPath != null ? 6 : 0),
            child: Text(
              localizeStored(message.text),
              textDirection: textDirectionOf(message.text),
              style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
            ),
          ),
        // Telegram'a gönderilen fotoğraf/video/ses yüklenirken yüzdesi.
        if (mine && message.pending)
          _UploadStatus(
            bridge: bridge,
            messageId: message.id,
            color: textColor.withValues(alpha: 0.85),
          ),
        const SizedBox(height: 2),
        // Saat balonun sağ alt köşesinde (IntrinsicWidth sayesinde balon
        // metin kadar geniş kalır, saat sağa yaslanır).
        Align(alignment: Alignment.centerRight, child: meta),
      ],
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: GestureDetector(
          // Gönderilemeyen mesaja dokununca "Tekrar gönder".
          onTap: message.failed ? onLongPress : null,
          onLongPress: onLongPress,
          child: Container(
            margin: EdgeInsets.only(top: groupStart ? 6 : 1.5, bottom: 1.5),
            padding: sticker
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: sticker
                ? null
                : BoxDecoration(
                    gradient: mine ? AppTheme.outgoingBubble(brightness) : null,
                    color: mine ? null : AppTheme.incomingBubble(brightness),
                    borderRadius: radius,
                    boxShadow: mine
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                  ),
            child: IntrinsicWidth(child: content),
          ),
        ),
      ),
    );
  }
}

/// Sohbetin üstünde bir kez: burada okumak "görüldü" göndermez.
class _GhostHint extends StatelessWidget {
  const _GhostHint({required this.appName, required this.onDismiss});

  final String appName;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off_rounded,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(
                  'Burada okumak {appName}\'ta "görüldü" göndermez. Yanıt verirseniz gider.',
                  {'appName': appName},
                ),
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(onPressed: onDismiss, child: Text(tr('Anladım'))),
          ],
        ),
      ),
    );
  }
}

extension on Message {
  /// Sesli mesajın metni yalnızca "🎤 Sesli mesaj" etiketi mi.
  bool get textIsVoiceLabel =>
      text == '🎤 Sesli mesaj' || text == '🎵 Ses dosyası';
}

/// Fotoğraf/çıkartma/video önizlemesi; videolarda oynat simgesi.
class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.message, required this.onTap});

  final Message message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sticker = message.mediaKind == 'sticker';
    final maxWidth = sticker ? 160.0 : 260.0;
    return GestureDetector(
      onTap: sticker ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(sticker ? 0 : 14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: sticker ? 160 : 320,
              ),
              child: Image.file(
                File(message.mediaPath!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // Ekrandaki boyutta çözülür: tam çözünürlüklü fotoğraf
                // kaydırırken takılmaya yol açıyordu.
                cacheWidth: (maxWidth * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                // Dosya silinmiş ya da çözülemiyorsa yalnızca metin kalır.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            if (formatMediaInfo(
                  seconds: message.mediaDuration,
                  bytes: message.mediaSize,
                )
                case final info? when message.isVideo)
              Positioned(
                left: 8,
                bottom: 8,
                child: _MediaInfoBadge(text: info),
              ),
            if (message.isVideo)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  message.mediaKind == 'animation'
                      ? Icons.gif_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                  semanticLabel: tr('Oynat'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Önizlemesi olmayan ama indirilip açılabilen medya (Telegram videosu, dosya).
class _OpenableMedia extends StatelessWidget {
  const _OpenableMedia({
    required this.message,
    required this.color,
    required this.onTap,
  });

  final Message message;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.isVideo
                  ? Icons.play_circle_fill_rounded
                  : Icons.image_rounded,
              color: color,
              size: 36,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizeStored(message.text),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  if (formatMediaInfo(
                        seconds: message.mediaDuration,
                        bytes: message.mediaSize,
                      )
                      case final info?)
                    Text(
                      info,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Telegram sesli mesajı: indirilir ve uygulamada çalınır.
class _VoiceBubble extends StatefulWidget {
  const _VoiceBubble({
    required this.message,
    required this.bridge,
    required this.color,
  });

  final Message message;
  final CoreBridge bridge;
  final Color color;

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  VideoPlayerController? _player;
  bool _loading = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    var player = _player;
    if (player == null) {
      setState(() => _loading = true);
      final file = await widget.bridge.downloadMedia(widget.message.id);
      if (!mounted) return;
      if (file == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Sesli mesaj indirilemedi.'))),
        );
        return;
      }
      player = VideoPlayerController.file(File(file.path));
      await player.initialize();
      player.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _loading = false;
      });
    }
    final value = player.value;
    if (value.isPlaying) {
      await player.pause();
    } else {
      if (value.position >= value.duration) await player.seekTo(Duration.zero);
      await player.play();
    }
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final value = _player?.value;
    final total = value?.duration ?? Duration.zero;
    final position = value?.position ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.color,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggle,
                    icon: Icon(
                      value?.isPlaying ?? false
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: widget.color,
                      size: 38,
                    ),
                    tooltip: value?.isPlaying ?? false
                        ? tr('Duraklat')
                        : tr('Dinle'),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    color: widget.color,
                    backgroundColor: widget.color.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == Duration.zero
                      ? tr('Sesli mesaj')
                      : '${_clock(position)} / ${_clock(total)}',
                  style: TextStyle(
                    color: widget.color.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bildirimle görseli gelmeyen medya (ör. WhatsApp videosu): kaynakta aç.
class _SourceOnlyMedia extends StatelessWidget {
  const _SourceOnlyMedia({
    required this.message,
    required this.appName,
    required this.color,
    required this.onTap,
  });

  final Message message;
  final String appName;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.isVideo
                  ? Icons.play_circle_fill_rounded
                  : message.isVoice
                  ? Icons.mic_rounded
                  : Icons.image_rounded,
              color: color,
              size: 34,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simge zaten türü gösteriyor; "🎥 Video" etiketindeki emoji tekrar olur.
                  Text(
                    localizeStored(message.text).replaceFirst(
                      RegExp(r'^[^\p{L}\p{N}]+', unicode: true),
                      '',
                    ),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    tr('{appName}\'ta aç', {'appName': appName}),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.75),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: color.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kişi ekranında yanıtın gideceği uygulama (WhatsApp, Instagram, Telegram…).
class _PersonSwitcher extends StatelessWidget {
  const _PersonSwitcher({
    required this.members,
    required this.active,
    required this.onSelect,
  });

  final List<Conversation> members;
  final Conversation active;
  final ValueChanged<Conversation> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = [
      for (final m in members) MessagingApp.of(m.packageName).name,
    ];
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  tr('Yanıt:'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            for (final (i, m) in members.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: AppIcon(packageName: m.packageName, size: 18),
                  // Aynı uygulamadan iki sohbet varsa (ör. iki numara) adıyla.
                  label: Text(
                    names.where((n) => n == names[i]).length > 1
                        ? '${names[i]} · ${m.title}'
                        : names[i],
                  ),
                  tooltip: '${names[i]}: ${m.title}',
                  selected: m.key == active.key,
                  onSelected: (_) => onSelect(m),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Video önizlemesinin köşesinde süre ve boyut ("1:23 · 4,2 MB").
class _MediaInfoBadge extends StatelessWidget {
  const _MediaInfoBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}

/// Gönderilmekte olan mesajın dosyası yükleniyorsa "Yükleniyor %42". Yazı
/// mesajında (yüklenecek dosya yok) hiçbir şey göstermez.
class _UploadStatus extends StatefulWidget {
  const _UploadStatus({
    required this.bridge,
    required this.messageId,
    required this.color,
  });

  final CoreBridge bridge;
  final String messageId;
  final Color color;

  @override
  State<_UploadStatus> createState() => _UploadStatusState();
}

class _UploadStatusState extends State<_UploadStatus> {
  double? _progress;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _check();
    _poll = Timer.periodic(const Duration(milliseconds: 400), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final progress = await widget.bridge.uploadProgress(widget.messageId);
      if (mounted && progress != _progress) {
        setState(() => _progress = progress);
      }
    } catch (_) {
      // Eski yerel taraf ya da test: yüzde gösterilmez.
      _poll?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
              color: widget.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            tr('Yükleniyor %{percent}', {'percent': (progress * 100).round()}),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: widget.color),
          ),
        ],
      ),
    );
  }
}

/// "Yanıtlar WhatsApp açılmadan gitsin": gönderim kaynak uygulamayı açacakken.
class _KeepNudge extends StatelessWidget {
  const _KeepNudge({
    required this.appName,
    required this.onEnable,
    required this.onDismiss,
  });

  final String appName;
  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(
                  'Şu an gönderince {appName} açılıyor. Açarsanız bu sohbetten mesaj geldiğinde yanıtlarınız doğrudan gider.',
                  {'appName': appName},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(onPressed: onEnable, child: Text(tr('Aç'))),
            IconButton(
              tooltip: tr('Kapat'),
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
