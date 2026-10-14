import 'package:flutter/widgets.dart';

final _rtl = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final _ltr = RegExp(r'[A-Za-zÀ-ɏͰ-ϿЀ-ӿ]');

/// Kullanıcı metninin (mesaj, ad) yönü: ilk güçlü harfe göre. Arayüz
/// Arapçayken Türkçe mesajın soru işareti başa kaçmasın, arayüz Türkçeyken
/// Arapça mesaj sağdan sola okunsun. Yalnızca emoji ya da sayıysa null
/// (çevrenin yönü).
TextDirection? textDirectionOf(String text) {
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (_rtl.hasMatch(char)) return TextDirection.rtl;
    if (_ltr.hasMatch(char)) return TextDirection.ltr;
  }
  return null;
}
