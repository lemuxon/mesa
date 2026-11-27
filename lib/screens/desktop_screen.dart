import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../l10n/l10n.dart';
import '../ui/large_title.dart';

/// Ayarlar → Bilgisayardan Mesa: aç/kapat, bilgisayarda açılacak adres,
/// adımlar ve eşleştirilmiş tarayıcılar.
class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  DesktopStatus? _status;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // Sunucu açılınca adres, telefondan izin verilince bağlı tarayıcı görünsün.
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await widget.bridge.desktopStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted && _status == null) {
        setState(() => _status = const DesktopStatus());
      }
    }
  }

  Future<void> _setEnabled(bool value) async {
    setState(
      () => _status = DesktopStatus(
        enabled: value,
        running: false,
        sessions: _status?.sessions ?? const [],
      ),
    );
    await widget.bridge.desktopSetEnabled(value);
    await _load();
  }

  Future<void> _revoke(DesktopSession session) async {
    await widget.bridge.desktopRevoke(session.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Bilgisayardan Mesa'))),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    tr(
                      'Mesajlarınızı aynı Wi-Fi\'deki bir bilgisayarın tarayıcısından okuyup yanıtlayın. Bağlantı şifrelidir ve internete çıkmaz; telefon açık ve Wi-Fi\'de olmalı.',
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                SectionCard(
                  title: tr('Bağlantı'),
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.computer_rounded),
                      title: Text(tr('Bilgisayardan Mesa')),
                      subtitle: Text(
                        status.enabled
                            ? (status.running
                                  ? tr('Açık; bilgisayar bağlanabilir')
                                  : tr('Açılıyor…'))
                            : tr('Kapalı'),
                      ),
                      value: status.enabled,
                      onChanged: _setEnabled,
                    ),
                  ],
                ),
                if (status.enabled && status.running && status.urls.isEmpty)
                  SectionCard(
                    title: tr('Bilgisayarda açılacak adres'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.wifi_off_rounded),
                        title: Text(tr('Telefon bir Wi-Fi ağına bağlı değil')),
                        subtitle: Text(
                          tr('Wi-Fi\'ye bağlanınca adres burada görünür.'),
                        ),
                      ),
                    ],
                  ),
                if (status.enabled && status.urls.isNotEmpty)
                  SectionCard(
                    title: tr('Bilgisayarda açılacak adres'),
                    children: [
                      for (final url in status.urls)
                        ListTile(
                          title: SelectableText(
                            url,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: tr('Kopyala'),
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: url));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('Kopyalandı.'))),
                              );
                            },
                          ),
                        ),
                      const Divider(height: 1),
                      _Step(
                        number: 1,
                        text: tr(
                          'Bilgisayarınız telefonla aynı Wi-Fi\'ye bağlı olsun.',
                        ),
                      ),
                      _Step(
                        number: 2,
                        text: tr(
                          'Bilgisayarın tarayıcısında yukarıdaki adresi açın.',
                        ),
                      ),
                      _Step(
                        number: 3,
                        text: tr(
                          'Tarayıcı bir güvenlik uyarısı gösterirse "Gelişmiş"e, ardından "ilerle" ya da "devam et" yazan bağlantıya tıklayın. Sertifikayı telefonunuz oluşturduğu için tarayıcı onu tanımıyor; bağlantı yine de şifreli.',
                        ),
                      ),
                      _Step(
                        number: 4,
                        text: tr(
                          '"Bağlan"a tıklayın; telefonunuzdaki bildirimde aynı kodu görüyorsanız "İzin ver"e dokunun.',
                        ),
                      ),
                    ],
                  ),
                SectionCard(
                  title: tr('Bağlı bilgisayarlar'),
                  children: [
                    if (status.sessions.isEmpty)
                      ListTile(
                        leading: const Icon(Icons.devices_outlined),
                        title: Text(tr('Henüz bağlı bilgisayar yok')),
                      )
                    else
                      for (final session in status.sessions)
                        ListTile(
                          leading: const Icon(Icons.laptop_rounded),
                          title: Text(session.name),
                          subtitle: Text(
                            tr('Son kullanım: {when}', {
                              'when': formatListTime(
                                session.lastSeen,
                                DateTime.now(),
                              ),
                            }),
                          ),
                          trailing: IconButton(
                            tooltip: tr('Bağlantıyı kes'),
                            icon: const Icon(Icons.link_off_rounded),
                            onPressed: () => _revoke(session),
                          ),
                        ),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      subtitle: Text(
                        tr(
                          'Ortak bir bilgisayarda işiniz bitince tarayıcıda "Çıkış yap"a tıklayın ya da buradan bağlantıyı kesin. 30 gün kullanılmayan bağlantı kendiliğinden kapanır.',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          '$number',
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(text),
    );
  }
}
