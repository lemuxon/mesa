import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/frame_stats.dart';

void main() {
  test('kare özeti yavaş, takılan ve donan kareleri sayar', () {
    final stats = FrameStats();
    const ms = Duration(milliseconds: 1);
    stats.add(ms * 5, ms * 6); // akıcı
    stats.add(ms * 20, ms * 4); // yavaş
    stats.add(ms * 3, ms * 40); // takılma (çizim uzun)
    stats.add(ms * 800, ms * 2); // donma
    expect(
      stats.takeSummary(),
      '4 kare, %75.0 >16 ms, %50.0 >32 ms, 1 donma, en uzun 800 ms',
    );
    expect(stats.takeSummary(), isNull, reason: 'sayaçlar sıfırlanır');
  });
}
