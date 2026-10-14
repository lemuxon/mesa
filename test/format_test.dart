import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/format.dart';

void main() {
  final now = DateTime(2026, 10, 9, 15, 30); // Cuma

  test('bugün saat olarak gösterilir', () {
    expect(formatListTime(DateTime(2026, 10, 9, 8, 5), now), '08:05');
  });

  test('dün "Dün" olarak gösterilir', () {
    expect(formatListTime(DateTime(2026, 10, 8, 23, 59), now), 'Dün');
  });

  test('son bir hafta gün adıyla gösterilir', () {
    expect(formatListTime(DateTime(2026, 10, 5, 12), now), 'Pazartesi');
  });

  test('daha eskisi tarihle gösterilir', () {
    expect(formatListTime(DateTime(2026, 9, 1, 12), now), '01.09.2026');
  });
}
