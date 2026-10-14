import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/apps.dart';
import 'package:mesaj_merkezi/core/rules.dart';

void main() {
  group('parseKeywords', () {
    test('virgülle ayırır, boşlukları ve boş öğeleri atar', () {
      expect(parseKeywords(' acil, toplantı ,, '), ['acil', 'toplantı']);
    });

    test('tekrarları büyük/küçük harf duyarsız atar, ilk yazılışı korur', () {
      expect(parseKeywords('Acil, acil, ACIL, fatura'), ['Acil', 'fatura']);
    });

    test('boş girdi boş liste', () {
      expect(parseKeywords('   '), isEmpty);
    });
  });

  test('Rule harita dönüşümü gidip gelir', () {
    const rule = Rule(
      id: 3,
      name: 'Tatil',
      packages: {'com.whatsapp'},
      keywords: ['acil'],
      senderContains: 'Ali',
      includeGroups: true,
      action: RuleAction.autoReply,
      replyText: 'Tatildeyim',
      cooldownMinutes: 360,
    );
    final back = Rule.fromMap({...rule.toMap(), 'recentFires': 4});
    expect(back.toMap(), rule.toMap());
    expect(back.recentFires, 4);
    expect(back.action, RuleAction.autoReply);
  });

  test('yeni kuralın kimliği null gönderilir', () {
    const rule = Rule(name: 'x', action: RuleAction.mute);
    expect(rule.toMap()['id'], isNull);
    expect(rule.toMap()['action'], 'MUTE');
    expect(rule.hasConditions, isFalse);
  });

  test('koşul özeti', () {
    String name(String p) => MessagingApp.of(p).name;
    expect(
      describeConditions(const Rule(name: 'x', action: RuleAction.mute), name),
      'Tüm uygulamalar',
    );
    expect(
      describeConditions(
        const Rule(
          name: 'x',
          action: RuleAction.important,
          packages: {
            'org.telegram.messenger',
            'org.telegram.messenger.web',
            'com.whatsapp',
          },
          senderContains: 'Anne',
          keywords: ['acil', 'hastane'],
          includeGroups: true,
        ),
        name,
      ),
      'Telegram, WhatsApp · Kimden: "Anne" · İçerik: acil, hastane · '
      'gruplar dahil',
    );
  });

  test('aynı adlı paketler tek seçenekte toplanır', () {
    expect(MessagingApp.packagesByName['SMS'], hasLength(2));
    expect(MessagingApp.packagesByName['Telegram'], hasLength(2));
  });
}
