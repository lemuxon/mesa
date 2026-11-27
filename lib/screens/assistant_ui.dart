import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/assistant.dart';
import '../l10n/l10n.dart';

/// Asistan hatasının kullanıcıya gösterilecek metni.
String assistantErrorText(Object? error) {
  final code = error is AssistantException ? error.code : AssistantError.failed;
  return switch (code) {
    AssistantError.noKey => tr(
      'Önce Ayarlar → Yapay zekâ asistanı bölümünden Claude API anahtarınızı girin.',
    ),
    AssistantError.invalidKey => tr(
      'Claude API anahtarı geçersiz ya da silinmiş. Ayarlar\'dan yeniden girin.',
    ),
    AssistantError.forbidden => tr('Bu API anahtarının bu işe izni yok.'),
    AssistantError.noCredit => tr(
      'Anthropic hesabınızda kredi kalmadı ya da harcama sınırına ulaşıldı. console.anthropic.com\'dan bakabilirsiniz.',
    ),
    AssistantError.rateLimited => tr(
      'Çok sık istek gönderildi; biraz bekleyip yeniden deneyin.',
    ),
    AssistantError.overloaded => tr(
      'Claude şu an çok yoğun; biraz sonra yeniden deneyin.',
    ),
    AssistantError.offline => tr(
      'Claude\'a ulaşılamadı. İnternet bağlantınızı kontrol edin.',
    ),
    AssistantError.refused => tr('Claude bu isteği yanıtlamadı.'),
    AssistantError.modelUnavailable => tr(
      'Seçili model hesabınızda kullanılamıyor; Ayarlar\'dan başka bir model seçin.',
    ),
    AssistantError.tooLarge => tr(
      'Sohbet asistana gönderilemeyecek kadar uzun.',
    ),
    AssistantError.badResponse ||
    AssistantError.failed => tr('Asistan yanıt veremedi; yeniden deneyin.'),
  };
}

/// Özet ya da sorunun yanıtı: yanıt geldikçe yazılır, kopyalanabilir.
Future<void> showAssistantResult(
  BuildContext context, {
  required String title,
  required String modelName,
  required Future<String> Function(void Function(String text) onText) run,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => AssistantResult(title: title, modelName: modelName, run: run),
);

class AssistantResult extends StatefulWidget {
  const AssistantResult({
    super.key,
    required this.title,
    required this.modelName,
    required this.run,
  });

  final String title;
  final String modelName;
  final Future<String> Function(void Function(String text) onText) run;

  @override
  State<AssistantResult> createState() => _AssistantResultState();
}

class _AssistantResultState extends State<AssistantResult> {
  String _text = '';
  Object? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _text = '';
      _error = null;
      _done = false;
    });
    try {
      final text = await widget.run((partial) {
        if (mounted) setState(() => _text = partial);
      });
      if (mounted) {
        setState(() {
          _text = text;
          _done = true;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _done = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = _error;
    final Widget body;
    if (error != null) {
      body = Text(
        assistantErrorText(error),
        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
      );
    } else if (_text.isEmpty) {
      body = Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(tr('Claude düşünüyor…')),
        ],
      );
    } else {
      body = SelectableText(_text, style: theme.textTheme.bodyLarge);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: body)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('{model} · Yapay zekâ yanılabilir', {
                        'model': widget.modelName,
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ),
                  if (error != null)
                    TextButton(
                      onPressed: _start,
                      child: Text(tr('Yeniden dene')),
                    )
                  else if (_done)
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _text));
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(tr('Kopyala')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Taslağa ne yapılacağı.
Future<RewriteMode?> pickRewriteMode(
  BuildContext context,
) => showModalBottomSheet<RewriteMode>(
  context: context,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(tr('Claude ile düzelt')),
            subtitle: Text(
              tr(
                'Yazdığınız metin Claude\'a gönderilir; siz onaylamadan değişmez.',
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.spellcheck_rounded),
            title: Text(tr('Yazım hatalarını düzelt')),
            onTap: () => Navigator.of(context).pop(RewriteMode.fix),
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_outlined),
            title: Text(tr('Daha kibar yap')),
            onTap: () => Navigator.of(context).pop(RewriteMode.polite),
          ),
          ListTile(
            leading: const Icon(Icons.short_text_rounded),
            title: Text(tr('Daha kısa yap')),
            onTap: () => Navigator.of(context).pop(RewriteMode.shorter),
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(tr('Karşı tarafın diline çevir')),
            subtitle: Text(
              tr(
                'Dil, sohbetin son mesajlarından anlaşılır; onlar da gönderilir.',
              ),
            ),
            onTap: () => Navigator.of(context).pop(RewriteMode.translate),
          ),
        ],
      ),
    ),
  ),
);

/// Yeniden yazılan metin: kullanılırsa true.
Future<bool> confirmRewrite(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.auto_awesome_rounded),
        title: Text(tr('Önerilen metin')),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Kullan')),
          ),
        ],
      ),
    ) ??
    false;

/// Mesaj kutusunun üstünde: yanıt öner, özetle, sor; yazarken düzelt.
/// Öneriler gelince onların çipleri.
class AssistantBar extends StatelessWidget {
  const AssistantBar({
    super.key,
    required this.hasText,
    required this.suggestions,
    required this.suggesting,
    required this.rewriting,
    required this.onSuggest,
    required this.onSummarize,
    required this.onAsk,
    required this.onRewrite,
    required this.onUseSuggestion,
    required this.onCloseSuggestions,
  });

  final bool hasText;
  final List<String>? suggestions;
  final bool suggesting;
  final bool rewriting;
  final VoidCallback onSuggest;
  final VoidCallback onSummarize;
  final VoidCallback onAsk;
  final VoidCallback onRewrite;
  final ValueChanged<String> onUseSuggestion;
  final VoidCallback onCloseSuggestions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(
      IconData icon,
      String label,
      VoidCallback? onPressed, {
      bool busy = false,
    }) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        avatar: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 16, color: scheme.primary),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
    final replies = suggestions;
    final List<Widget> children;
    if (replies != null && !hasText) {
      children = [
        for (final reply in replies)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              visualDensity: VisualDensity.compact,
              label: Text(reply),
              onPressed: () => onUseSuggestion(reply),
            ),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: tr('Önerileri kapat'),
          onPressed: onCloseSuggestions,
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ];
    } else if (hasText) {
      children = [
        chip(
          Icons.auto_awesome_rounded,
          rewriting ? tr('Düzeltiliyor…') : tr('Düzelt'),
          rewriting ? null : onRewrite,
          busy: rewriting,
        ),
      ];
    } else {
      children = [
        chip(
          Icons.auto_awesome_rounded,
          suggesting ? tr('Öneriler hazırlanıyor…') : tr('Yanıt öner'),
          suggesting ? null : onSuggest,
          busy: suggesting,
        ),
        chip(Icons.summarize_outlined, tr('Özetle'), onSummarize),
        chip(Icons.help_outline_rounded, tr('Sor'), onAsk),
      ];
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(children: children),
    );
  }
}
