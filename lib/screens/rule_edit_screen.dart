import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/rules.dart';

/// Kural ekleme / düzenleme. Kaydedilince ya da silinince `true` ile kapanır.
class RuleEditScreen extends StatefulWidget {
  const RuleEditScreen({super.key, required this.bridge, this.rule});

  final CoreBridge bridge;

  /// Yeni kural için null.
  final Rule? rule;

  @override
  State<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends State<RuleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.rule?.name);
  late final _keywords = TextEditingController(
    text: widget.rule?.keywords.join(', '),
  );
  late final _sender = TextEditingController(text: widget.rule?.senderContains);
  late final _reply = TextEditingController(text: widget.rule?.replyText);

  // Web servisleri de seçilebilir (Discord, Slack…).
  final _appPackages = MessagingApp.packagesByNameWithWeb;

  /// Seçili uygulamaların görünen adları; boşsa tümü.
  late final Set<String> _apps = {
    for (final MapEntry(key: name, value: packages) in _appPackages.entries)
      if (packages.any((p) => widget.rule?.packages.contains(p) ?? false)) name,
  };
  late RuleAction _action = widget.rule?.action ?? RuleAction.autoReply;
  late bool _includeGroups = widget.rule?.includeGroups ?? false;
  late int _cooldown = cooldownOptions.containsKey(widget.rule?.cooldownMinutes)
      ? widget.rule!.cooldownMinutes
      : 60;
  late bool _timed = widget.rule?.hasTimeWindow ?? false;
  late int _from = widget.rule?.activeFrom ?? 23 * 60;
  late int _to = widget.rule?.activeTo ?? 8 * 60;
  late int _days = widget.rule?.activeDays ?? Rule.allDays;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _keywords.dispose();
    _sender.dispose();
    _reply.dispose();
    super.dispose();
  }

  Rule _build() {
    final name = _name.text.trim();
    return Rule(
      id: widget.rule?.id,
      name: name.isEmpty ? _action.label : name,
      enabled: widget.rule?.enabled ?? true,
      packages: {for (final app in _apps) ..._appPackages[app]!},
      keywords: parseKeywords(_keywords.text),
      senderContains: _sender.text.trim(),
      includeGroups: _includeGroups,
      action: _action,
      replyText: _action == RuleAction.autoReply ? _reply.text.trim() : '',
      cooldownMinutes: _cooldown,
      activeFrom: _timed ? _from : null,
      activeTo: _timed ? _to : null,
      activeDays: _days,
    );
  }

  Future<void> _pickTime({required bool start}) async {
    final minutes = start ? _from : _to;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: start ? tr('Başlangıç saati') : tr('Bitiş saati'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final value = picked.hour * 60 + picked.minute;
      start ? _from = value : _to = value;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days & Rule.allDays == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('En az bir gün seçin.'))));
      return;
    }
    setState(() => _saving = true);
    // Önemli kuralı bildirim gösterir; Android 13+ izni şimdi istenir.
    if (_action == RuleAction.important) {
      await widget.bridge.requestNotificationPermission();
    }
    await widget.bridge.saveRule(_build());
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Kural silinsin mi?')),
        content: Text(
          tr('"{name}" kalıcı olarak silinecek.', {'name': widget.rule!.name}),
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
    if (!(confirmed ?? false)) return;
    await widget.bridge.deleteRule(widget.rule!.id!);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = _build();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.rule?.id == null ? tr('Yeni kural') : tr('Kuralı düzenle'),
        ),
        actions: [
          if (widget.rule?.id != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: tr('Sil'),
            ),
        ],
      ),
      // ListView değil: tembel liste ekran dışındaki alanları atar ve Form
      // onları doğrulayamaz (aşağı kaydırıp kaydedince boş yanıt metni geçiyordu).
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: tr('Kural adı'),
                  hintText: _action.label,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(tr('Ne yapılsın?'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<RuleAction>(
                segments: [
                  for (final a in RuleAction.values)
                    ButtonSegment(
                      value: a,
                      icon: Icon(a.icon),
                      label: Text(a.label),
                    ),
                ],
                selected: {_action},
                onSelectionChanged: (s) => setState(() => _action = s.first),
              ),
              const SizedBox(height: 8),
              Text(switch (_action) {
                RuleAction.autoReply => tr(
                  'Mesaja, geldiği uygulama üzerinden otomatik cevap verilir.',
                ),
                RuleAction.mute => tr(
                  'Mesajlar kaydedilir ama okunmamış sayılmaz.',
                ),
                RuleAction.important => tr(
                  'Sohbet, açılana kadar listenin en üstünde yıldızla durur.',
                ),
              }, style: theme.textTheme.bodySmall),
              if (_action == RuleAction.autoReply) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reply,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: tr('Yanıt metni'),
                    hintText: tr('Şu an müsait değilim, sonra yazacağım.'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? tr('Otomatik yanıt için bir metin yazın')
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _cooldown,
                  decoration: InputDecoration(
                    labelText: tr('Aynı sohbete tekrar yanıt için bekle'),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final MapEntry(key: minutes, value: label)
                        in cooldownOptions.entries)
                      DropdownMenuItem(value: minutes, child: Text(label)),
                  ],
                  onChanged: (v) => setState(() => _cooldown = v!),
                ),
              ],
              const SizedBox(height: 24),
              Text(tr('Hangi mesajlarda?'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _apps.isEmpty
                    ? tr('Uygulama seçilmedi: tüm uygulamalar')
                    : tr('Yalnızca seçilen uygulamalar'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final name in _appPackages.keys)
                    FilterChip(
                      label: Text(name),
                      selected: _apps.contains(name),
                      onSelected: (on) => setState(
                        () => on ? _apps.add(name) : _apps.remove(name),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sender,
                decoration: InputDecoration(
                  labelText: tr('Kimden (isteğe bağlı)'),
                  hintText: tr('Sohbet ya da kişi adında geçen ifade'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keywords,
                decoration: InputDecoration(
                  labelText: tr('Anahtar kelimeler (isteğe bağlı)'),
                  hintText: tr('acil, toplantı, fatura'),
                  helperText: tr(
                    'Virgülle ayırın; herhangi biri geçerse kural çalışır',
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Grup sohbetlerinde de çalışsın')),
                subtitle: _action == RuleAction.autoReply && _includeGroups
                    ? Text(tr('Gruptaki herkes otomatik yanıtı görür.'))
                    : null,
                value: _includeGroups,
                onChanged: (v) => setState(() => _includeGroups = v),
              ),
              const SizedBox(height: 16),
              Text(tr('Ne zaman?'), style: theme.textTheme.titleMedium),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('Yalnızca belirli saatlerde')),
                subtitle: _timed ? null : Text(tr('Gün boyu')),
                value: _timed,
                onChanged: (v) => setState(() => _timed = v),
              ),
              if (_timed) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(start: true),
                        child: Text(
                          tr('Başlangıç {from}', {
                            'from': formatMinutes(_from),
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(start: false),
                        child: Text(
                          tr('Bitiş {to}', {'to': formatMinutes(_to)}),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_from > _to)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr('Gece yarısını aşar: {from}–{to} (ertesi gün)', {
                        'from': formatMinutes(_from),
                        'to': formatMinutes(_to),
                      }),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i < 7; i++)
                    FilterChip(
                      label: Text(weekdayShort[i]),
                      selected: _days & (1 << i) != 0,
                      onSelected: (on) => setState(
                        () => _days = on ? _days | (1 << i) : _days & ~(1 << i),
                      ),
                    ),
                ],
              ),
              if (_action == RuleAction.autoReply && !draft.hasConditions)
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      tr(
                        'Koşul yok: bu kural her yeni mesaja yanıt verir (bekleme süresi ve saatlik sınırla).',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(tr('Kaydet')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
