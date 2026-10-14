import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Kasma ölçümü: kare sürelerinin içeriksiz özeti. Uygulama arka plana
/// geçince (ya da her 3000 karede) logcat'e tek satır yazılır; arka planda
/// zamanlayıcı yoktur.
class FrameStats {
  int frames = 0;

  /// 16 ms'yi aşan kare (60 Hz'de bir kare kaçar).
  int slow = 0;

  /// 32 ms'yi aşan kare (gözle görülen takılma).
  int janky = 0;

  /// 700 ms'yi aşan kare (donma).
  int frozen = 0;

  Duration worst = Duration.zero;

  static const _slow = Duration(milliseconds: 16);
  static const _janky = Duration(milliseconds: 32);
  static const _frozen = Duration(milliseconds: 700);

  /// Karenin oluşturma ve çizim süresinden uzun olanı sayılır (ikisi
  /// ayrı iş parçacıklarında, üst üste biner).
  void add(Duration build, Duration raster) {
    final longest = build > raster ? build : raster;
    frames++;
    if (longest > _slow) slow++;
    if (longest > _janky) janky++;
    if (longest >= _frozen) frozen++;
    if (longest > worst) worst = longest;
  }

  /// Özet satırı; kare yoksa null. Sayaçlar sıfırlanır.
  String? takeSummary() {
    if (frames == 0) return null;
    String pct(int n) => (100 * n / frames).toStringAsFixed(1);
    final line =
        '$frames kare, %${pct(slow)} >16 ms, %${pct(janky)} >32 ms, '
        '$frozen donma, en uzun ${worst.inMilliseconds} ms';
    frames = slow = janky = frozen = 0;
    worst = Duration.zero;
    return line;
  }
}

void startFrameStats() {
  final stats = FrameStats();
  void flush() {
    final line = stats.takeSummary();
    if (line != null) debugPrint('MesajMerkezi kare özeti: $line');
  }

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      stats.add(t.buildDuration, t.rasterDuration);
    }
    if (stats.frames >= 3000) flush();
  });
  // Bağlama kendini kaydeder; uygulama boyunca yaşar.
  AppLifecycleListener(onHide: flush);
}
