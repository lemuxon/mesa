import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/bridge.dart';
import 'core/frame_stats.dart';
import 'core/lock.dart';
import 'core/settings.dart';
import 'core/web_services.dart';
import 'l10n/l10n.dart';
import 'screens/home_screen.dart';
import 'screens/lock_gate.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startFrameStats();
  final prefs = await LocalPrefs.load();
  final bridge = CoreBridge();
  // Seçilen dil; seçilmediyse telefonun dili (desteklenmiyorsa İngilizce).
  // Yerel taraf (bildirimler, bileşen) da aynı dili kullanır.
  setLanguage(prefs.languageCode);
  unawaited(bridge.setLanguage(prefs.languageCode).catchError((_) {}));
  // Kilit ayarının yerel kopyası: web servisi ekranı da kilide uysun.
  unawaited(bridge.appLockSetEnabled(prefs.lockEnabled).catchError((_) {}));
  // Hazır yanıtlar bildirimdeki tek dokunuşluk seçenekler için.
  unawaited(bridge.setQuickReplies(prefs.quickReplies).catchError((_) {}));
  final web = WebBridge();
  // Gelen kutusundaki web sohbetleri ilk çizimde servisin adıyla görünsün.
  try {
    await web.services();
  } on Exception {
    // Liste okunamazsa ad, servis listesi ilk kez açılınca güncellenir.
  }
  runApp(
    MesajMerkeziApp(
      bridge: bridge,
      web: web,
      prefs: prefs,
      authenticator: DeviceAuthenticator(),
    ),
  );
}

class MesajMerkeziApp extends StatelessWidget {
  const MesajMerkeziApp({
    super.key,
    required this.bridge,
    required this.web,
    required this.prefs,
    required this.authenticator,
  });

  final CoreBridge bridge;
  final WebBridge web;
  final LocalPrefs prefs;
  final Authenticator authenticator;

  @override
  Widget build(BuildContext context) {
    // Dil değişince Material metinleri (tarih seçici, kopyala/yapıştır) ve
    // yazı yönü (Arapça sağdan sola) de değişir.
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, language, _) => AppScope(
        prefs: prefs,
        authenticator: authenticator,
        child: MaterialApp(
          title: 'Mesa',
          locale: Locale(language),
          supportedLocales: [for (final code in languages.keys) Locale(code)],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          // Kilit, açılan tüm ekranların (sohbetler dahil) üstünü örtsün diye
          // Navigator'ın dışında.
          builder: (context, child) => LockGate(
            prefs: prefs,
            authenticator: authenticator,
            onLockChanged: (locked) =>
                bridge.appLockChanged(locked: locked).catchError((_) {}),
            isNativeLocked: bridge.appLockIsLocked,
            child: child!,
          ),
          home: HomeScreen(bridge: bridge, web: web),
        ),
      ),
    );
  }
}
