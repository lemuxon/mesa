import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bridge.dart';
import 'models.dart';

/// Sohbetlerin "yazıyor…" ve çevrimiçi bilgisi; Sohbetler listesi ve sohbet
/// ekranı aynı kaynağı dinler. Yalnızca Telegram bu bilgiyi verir.
class PresenceHub extends ValueNotifier<Map<String, PresenceState>> {
  PresenceHub._() : super(const {});

  static final instance = PresenceHub._();

  StreamSubscription<PresenceState>? _subscription;

  /// Uygulama açılınca bir kez çağrılır.
  Future<void> attach(CoreBridge bridge) async {
    if (_subscription != null) return;
    try {
      _subscription = bridge.presenceChanges.listen(_apply, onError: (_) {});
      for (final state in await bridge.presence()) {
        _apply(state);
      }
    } catch (_) {
      // Yerel taraf yok (testler) ya da Telegram bağlı değil.
    }
  }

  void _apply(PresenceState state) {
    value = {...value, state.key: state};
  }

  PresenceState? of(String key) => value[key];
}
