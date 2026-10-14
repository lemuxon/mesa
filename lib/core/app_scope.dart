import 'package:flutter/widgets.dart';

import 'lock.dart';
import 'settings.dart';

/// Cihazdaki arayüz tercihleri ve kimlik doğrulayıcıyı ekranlara taşır.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.prefs,
    required this.authenticator,
    required super.child,
  });

  final LocalPrefs prefs;
  final Authenticator authenticator;

  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      prefs != oldWidget.prefs || authenticator != oldWidget.authenticator;
}
