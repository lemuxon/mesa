import 'package:mesaj_merkezi/l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/focus.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../ui/avatars.dart';
import '../ui/large_title.dart';

/// Odak modu: VIP kişiler, önemli mesajlar ve acil durumlar dışındaki
/// bildirimler susar; mesajlar Mesa'da birikir, odak bitince özet gelir.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  FocusStatus? _status;
  List<Conversation> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await widget.bridge.focusStatus();
    final conversations = await widget.bridge.conversations();
    if (!mounted) return;
    setState(() {
      _status = status;
      _conversations = conversations;
    });
  }

  void _apply(FocusStatus status) {
    if (mounted) setState(() => _status = status);
  }

  Future<void> _toggle(bool on) async {
    if (!on) {
      _apply(await widget.bridge.setFocusManual(0));
      return;
    }
    final option = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(tr('1 saat')),
              onTap: () => Navigator.of(context).pop('1h'),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse_rounded),
              title: Text(tr('3 saat')),
              onTap: () => Navigator.of(context).pop('3h'),
            ),
            ListTile(
              leading: const Icon(Icons.wb_twilight_rounded),
              title: Text(tr('Sabah 08:00\'e kadar')),
              onTap: () => Navigator.of(context).pop('morning'),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: Text(tr('Ben kapatana kadar')),
              onTap: () => Navigator.of(context).pop('forever'),
            ),
          ],
        ),
      ),
    );
    if (option == null) return;
    _apply(
      await widget.bridge.setFocusManual(focusUntil(option, DateTime.now())),
    );
  }

  Future<void> _setSchedule({
    bool? enabled,
    int? from,
    int? to,
    int? days,
  }) async {
    final s = _status!;
    _apply(
      await widget.bridge.setFocusSchedule(
        enabled: enabled ?? s.scheduleOn,
        from: from ?? s.scheduleFrom,
        to: to ?? s.scheduleTo,
        days: days ?? s.scheduleDays,
      ),
    );
  }

  Future<void> _pickTime(bool start) async {
    final s = _status!;
    final minutes = start ? s.scheduleFrom : s.scheduleTo;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    await (start ? _setSchedule(from: value) : _setSchedule(to: value));
  }

  Future<void> _enableUnified() async {
    final settings = await widget.bridge.settings();
    await widget.bridge.requestNotificationPermission();
    await widget.bridge.updateSettings(
      settings.copyWith(unifiedNotifications: true),
    );
    await _load();
  }

  /// Aynı kişinin bütün sohbetleri birlikte VIP olur.
  List<String> _keysOf(Conversation c) => c.personId == null
      ? [c.key]
      : [
          for (final other in _conversations)
            if (other.personId == c.personId) other.key,
        ];

  Future<void> _addVip() async {
    final vip = _status!.vip.toSet();
    final candidates = [
      for (final c in _conversations)
        if (!vip.contains(c.key)) c,
    ];
    final picked = await showModalBottomSheet<Conversation>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => candidates.isEmpty
            ? Center(child: Text(tr('Eklenecek sohbet yok.')))
            : ListView(
                controller: controller,
                children: [
                  for (final c in candidates)
                    ListTile(
                      leading: ConversationAvatar(
                        title: c.title,
                        packageName: c.packageName,
                        avatarPath: c.avatarPath,
                        size: 40,
                      ),
                      title: Text(c.personName ?? c.title),
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
      ),
    );
    if (picked == null) return;
    _apply(await widget.bridge.setFocusVip([...vip, ..._keysOf(picked)]));
  }

  Future<void> _removeVip(Conversation c) async {
    final remove = _keysOf(c).toSet();
    _apply(
      await widget.bridge.setFocusVip([
        for (final key in _status!.vip)
          if (!remove.contains(key)) key,
      ]),
    );
  }

  String _subtitle(FocusStatus s) {
    if (!s.active) return tr('Kapalı');
    if (s.indefiniteManual) return tr('Açık · siz kapatana kadar');
    final end = s.end;
    if (end == null) return tr('Açık');
    final time =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return tr('Açık · {time} saatine kadar', {'time': time});
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final theme = Theme.of(context);
    // VIP listesi kişi başına bir satır (birleştirilmiş kişinin sohbetleri tek satır).
    final vipRows = <Conversation>[];
    final seenPeople = <int>{};
    if (s != null) {
      for (final c in _conversations) {
        if (!s.vip.contains(c.key)) continue;
        if (c.personId != null && !seenPeople.add(c.personId!)) continue;
        vipRows.add(c);
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr('Odak modu'))),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                SectionCard(
                  title: tr('Odak modu'),
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        s.active
                            ? Icons.bedtime_rounded
                            : Icons.bedtime_outlined,
                      ),
                      title: Text(tr('Odak modu')),
                      subtitle: Text(_subtitle(s)),
                      value: s.active,
                      onChanged: _toggle,
                    ),
                    if (s.active && s.silenced > 0)
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_paused_outlined,
                        ),
                        title: Text(
                          tr(
                            '{count, plural, one{# mesaj susturuldu} other{# mesaj susturuldu}}',
                            {'count': s.silenced},
                          ),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      subtitle: Text(
                        tr(
                          'Odaktayken yalnızca VIP kişiler, "Önemli işaretle" kuralına uyan mesajlar ve acil durumlar bildirim verir. Diğer mesajlar Mesa\'da sessizce birikir; odak bitince kısa bir özet gelir.',
                        ),
                      ),
                    ),
                    if (!s.unified)
                      ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          tr(
                            'Birleşik bildirimler kapalı: WhatsApp gibi uygulamaların kendi bildirimleri yine ses çıkarabilir. Odak modunun her şeyi susturması için birleşik bildirimleri açın.',
                          ),
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: _enableUnified,
                          child: Text(tr('Aç')),
                        ),
                      ),
                  ],
                ),
                SectionCard(
                  title: tr('Zamanlama'),
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.schedule_rounded),
                      title: Text(tr('Her gün belirli saatlerde')),
                      subtitle: Text(
                        '${formatMinutes(s.scheduleFrom)} – ${formatMinutes(s.scheduleTo)}',
                      ),
                      value: s.scheduleOn,
                      onChanged: (v) => _setSchedule(enabled: v),
                    ),
                    if (s.scheduleOn) ...[
                      ListTile(
                        leading: const Icon(Icons.play_circle_outline_rounded),
                        title: Text(tr('Başlangıç')),
                        trailing: Text(formatMinutes(s.scheduleFrom)),
                        onTap: () => _pickTime(true),
                      ),
                      ListTile(
                        leading: const Icon(Icons.stop_circle_outlined),
                        title: Text(tr('Bitiş')),
                        trailing: Text(formatMinutes(s.scheduleTo)),
                        onTap: () => _pickTime(false),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (var i = 0; i < 7; i++)
                              FilterChip(
                                label: Text(weekdayShort[i]),
                                selected: s.scheduleDays & (1 << i) != 0,
                                onSelected: (on) => _setSchedule(
                                  days: on
                                      ? s.scheduleDays | (1 << i)
                                      : s.scheduleDays & ~(1 << i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SectionCard(
                  title: tr('VIP kişiler'),
                  children: [
                    if (vipRows.isEmpty)
                      ListTile(
                        leading: const Icon(Icons.star_outline_rounded),
                        subtitle: Text(
                          tr(
                            'VIP kişiler odaktayken de size ulaşır: aile, yakın arkadaşlar, iş için önemli biri.',
                          ),
                        ),
                      ),
                    for (final c in vipRows)
                      ListTile(
                        leading: ConversationAvatar(
                          title: c.title,
                          packageName: c.packageName,
                          avatarPath: c.avatarPath,
                          size: 40,
                        ),
                        title: Text(c.personName ?? c.title),
                        trailing: IconButton(
                          tooltip: tr('Çıkar'),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: () => _removeVip(c),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_rounded),
                      title: Text(tr('VIP ekle')),
                      onTap: _addVip,
                    ),
                  ],
                ),
                SectionCard(
                  title: tr('Acil durum'),
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.priority_high_rounded),
                      title: Text(tr('Israrla yazana izin ver')),
                      subtitle: Text(
                        tr(
                          'Aynı kişi 5 dakika içinde 3 kez yazarsa bildirim gelir.',
                        ),
                      ),
                      value: s.breakthrough,
                      onChanged: (v) async =>
                          _apply(await widget.bridge.setFocusBreakthrough(v)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Text(
                    tr(
                      'Bildirim panelindeki "Odak modu" kutucuğuyla da tek dokunuşla açıp kapatabilirsiniz.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
