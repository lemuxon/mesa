import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/assistant.dart';
import '../core/bridge.dart';
import '../core/settings.dart';
import '../l10n/l10n.dart';
import '../ui/large_title.dart';

/// Ayarlar → Yapay zekâ asistanı: Claude API anahtarı, model ve neyin
/// gönderildiği.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.bridge,
    required this.prefs,
    this.checkKey = checkAssistantKey,
  });

  final CoreBridge bridge;
  final LocalPrefs prefs;

  /// Anahtarı Anthropic'e sorar: geçerliyse true, değilse false, bilinmiyorsa null.
  final Future<bool?> Function(String key) checkKey;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  bool? _hasKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool has;
    try {
      has = await widget.bridge.assistantHasKey();
    } catch (_) {
      has = false;
    }
    if (mounted) setState(() => _hasKey = has);
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _enterKey() async {
    final key = await showDialog<String>(
      context: context,
      builder: (_) => const _KeyDialog(),
    );
    if (key == null || key.isEmpty || !mounted) return;
    if (!key.startsWith('sk-ant-')) {
      _snack(
        tr(
          'Bu bir Claude API anahtarına benzemiyor; anahtarlar "sk-ant-" ile başlar.',
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final valid = await widget.checkKey(key);
      if (!mounted) return;
      if (valid == false) {
        _snack(
          tr(
            'Anthropic bu anahtarı kabul etmedi. Doğru kopyaladığınızdan emin olun.',
          ),
        );
        return;
      }
      await widget.bridge.assistantSetKey(key);
      if (!mounted) return;
      setState(() => _hasKey = true);
      _snack(
        valid == true
            ? tr('Anahtar kaydedildi; asistan hazır.')
            : tr('Anahtar kaydedildi; internet olmadığı için doğrulanamadı.'),
      );
    } catch (_) {
      if (mounted) _snack(tr('Anahtar kaydedilemedi.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeKey() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Anahtar silinsin mi?')),
        content: Text(
          tr(
            'Asistan, yeniden anahtar girene kadar çalışmaz. Anahtar Anthropic hesabınızda kalır; tamamen iptal etmek için console.anthropic.com\'dan silin.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Sil')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.bridge.assistantClearKey();
    if (mounted) setState(() => _hasKey = false);
  }

  Future<void> _setModel(String id) async {
    await widget.prefs.setAssistantModel(id);
    if (mounted) setState(() {});
  }

  String _modelNote(String id) => switch (id) {
    'claude-opus-5-5' => tr('En akıllısı · uzun bir özet yaklaşık 3 sent'),
    'claude-sonnet-5-5' => tr('Dengeli · uzun bir özet yaklaşık 1,5 sent'),
    _ => tr('En hızlısı ve en ucuzu · uzun bir özet 0,1 sentten az'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasKey = _hasKey == true;
    final selected = widget.prefs.assistantModel;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Yapay zekâ asistanı'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              tr(
                'Sohbetleri özetler, sohbete sorduğunuz soruyu yanıtlar, yanıt önerir ve yazdığınızı düzeltir. Anthropic\'in yapay zekâsı Claude ile, sizin API anahtarınızla çalışır.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SectionCard(
            title: tr('API anahtarı'),
            children: [
              ListTile(
                leading: Icon(
                  hasKey ? Icons.key_rounded : Icons.key_off_rounded,
                  color: hasKey ? scheme.primary : null,
                ),
                title: Text(
                  hasKey ? tr('Anahtar kayıtlı') : tr('Anahtar girilmedi'),
                ),
                subtitle: Text(
                  tr(
                    'Telefonda şifreli saklanır; Mesa\'nın yedeklerine girmez.',
                  ),
                ),
                trailing: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(
                  hasKey ? tr('Anahtarı değiştir') : tr('Anahtarı gir'),
                ),
                enabled: !_saving,
                onTap: _enterKey,
              ),
              if (hasKey)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error,
                  ),
                  title: Text(tr('Anahtarı sil')),
                  onTap: _removeKey,
                ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(tr('Anahtar nasıl alınır?')),
                subtitle: Text(
                  tr(
                    'console.anthropic.com\'da hesap açın, kredi yükleyin, "API Keys" bölümünden bir anahtar oluşturup buraya yapıştırın. Anahtarı kimseyle paylaşmayın.',
                  ),
                ),
                onTap: () => widget.bridge.openUri(
                  'https://console.anthropic.com/settings/keys',
                ),
              ),
            ],
          ),
          SectionCard(
            title: tr('Model'),
            children: [
              for (final MapEntry(key: id, value: name)
                  in assistantModels.entries)
                ListTile(
                  title: Text(name),
                  subtitle: Text(_modelNote(id)),
                  trailing: id == selected
                      ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                      : const Icon(Icons.circle_outlined),
                  selected: id == selected,
                  onTap: () => _setModel(id),
                ),
            ],
          ),
          SectionCard(
            title: tr('Ne gönderilir?'),
            children: [
              ListTile(
                leading: const Icon(Icons.touch_app_outlined),
                title: Text(tr('Yalnızca siz dokununca')),
                subtitle: Text(
                  tr(
                    'Özet ve soruda sohbetin son mesajları, yanıt önerisinde son 30 mesaj, düzeltmede yalnızca yazdığınız metin (çeviride son 10 mesaj da) gönderen adlarıyla Anthropic\'e gider. Kendiliğinden hiçbir şey gönderilmez; asistan sizin yerinize mesaj atmaz.',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: Text(tr('Verileriniz ve ücret')),
                subtitle: Text(
                  tr(
                    'Anthropic, API ile gönderilen verileri yapay zekâsını eğitmek için kullanmadığını belirtiyor. Ücret, kullandıkça Anthropic hesabınızdaki krediden düşer.',
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

/// Anahtarın yapıştırıldığı diyalog (denetleyici diyaloğun kendisinde).
class _KeyDialog extends StatefulWidget {
  const _KeyDialog();

  @override
  State<_KeyDialog> createState() => _KeyDialogState();
}

class _KeyDialogState extends State<_KeyDialog> {
  final _controller = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) _controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Claude API anahtarı')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: !_visible,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          hintText: 'sk-ant-…',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: tr('Yapıştır'),
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded),
              ),
              IconButton(
                tooltip: _visible ? tr('Gizle') : tr('Göster'),
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Vazgeç')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(tr('Kaydet')),
        ),
      ],
    );
  }
}
