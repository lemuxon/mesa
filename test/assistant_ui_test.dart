import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/assistant.dart';
import 'package:mesaj_merkezi/core/bridge.dart';
import 'package:mesaj_merkezi/core/models.dart';
import 'package:mesaj_merkezi/core/settings.dart';
import 'package:mesaj_merkezi/screens/assistant_screen.dart';
import 'package:mesaj_merkezi/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBridge implements CoreBridge {
  bool hasKey = false;
  final savedKeys = <String>[];

  @override
  Stream<String> get changes => const Stream.empty();
  @override
  Future<List<Message>> messages(String key) async => [
    Message(
      id: 'm1',
      sender: 'Deniz',
      text: 'Bu akşam sinemaya gidelim mi?',
      time: DateTime(2026, 11, 27, 18),
      outgoing: false,
    ),
  ];
  @override
  Future<ReplyMode> replyMode(Conversation c) async => ReplyMode.app;
  @override
  Future<List<ScheduledMessage>> scheduledMessages({String? key}) async =>
      const [];
  @override
  Future<void> markRead(String key) async {}
  @override
  Future<void> setActiveConversation(String? key) async {}
  @override
  Future<AppSettings> settings() async => const AppSettings();
  @override
  Future<Set<String>> shareKinds(String packageName) async => {'photo'};
  @override
  Future<bool> assistantHasKey() async => hasKey;
  @override
  Future<void> assistantSetKey(String key) async {
    savedKeys.add(key);
    hasKey = true;
  }

  @override
  Future<void> assistantClearKey() async => hasKey = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAssistant implements Assistant {
  final calls = <String>[];

  @override
  Future<List<String>> suggestReplies(AssistantChat chat) async {
    calls.add('öneri:${chat.title}:${chat.messages.length}');
    return ['Olur', 'Bu akşam olmaz', 'Saat kaçta?'];
  }

  @override
  Future<String> summarize(
    AssistantChat chat, {
    void Function(String text)? onText,
  }) async {
    onText?.call('• Deniz');
    return '• Deniz bu akşam sinemaya gitmek istiyor.';
  }

  @override
  Future<String> ask(
    AssistantChat chat,
    String question, {
    void Function(String text)? onText,
  }) async {
    calls.add('soru:$question');
    return 'Bu akşam diyor.';
  }

  @override
  Future<String> rewrite(
    AssistantChat chat,
    String draft,
    RewriteMode mode,
  ) async {
    calls.add('düzelt:${mode.name}:$draft');
    return 'Olur, saat kaçta?';
  }
}

Future<void> _openChat(
  WidgetTester tester,
  _FakeBridge bridge, {
  Assistant? assistant,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        bridge: bridge,
        assistant: assistant,
        conversation: Conversation(
          key: 'com.instagram.android|Deniz',
          packageName: 'com.instagram.android',
          title: 'Deniz',
          isGroup: false,
          lastText: '',
          lastTime: DateTime(2026, 11, 27),
          unread: 1,
          canReply: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('anahtar girilmediyse asistan şeridi görünmez', (tester) async {
    await _openChat(tester, _FakeBridge());
    expect(find.text('Yanıt öner'), findsNothing);
  });

  testWidgets('yanıt önerisine dokununca kutuya yazılır', (tester) async {
    final assistant = _FakeAssistant();
    await _openChat(tester, _FakeBridge(), assistant: assistant);

    await tester.tap(find.text('Yanıt öner'));
    await tester.pumpAndSettle();
    expect(assistant.calls, ['öneri:Deniz:1']);
    expect(find.text('Bu akşam olmaz'), findsOneWidget);

    await tester.tap(find.text('Bu akşam olmaz'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Bu akşam olmaz');
    // Yazı varken öneriler yerine "Düzelt".
    expect(find.text('Olur'), findsNothing);
    expect(find.text('Düzelt'), findsOneWidget);
  });

  testWidgets('sohbet özeti yazılarak gelir, model adıyla', (tester) async {
    await _openChat(tester, _FakeBridge(), assistant: _FakeAssistant());

    await tester.tap(find.text('Özetle'));
    await tester.pumpAndSettle();
    expect(find.text('Deniz sohbetinin özeti'), findsOneWidget);
    expect(
      find.text('• Deniz bu akşam sinemaya gitmek istiyor.'),
      findsOneWidget,
    );
    expect(
      find.text('Claude Opus 5.5 · Yapay zekâ yanılabilir'),
      findsOneWidget,
    );
  });

  testWidgets('sohbete soru sorulur', (tester) async {
    final assistant = _FakeAssistant();
    await _openChat(tester, _FakeBridge(), assistant: assistant);

    await tester.tap(find.text('Sor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Ne zaman?',
    );
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Sor')),
    );
    await tester.pumpAndSettle();
    expect(assistant.calls, ['soru:Ne zaman?']);
    expect(find.text('Bu akşam diyor.'), findsOneWidget);
  });

  testWidgets('düzeltme ancak onaylanınca kutuya yazılır', (tester) async {
    final assistant = _FakeAssistant();
    await _openChat(tester, _FakeBridge(), assistant: assistant);

    await tester.enterText(find.byType(TextField), 'olr saat kacta');
    await tester.pump();
    await tester.tap(find.text('Düzelt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yazım hatalarını düzelt'));
    await tester.pumpAndSettle();
    expect(assistant.calls, ['düzelt:fix:olr saat kacta']);
    expect(find.text('Önerilen metin'), findsOneWidget);

    await tester.tap(find.text('Kullan'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Olur, saat kaçta?');
  });

  group('ayarlar', () {
    Future<(LocalPrefs, _FakeBridge, List<String>)> open(
      WidgetTester tester, {
      bool? valid = true,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefs.load();
      final bridge = _FakeBridge();
      final checked = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            bridge: bridge,
            prefs: prefs,
            checkKey: (key) async {
              checked.add(key);
              return valid;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (prefs, bridge, checked);
    }

    Future<void> enterKey(WidgetTester tester, String key) async {
      await tester.tap(find.text('Anahtarı gir'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        key,
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
    }

    testWidgets('anahtar doğrulanıp kaydedilir', (tester) async {
      final (_, bridge, checked) = await open(tester);
      expect(find.text('Anahtar girilmedi'), findsOneWidget);
      await enterKey(tester, ' sk-ant-deneme ');
      expect(checked, ['sk-ant-deneme']);
      expect(bridge.savedKeys, ['sk-ant-deneme']);
      expect(find.text('Anahtar kayıtlı'), findsOneWidget);
      expect(find.text('Anahtar kaydedildi; asistan hazır.'), findsOneWidget);
    });

    testWidgets('anahtara benzemeyen ya da reddedilen kaydedilmez', (
      tester,
    ) async {
      final (_, bridge, checked) = await open(tester, valid: false);
      await enterKey(tester, 'merhaba');
      expect(checked, isEmpty);
      await enterKey(tester, 'sk-ant-yanlis');
      expect(checked, ['sk-ant-yanlis']);
      expect(bridge.savedKeys, isEmpty);
      expect(find.text('Anahtar girilmedi'), findsOneWidget);
    });

    testWidgets('model seçilir', (tester) async {
      final (prefs, _, _) = await open(tester);
      expect(prefs.assistantModel, 'claude-opus-5-5');
      await tester.ensureVisible(find.text('Claude Haiku 5.5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Claude Haiku 5.5'));
      await tester.pumpAndSettle();
      expect(prefs.assistantModel, 'claude-haiku-5-5');
    });
  });
}
