import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Tek alanlı metin diyaloğu; onaylanırsa yazılan metin, vazgeçilirse null.
///
/// Denetleyici diyaloğun kendisinde: çağıran tarafta `showDialog`'dan hemen
/// sonra kapatılırsa kapanış animasyonu sürerken alan onu kullanmaya devam
/// ediyor ve "TextEditingController was used after being disposed" hatası
/// çıkıyordu (2026-10-11, testte yakalandı).
Future<String?> showTextDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String? hint,
  int maxLines = 1,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextDialog(
    title: title,
    confirmLabel: confirmLabel,
    initial: initial,
    hint: hint,
    maxLines: maxLines,
  ),
);

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    required this.hint,
    required this.maxLines,
  });

  final String title;
  final String confirmLabel;
  final String initial;
  final String? hint;
  final int maxLines;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      minLines: 1,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: widget.maxLines == 1 ? (_) => _confirm() : null,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(tr('Vazgeç')),
      ),
      FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
    ],
  );
}
