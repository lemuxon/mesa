import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesaj_merkezi/core/secure.dart';
import 'package:mesaj_merkezi/screens/secure_connection_screen.dart';

class _FakeSecureBridge extends SecureBridge {
  _FakeSecureBridge({this.proxies});

  bool running = false;
  String provider = 'cloudflare';
  bool shield = false;
  List<TelegramProxy>? proxies;
  final calls = <String>[];

  @override
  Future<SecureStatus> status() async => SecureStatus(
    dns: SecureDnsStatus(
      running: running,
      enabled: running,
      prepared: true,
      provider: provider,
      queries: running ? 42 : 0,
      latencyMs: 18,
    ),
    shield: ShieldStatus(supported: true, enabled: shield),
  );

  @override
  Future<String> startDns() async {
    calls.add('start');
    running = true;
    return 'started';
  }

  @override
  Future<void> stopDns() async {
    calls.add('stop');
    running = false;
  }

  @override
  Future<void> setDnsProvider(String id) async {
    calls.add('provider:$id');
    provider = id;
  }

  @override
  Future<void> setShield(bool enabled) async {
    calls.add('shield:$enabled');
    shield = enabled;
  }

  @override
  Future<List<TelegramProxy>?> telegramProxies() async => proxies;

  @override
  Future<int?> pingTelegram(int? id) async {
    calls.add('ping:$id');
    return id == null ? null : 120;
  }
}

Future<void> _open(WidgetTester tester, _FakeSecureBridge bridge) async {
  await tester.binding.setSurfaceSize(const Size(800, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: SecureConnectionScreen(
        bridge: bridge,
        refreshInterval: const Duration(hours: 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('proxy bağlantısı', () {
    test('tg://proxy onaltılık anahtarla', () {
      final link = parseProxyLink(
        'tg://proxy?server=1.2.3.4&port=443&secret=DD00112233445566778899AABBCCDDEEFF',
      )!;
      expect(link.type, 'mtproto');
      expect(link.server, '1.2.3.4');
      expect(link.port, 443);
      expect(link.secret, 'dd00112233445566778899aabbccddeeff');
    });

    test('t.me/proxy base64url anahtar onaltılığa çevrilir', () {
      final bytes = List<int>.generate(17, (i) => i * 7);
      final secret = base64Url.encode(bytes).replaceAll('=', '');
      final link = parseProxyLink(
        'https://t.me/proxy?server=proxy.example&port=8443&secret=$secret',
      )!;
      expect(
        link.secret,
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      );
    });

    test('şemasız t.me/socks kullanıcı ve parolayla', () {
      final link = parseProxyLink(
        't.me/socks?server=s.example&port=1080&user=ali&pass=gizli',
      )!;
      expect(link.type, 'socks5');
      expect(link.username, 'ali');
      expect(link.password, 'gizli');
    });

    test('geçersiz bağlantılar reddedilir', () {
      expect(
        parseProxyLink('https://example.com/proxy?server=a&port=1&secret=00'),
        isNull,
      );
      expect(parseProxyLink('tg://proxy?server=a&port=0&secret=00'), isNull);
      expect(parseProxyLink('tg://proxy?server=a&port=443'), isNull);
      expect(parseProxyLink('tg://resolve?domain=mesa'), isNull);
      expect(parseProxyLink(''), isNull);
    });
  });

  test('durum haritası okunur', () {
    final status = SecureStatus.fromMap({
      'dns': {
        'running': true,
        'enabled': true,
        'prepared': true,
        'provider': 'adguard',
        'queries': 10,
        'privateDns': 'hostname',
        'since': 1700000000000,
      },
      'shield': {'supported': true, 'enabled': false},
    });
    expect(status.dns.provider, 'adguard');
    expect(status.dns.queries, 10);
    expect(status.dns.privateDnsOverrides, isTrue);
    expect(status.dns.since, isNotNull);
    expect(status.shield.supported, isTrue);
  });

  testWidgets('şifreli DNS açılır, sağlayıcı değişir', (tester) async {
    final bridge = _FakeSecureBridge();
    await _open(tester, bridge);
    expect(find.text('Bütün telefonda şifreli DNS'), findsOneWidget);
    expect(find.text('Kapalı'), findsOneWidget);

    await tester.tap(find.text('Bütün telefonda şifreli DNS'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('start'));
    expect(find.text('Açık · Cloudflare 1.1.1.1'), findsOneWidget);
    expect(find.text('42 sorgu'), findsOneWidget);

    await tester.tap(find.text('AdGuard DNS'));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('provider:adguard'));
    expect(find.text('Açık · AdGuard DNS'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('erişim kalkanı açılır', (tester) async {
    final bridge = _FakeSecureBridge();
    await _open(tester, bridge);
    await tester.tap(find.text('Web servisleri için erişim kalkanı'));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('shield:true'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Telegram açık değilse proxy için yönlendirir', (tester) async {
    final bridge = _FakeSecureBridge();
    await _open(tester, bridge);
    expect(
      find.text('Proxy eklemek için önce Telegram bağlantısını başlatın.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('proxy listesi ve doğrudan erişim denemesi', (tester) async {
    final bridge = _FakeSecureBridge(
      proxies: const [
        TelegramProxy(
          id: 3,
          server: 'proxy.example',
          port: 443,
          type: 'mtproto',
          enabled: true,
        ),
      ],
    );
    await _open(tester, bridge);
    expect(find.text('proxy.example:443'), findsOneWidget);
    expect(find.text('MTProto · Kullanılıyor'), findsOneWidget);

    await tester.tap(find.text('Dene'));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('ping:null'));
    expect(find.text('Ulaşılamıyor'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
