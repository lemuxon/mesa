import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/lock.dart';
import '../core/settings.dart';

/// Kilit açıkken tüm uygulamanın (açık sohbetler dahil) üstünü örter.
/// Uygulama [relockAfter]'dan uzun süre arka planda kalınca yeniden kilitlenir.
class LockGate extends StatefulWidget {
  const LockGate({
    super.key,
    required this.prefs,
    required this.authenticator,
    required this.child,
    this.relockAfter = const Duration(seconds: 30),
    this.now = DateTime.now,
    this.onLockChanged,
    this.isNativeLocked,
  });

  final LocalPrefs prefs;
  final Authenticator authenticator;
  final Widget child;
  final Duration relockAfter;

  /// Testlerde zamanı ilerletebilmek için.
  final DateTime Function() now;

  /// Kilit açılınca/kapanınca: yerel ekranlar (web servisi sayfası) da uysun.
  final ValueChanged<bool>? onLockChanged;

  /// Yerel taraf kilitli mi. Web servisi ekranına geçmek Flutter'a "arka
  /// plan" görünür ama uygulama arka planda değildir; orada kilit açıldıysa
  /// burada yeniden sorulmaz. Verilmezse yalnızca süre ölçülür.
  final Future<bool> Function()? isNativeLocked;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked = widget.prefs.lockEnabled;
  DateTime? _pausedAt;

  /// Doğrulama penceresi uygulamayı arka plana itebilir; o sırada
  /// "arka planda kaldı" sayılıp tekrar kilitlenmesin.
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (!_authenticating) _pausedAt ??= widget.now();
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (!widget.prefs.lockEnabled || _locked || pausedAt == null) return;
        if (widget.now().difference(pausedAt) >= widget.relockAfter) {
          // Önce hemen örtülür (içerik bir an bile görünmesin), sonra sorulur.
          setState(() => _locked = true);
          widget.onLockChanged?.call(true);
          _resolve();
        }
      default:
        break;
    }
  }

  /// Kilitliyken: yerel tarafta (web servisi ekranında) az önce açıldıysa
  /// yeniden sorulmaz, yoksa kimlik doğrulanır.
  Future<void> _resolve() async {
    final native = widget.isNativeLocked;
    if (native != null) {
      try {
        if (!await native()) {
          if (mounted) setState(() => _locked = false);
          return;
        }
      } catch (_) {
        // Yerel taraf yanıt vermedi: kimlik sorulur.
      }
    }
    await _unlock();
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    final ok = await widget.authenticator.authenticate(
      tr('Mesa\'yı açmak için kimliğinizi doğrulayın'),
    );
    _authenticating = false;
    if (ok && mounted) {
      setState(() => _locked = false);
      widget.onLockChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Kilitliyken alttaki içerik erişilebilirlik ağacından da gizlenir.
        ExcludeSemantics(excluding: _locked, child: widget.child),
        if (_locked) Positioned.fill(child: _LockScreen(onUnlock: _unlock)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(tr('Mesa kilitli'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(tr('Kilidi aç')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
