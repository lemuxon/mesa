import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/settings.dart';
import '../l10n/l10n.dart';
import '../ui/large_title.dart';

/// Uygulamanın dilini (Flutter ve yerel taraf) uygular; [code] null: telefonun dili.
Future<void> applyAppLanguage(
  String? code,
  CoreBridge bridge,
  LocalPrefs? prefs,
) async {
  setLanguage(code);
  try {
    await bridge.setLanguage(code);
    // Değiştirilmemiş hazır yanıtlar yeni dilde olsun (bildirimdekiler dahil).
    if (prefs != null) await bridge.setQuickReplies(prefs.quickReplies);
  } catch (_) {
    // Eski yerel taraf ya da test: yalnızca arayüz değişir.
  }
}

/// Ayarlar'da "Dil": telefonun dili ya da seçilen dil.
class LanguageTile extends StatefulWidget {
  const LanguageTile({super.key, required this.bridge, this.prefs});

  final CoreBridge bridge;
  final LocalPrefs? prefs;

  @override
  State<LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<LanguageTile> {
  Future<void> _pick() async {
    final chosen = widget.prefs?.languageCode;
    final picked = await showModalBottomSheet<(String?,)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              tr('Uygulamanın dili'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _option(context, null, tr('Telefonun dili'), chosen == null),
          for (final MapEntry(key: code, value: name) in languages.entries)
            _option(context, code, name, chosen == code),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final code = picked.$1;
    await widget.prefs?.setLanguageCode(code);
    await applyAppLanguage(code, widget.bridge, widget.prefs);
    if (mounted) setState(() {});
  }

  Widget _option(BuildContext context, String? code, String name, bool on) =>
      ListTile(
        key: ValueKey('dil-${code ?? 'telefon'}'),
        title: Text(name),
        trailing: on
            ? Icon(
                Icons.check_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () => Navigator.of(context).pop((code,)),
      );

  @override
  Widget build(BuildContext context) {
    final chosen = widget.prefs?.languageCode;
    return SectionCard(
      title: tr('Dil'),
      children: [
        ListTile(
          leading: const Icon(Icons.translate_rounded),
          title: Text(tr('Uygulamanın dili')),
          subtitle: Text(
            chosen == null
                ? tr('Telefonun dili ({language})', {
                    'language': languages[currentLanguage],
                  })
                : languages[chosen] ?? chosen,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _pick,
        ),
      ],
    );
  }
}
