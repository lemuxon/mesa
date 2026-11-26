import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../l10n/l10n.dart';

/// Telefona indirilmiş çeviri paketleri: yer açmak için silinebilir
/// (gerekince ilk çeviride yeniden sorulur).
Future<void> showTranslationPacks(BuildContext context, CoreBridge bridge) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _TranslationPacks(bridge: bridge),
    );

class _TranslationPacks extends StatefulWidget {
  const _TranslationPacks({required this.bridge});

  final CoreBridge bridge;

  @override
  State<_TranslationPacks> createState() => _TranslationPacksState();
}

class _TranslationPacksState extends State<_TranslationPacks> {
  List<({String code, String name})>? _packs;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<({String code, String name})> packs;
    try {
      packs = await widget.bridge.translationPacks(currentLanguage);
    } catch (_) {
      packs = const [];
    }
    if (mounted) setState(() => _packs = packs);
  }

  Future<void> _delete(({String code, String name}) pack) async {
    setState(() => _deleting.add(pack.code));
    final ok = await widget.bridge.deleteTranslationPack(pack.code);
    if (!mounted) return;
    setState(() => _deleting.remove(pack.code));
    if (ok) {
      await _load();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('Dil paketi silinemedi.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packs = _packs;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tr('Çeviri dil paketleri'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                tr(
                  'Başka dildeki mesajlar bu paketlerle telefonda çevrilir; mesajlar hiçbir yere gönderilmez. Sildiğiniz paket gerekince yeniden sorulur.',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (packs == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (packs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  tr(
                    'Henüz dil paketi indirilmedi. Bir mesajın altındaki "Çevir"e dokununca gereken paket sorulur.',
                  ),
                ),
              )
            else
              for (final pack in packs)
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(_capitalized(pack.name)),
                  trailing: _deleting.contains(pack.code)
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: tr('Sil'),
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _delete(pack),
                        ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Dil adları bazı dillerde küçük harfle gelir ("anglais"); listede baş harf büyük.
String _capitalized(String name) =>
    name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
