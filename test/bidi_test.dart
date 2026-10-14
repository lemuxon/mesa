import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/ui/bidi.dart';

void main() {
  test('mesaj yönü ilk güçlü harfe göre', () {
    expect(textDirectionOf('Henüz yok, neden?'), TextDirection.ltr);
    expect(textDirectionOf('مرحبا، كيف حالك؟'), TextDirection.rtl);
    expect(textDirectionOf('👍 Привет'), TextDirection.ltr);
    expect(textDirectionOf('12:30 😀'), isNull);
  });
}
