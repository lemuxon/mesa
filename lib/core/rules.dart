import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Kotlin'deki RuleAction ile aynı adlar ([wire]) kullanılır.
enum RuleAction {
  autoReply('AUTO_REPLY', Icons.reply),
  mute('MUTE', Icons.notifications_off_outlined),
  important('IMPORTANT', Icons.star_outline);

  const RuleAction(this.wire, this.icon);

  final String wire;

  /// Seçili dilde (enum sabit olduğundan getter).
  String get label => switch (this) {
    autoReply => tr('Otomatik yanıt'),
    mute => tr('Sessize al'),
    important => tr('Önemli işaretle'),
  };
  final IconData icon;

  static RuleAction fromWire(String wire) =>
      values.firstWhere((a) => a.wire == wire);
}

/// Otomatik yanıtlar arası bekleme süresi seçenekleri (dakika → etiket).
Map<int, String> get cooldownOptions => {
  15: tr('15 dakika'),
  60: tr('1 saat'),
  360: tr('6 saat'),
  1440: tr('1 gün'),
};

/// Yeni mesaj geldiğinde (uygulama kapalıyken de) yerel servis tarafından
/// değerlendirilen kural. Eşleştirme mantığı android/.../RuleEngine.kt'de.
class Rule {
  const Rule({
    this.id,
    required this.name,
    this.enabled = true,
    this.packages = const {},
    this.keywords = const [],
    this.senderContains = '',
    this.includeGroups = false,
    required this.action,
    this.replyText = '',
    this.cooldownMinutes = 60,
    this.activeFrom,
    this.activeTo,
    this.activeDays = allDays,
    this.recentFires = 0,
  });

  /// Pazartesi (bit 0) … pazar (bit 6): hepsi seçili.
  static const allDays = 0x7f;

  factory Rule.fromMap(Map<Object?, Object?> m) => Rule(
    id: m['id']! as int,
    name: m['name']! as String,
    enabled: m['enabled']! as bool,
    packages: (m['packages']! as List<Object?>).cast<String>().toSet(),
    keywords: (m['keywords']! as List<Object?>).cast<String>(),
    senderContains: m['senderContains']! as String,
    includeGroups: m['includeGroups']! as bool,
    action: RuleAction.fromWire(m['action']! as String),
    replyText: m['replyText']! as String,
    cooldownMinutes: m['cooldownMinutes']! as int,
    activeFrom: m['activeFrom'] as int?,
    activeTo: m['activeTo'] as int?,
    activeDays: m['activeDays'] as int? ?? allDays,
    recentFires: m['recentFires'] as int? ?? 0,
  );

  /// Yeni kuralda null.
  final int? id;
  final String name;
  final bool enabled;

  /// Boşsa tüm uygulamalar.
  final Set<String> packages;

  /// Herhangi biri geçerse eşleşir; boşsa her mesaj.
  final List<String> keywords;

  /// Sohbet ya da gönderen adında geçmeli; boşsa herkes.
  final String senderContains;
  final bool includeGroups;
  final RuleAction action;
  final String replyText;
  final int cooldownMinutes;

  /// Etkin saat aralığı (gece yarısından dakika); ikisi de null ise gün boyu.
  /// Başlangıç bitişten büyükse gece yarısını aşar (23:00–08:00).
  final int? activeFrom;
  final int? activeTo;

  /// Etkin günler: bit 0 pazartesi … bit 6 pazar.
  final int activeDays;

  bool get hasTimeWindow => activeFrom != null && activeTo != null;

  /// Son 7 günde kaç kez çalıştı (yalnızca okunur).
  final int recentFires;

  bool get hasConditions =>
      packages.isNotEmpty || keywords.isNotEmpty || senderContains.isNotEmpty;

  Rule withEnabled(bool value) => Rule(
    id: id,
    name: name,
    enabled: value,
    packages: packages,
    keywords: keywords,
    senderContains: senderContains,
    includeGroups: includeGroups,
    action: action,
    replyText: replyText,
    cooldownMinutes: cooldownMinutes,
    activeFrom: activeFrom,
    activeTo: activeTo,
    activeDays: activeDays,
    recentFires: recentFires,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'packages': packages.toList(),
    'keywords': keywords,
    'senderContains': senderContains,
    'includeGroups': includeGroups,
    'action': action.wire,
    'replyText': replyText,
    'cooldownMinutes': cooldownMinutes,
    'activeFrom': activeFrom,
    'activeTo': activeTo,
    'activeDays': activeDays,
  };
}

List<String> get weekdayShort => [
  tr('Pzt'),
  tr('Sal'),
  tr('Çar'),
  tr('Per'),
  tr('Cum'),
  tr('Cmt'),
  tr('Paz'),
];

/// 540 → "09:00"
String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// Kuralın etkin olduğu zamanın özeti; her zaman etkinse null.
String? describeSchedule(Rule rule) {
  final days = rule.activeDays & Rule.allDays;
  final dayText = switch (days) {
    Rule.allDays => null,
    0x1f => tr('hafta içi'),
    0x60 => tr('hafta sonu'),
    _ => [
      for (var i = 0; i < 7; i++)
        if (days & (1 << i) != 0) weekdayShort[i],
    ].join(', '),
  };
  final timeText = rule.hasTimeWindow
      ? '${formatMinutes(rule.activeFrom!)}–${formatMinutes(rule.activeTo!)}'
      : null;
  if (dayText == null && timeText == null) return null;
  return [?dayText, ?timeText].join(' ');
}

/// "acil, toplantı ,  , Acil" → ["acil", "toplantı"]. Tekrarlar (büyük/küçük
/// harf duyarsız) atılır, ilk yazılış korunur.
List<String> parseKeywords(String input) {
  final seen = <String>{};
  return [
    for (final raw in input.split(','))
      if (raw.trim() case final k
          when k.isNotEmpty && seen.add(k.toLowerCase()))
        k,
  ];
}

/// Kural listesinde gösterilen tek satırlık koşul özeti.
String describeConditions(Rule rule, String Function(String package) appName) {
  final parts = <String>[
    if (rule.packages.isEmpty)
      tr('Tüm uygulamalar')
    else
      ({for (final p in rule.packages) appName(p)}.toList()..sort()).join(', '),
    if (rule.senderContains.isNotEmpty)
      tr('Kimden: "{sender}"', {'sender': rule.senderContains}),
    if (rule.keywords.isNotEmpty)
      tr('İçerik: {words}', {'words': rule.keywords.join(', ')}),
    if (rule.includeGroups) tr('gruplar dahil'),
    ?describeSchedule(rule),
  ];
  return parts.join(' · ');
}
