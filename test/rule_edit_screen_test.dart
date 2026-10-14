import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/rules.dart';
import 'package:mesaj_merkezi/screens/rule_edit_screen.dart';

class _FakeBridge implements CoreBridge {
  final saved = <Rule>[];

  @override
  Future<int> saveRule(Rule rule) async {
    saved.add(rule);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<_FakeBridge> pump(WidgetTester tester) async {
    final bridge = _FakeBridge();
    await tester.pumpWidget(MaterialApp(home: RuleEditScreen(bridge: bridge)));
    return bridge;
  }

  testWidgets('otomatik yanıt metni boşsa kaydetmez', (tester) async {
    final bridge = await pump(tester);
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    expect(bridge.saved, isEmpty);
    await tester.ensureVisible(
      find.text('Otomatik yanıt için bir metin yazın'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Otomatik yanıt için bir metin yazın'), findsOneWidget);
  });

  testWidgets('koşulsuz otomatik yanıtta uyarı gösterir', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.textContaining('Koşul yok'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Koşul yok'), findsOneWidget);
  });

  testWidgets('formdaki değerlerle kuralı kaydeder', (tester) async {
    final bridge = await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Yanıt metni'),
      '  Tatildeyim  ',
    );
    await tester.ensureVisible(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    final keywords = find.widgetWithText(
      TextFormField,
      'Anahtar kelimeler (isteğe bağlı)',
    );
    await tester.ensureVisible(keywords);
    await tester.pumpAndSettle();
    await tester.enterText(keywords, 'acil, iş');
    await tester.pump();
    expect(find.textContaining('Koşul yok'), findsNothing);

    await tester.ensureVisible(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(bridge.saved, hasLength(1));
    final rule = bridge.saved.single;
    expect(rule.id, isNull);
    expect(rule.name, 'Otomatik yanıt'); // ad boş bırakıldı
    expect(rule.action, RuleAction.autoReply);
    expect(rule.replyText, 'Tatildeyim');
    expect(rule.keywords, ['acil', 'iş']);
    expect(rule.packages, {'com.whatsapp'});
    expect(rule.includeGroups, isFalse);
    expect(rule.cooldownMinutes, 60);
  });

  testWidgets('sessize alma kuralında yanıt metni gönderilmez', (tester) async {
    final bridge = await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Yanıt metni'),
      'kalıntı',
    );
    await tester.tap(find.text('Sessize al'));
    await tester.pump();
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(bridge.saved.single.action, RuleAction.mute);
    expect(bridge.saved.single.replyText, isEmpty);
  });
}
