import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';

/// Mesajdaki fotoğraf ya da videoyu tam ekran açar. [gallery] verilirse aynı
/// sohbetin (kişinin) diğer fotoğraf ve videolarına sağa-sola kaydırılır.
/// Telegram'da tam boy dosya önce indirilir (yüzdesiyle); bildirimden gelen
/// görsellerde elimizdeki kopya gösterilir.
class MediaViewer extends StatefulWidget {
  const MediaViewer({
    super.key,
    required this.bridge,
    required this.message,
    this.title,
    this.gallery = const [],
    this.titleOf,
    this.sourceAppOf,
    this.onOpenInApp,
  });

  final CoreBridge bridge;

  /// İlk açılan medya.
  final Message message;
  final String? title;

  /// Kaydırılabilecek medya, ekrandaki sırayla ([message] dahil).
  final List<Message> gallery;

  /// Sayfanın başlığı (gönderen); verilmezse [title].
  final String Function(Message)? titleOf;

  /// Bildirimden gelen görselin kaynak uygulaması ("Instagram"); Telegram'da
  /// (tam boy dosya zaten iner) null. Doluysa "Tam boyut" düğmesi çıkar.
  final String? Function(Message)? sourceAppOf;

  /// "Tam boyut": sohbeti kaynak uygulamada açar.
  final void Function(Message)? onOpenInApp;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final List<Message> _pages = widget.gallery.isEmpty
      ? [widget.message]
      : widget.gallery;
  late int _index = () {
    final i = _pages.indexWhere((m) => m.id == widget.message.id);
    return i < 0 ? 0 : i;
  }();
  late final _controller = PageController(initialPage: _index);

  /// Fotoğraf yakınlaştırılmışken kaydırma sayfayı değil fotoğrafı gezdirir.
  bool _zoomed = false;
  bool _fullscreen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final title = widget.titleOf?.call(page) ?? widget.title;
    // Bildirim önizlemesi: uygulamalar çoğu zaman küçük gönderir.
    final sourceApp = page.downloadable ? null : widget.sourceAppOf?.call(page);
    final openInApp = widget.onOpenInApp;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black38,
              foregroundColor: Colors.white,
              actions: [
                if (sourceApp != null && openInApp != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => openInApp(page),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(tr('Tam boyut')),
                  ),
              ],
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) Text(title),
                  Text(
                    _pages.length > 1
                        ? '${formatWhen(page.time, DateTime.now())} · '
                              '${_index + 1} / ${_pages.length}'
                        : formatWhen(page.time, DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
      body: PageView.builder(
        controller: _controller,
        physics: _zoomed || _fullscreen
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: _pages.length,
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoomed = false;
        }),
        itemBuilder: (context, i) => _MediaPage(
          key: ValueKey(_pages[i].id),
          bridge: widget.bridge,
          message: _pages[i],
          active: i == _index,
          onZoomChanged: (zoomed) {
            if (i == _index && zoomed != _zoomed) {
              setState(() => _zoomed = zoomed);
            }
          },
          onFullscreenChanged: (value) => setState(() => _fullscreen = value),
        ),
      ),
    );
  }
}

/// Tek fotoğraf ya da video: indirir, gösterir, oynatır.
class _MediaPage extends StatefulWidget {
  const _MediaPage({
    super.key,
    required this.bridge,
    required this.message,
    required this.active,
    required this.onZoomChanged,
    required this.onFullscreenChanged,
  });

  final CoreBridge bridge;
  final Message message;

  /// Ekrandaki sayfa: yalnızca o oynar.
  final bool active;
  final ValueChanged<bool> onZoomChanged;
  final ValueChanged<bool> onFullscreenChanged;

  @override
  State<_MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<_MediaPage> {
  MediaFile? _file;
  bool _failed = false;
  VideoPlayerController? _video;

  /// Telegram indirmesinin ilerlemesi (0..1); bilinmiyorsa null.
  double? _progress;
  Timer? _progressPoll;
  final _zoom = TransformationController();

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      widget.onZoomChanged(_zoom.value.getMaxScaleOnAxis() > 1.01);
    });
    _load();
  }

  @override
  void didUpdateWidget(_MediaPage old) {
    super.didUpdateWidget(old);
    // Başka sayfaya geçilince video durur.
    if (old.active && !widget.active) _video?.pause();
  }

  @override
  void dispose() {
    _progressPoll?.cancel();
    _video?.dispose();
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final message = widget.message;
    MediaFile? file;
    if (message.downloadable) {
      _progressPoll = Timer.periodic(
        const Duration(milliseconds: 300),
        (_) => _pollProgress(),
      );
      try {
        file = await widget.bridge.downloadMedia(message.id);
      } finally {
        _progressPoll?.cancel();
        _progressPoll = null;
      }
    }
    file ??= switch (message.mediaPath) {
      final path? => MediaFile(path: path, kind: 'photo'),
      null => null,
    };
    if (!mounted) return;
    if (file == null) {
      setState(() => _failed = true);
      return;
    }
    if (file.isVideo) {
      final controller = VideoPlayerController.file(File(file.path));
      try {
        await controller.initialize();
      } on Exception {
        await controller.dispose();
        if (mounted) setState(() => _failed = true);
        return;
      }
      // GIF'ler Telegram'da sessiz mp4: döngüde oynar.
      final animation = file.kind == 'animation';
      await controller.setLooping(animation);
      if (animation) await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      if (widget.active) await controller.play();
      _video = controller;
    }
    setState(() => _file = file);
  }

  Future<void> _pollProgress() async {
    try {
      final progress = await widget.bridge.downloadProgress(widget.message.id);
      if (mounted && progress != null) setState(() => _progress = progress);
    } catch (_) {
      // Eski yerel taraf ya da test: yüzde gösterilmez.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            tr('Medya açılamadı.'),
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final file = _file;
    if (file == null) return _loading();
    final video = _video;
    if (video != null) {
      return VideoControls(
        controller: video,
        animation: file.kind == 'animation',
        onFullscreenChanged: widget.onFullscreenChanged,
      );
    }
    return InteractiveViewer(
      transformationController: _zoom,
      maxScale: 6,
      child: Center(
        child: Image.file(
          File(file.path),
          errorBuilder: (_, _, _) => Text(
            tr('Görsel açılamadı.'),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// İndirilirken önizleme bulanık arka plan olur; yüzde ve boyut yazılır.
  Widget _loading() {
    final message = widget.message;
    final preview = message.mediaPath;
    final progress = _progress;
    final size = message.mediaSize;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (preview != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Image.file(
              File(preview),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: progress,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                progress == null
                    ? (message.downloadable
                          ? tr('İndiriliyor…')
                          : tr('Açılıyor…'))
                    : tr('İndiriliyor… %{percent}', {
                        'percent': (progress * 100).round(),
                      }),
                style: const TextStyle(color: Colors.white),
              ),
              if (size != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    progress == null
                        ? formatSize(size)
                        : '${formatSize((size * progress).round())} / '
                              '${formatSize(size)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Video oynatıcı: dokununca denetimler görünür/gizlenir; oynat/duraklat,
/// sarma çubuğu, geçen/toplam süre, ses ve tam ekran (yatay).
class VideoControls extends StatefulWidget {
  const VideoControls({
    super.key,
    required this.controller,
    this.animation = false,
    this.onFullscreenChanged,
  });

  final VideoPlayerController controller;

  /// GIF: sessiz döngü, denetim çubuğu yok.
  final bool animation;
  final ValueChanged<bool>? onFullscreenChanged;

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  bool _visible = true;
  bool _fullscreen = false;

  /// Sürüklenirken çubuğun konumu (bırakınca sarılır).
  double? _dragMs;
  Timer? _hide;

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
    _scheduleHide();
  }

  @override
  void dispose() {
    _c.removeListener(_tick);
    _hide?.cancel();
    if (_fullscreen) _restoreScreen();
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  /// Oynarken denetimler 3 sn sonra çekilir.
  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && _c.value.isPlaying && _dragMs == null) {
        setState(() => _visible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _visible = !_visible);
    if (_visible) _scheduleHide();
  }

  void _togglePlay() {
    final value = _c.value;
    if (value.isPlaying) {
      _c.pause();
    } else {
      // Sona gelmişse baştan.
      if (value.position >= value.duration) _c.seekTo(Duration.zero);
      _c.play();
    }
    _scheduleHide();
  }

  void _toggleMute() {
    _c.setVolume(_c.value.volume > 0 ? 0 : 1);
    _scheduleHide();
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    setState(() => _fullscreen = next);
    widget.onFullscreenChanged?.call(next);
    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _restoreScreen();
    }
    _scheduleHide();
  }

  Future<void> _restoreScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const []);
  }

  @override
  Widget build(BuildContext context) {
    final value = _c.value;
    final durationMs = value.duration.inMilliseconds.toDouble();
    final positionMs =
        _dragMs ??
        value.position.inMilliseconds.toDouble().clamp(0.0, durationMs);
    final showControls = !widget.animation && (_visible || !value.isPlaying);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.animation ? _togglePlay : _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(_c),
            ),
          ),
          if (showControls) ...[
            const Positioned.fill(child: ColoredBox(color: Colors.black26)),
            IconButton(
              iconSize: 64,
              color: Colors.white,
              onPressed: _togglePlay,
              tooltip: value.isPlaying ? tr('Duraklat') : tr('Oynat'),
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
                  child: Row(
                    children: [
                      Text(
                        '${formatDuration(Duration(milliseconds: positionMs.round()))}'
                        ' / ${formatDuration(value.duration)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white30,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: positionMs,
                            max: durationMs <= 0 ? 1 : durationMs,
                            onChangeStart: (v) {
                              _hide?.cancel();
                              setState(() => _dragMs = v);
                            },
                            onChanged: (v) => setState(() => _dragMs = v),
                            onChangeEnd: (v) async {
                              await _c.seekTo(
                                Duration(milliseconds: v.round()),
                              );
                              if (mounted) setState(() => _dragMs = null);
                              _scheduleHide();
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: _toggleMute,
                        tooltip: value.volume > 0
                            ? tr('Sesi kapat')
                            : tr('Sesi aç'),
                        icon: Icon(
                          value.volume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: _toggleFullscreen,
                        tooltip: _fullscreen
                            ? tr('Tam ekrandan çık')
                            : tr('Tam ekran'),
                        icon: Icon(
                          _fullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
