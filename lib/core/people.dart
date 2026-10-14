import 'models.dart';

/// Gelen kutusunda bir satır: tek sohbet ya da aynı kişinin farklı
/// uygulamalardaki sohbetleri.
class InboxEntry {
  InboxEntry.single(Conversation c) : personId = null, members = [c];

  InboxEntry.person(int this.personId, this.members)
    : assert(members.length > 1);

  final int? personId;

  /// En son yazışılan önce.
  final List<Conversation> members;

  bool get isPerson => members.length > 1;

  Conversation get latest => members.first;

  /// Üyelerin uygulamaları (en son yazışılan önce, tekrarsız).
  List<String> get packages =>
      <String>{for (final m in members) m.packageName}.toList();

  /// Satırda gösterilen özet: kişinin adı, en son mesajı, toplam okunmamış.
  Conversation get summary {
    if (!isPerson) return latest;
    return Conversation(
      key: 'person:$personId',
      packageName: latest.packageName,
      title: latest.personName ?? latest.title,
      isGroup: false,
      lastText: latest.lastText,
      lastTime: latest.lastTime,
      unread: members.fold(0, (n, m) => n + m.unread),
      important: members.any((m) => m.important),
      pinned: members.any((m) => m.pinned),
      archived: latest.archived,
      avatarPath: members
          .map((m) => m.avatarPath)
          .whereType<String>()
          .firstOrNull,
      canReply: members.any((m) => m.canReply),
      reminded: members.any((m) => m.reminded),
      personId: personId,
      personName: latest.personName,
    );
  }
}

/// Sohbetleri kişilere göre toplar. Sıra korunur: kişi, ilk üyesinin
/// (sabit / hatırlatılan / önemli / en yeni) yerinde durur.
List<InboxEntry> groupByPerson(List<Conversation> conversations) {
  final byPerson = <int, List<Conversation>>{};
  for (final c in conversations) {
    final id = c.personId;
    if (id != null) (byPerson[id] ??= []).add(c);
  }
  final entries = <InboxEntry>[];
  final placed = <int>{};
  for (final c in conversations) {
    final id = c.personId;
    final members = id == null ? null : byPerson[id];
    if (id == null || members == null || members.length < 2) {
      entries.add(InboxEntry.single(c));
      continue;
    }
    if (!placed.add(id)) continue;
    entries.add(
      InboxEntry.person(
        id,
        [...members]..sort((a, b) => b.lastTime.compareTo(a.lastTime)),
      ),
    );
  }
  return entries;
}

/// Kişi ekranında yanıtın varsayılan uygulaması: en son yazışılan.
Conversation preferredMember(List<Conversation> members) =>
    members.reduce((a, b) => b.lastTime.isAfter(a.lastTime) ? b : a);

const _fold = {
  'ı': 'i',
  'İ': 'i',
  'I': 'i',
  'ğ': 'g',
  'Ğ': 'g',
  'ş': 's',
  'Ş': 's',
  'ç': 'c',
  'Ç': 'c',
  'ö': 'o',
  'Ö': 'o',
  'ü': 'u',
  'Ü': 'u',
};

final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Ad karşılaştırma biçimi (yerel taraftaki PersonMatcher.nameKey ile aynı
/// kural): "Yağız Arda" = "yagiz.arda".
String nameKey(String title) {
  final out = StringBuffer();
  for (final rune in title.runes) {
    final ch = String.fromCharCode(rune);
    final folded = _fold[ch] ?? ch.toLowerCase();
    if (_letterOrDigit.hasMatch(folded)) out.write(folded);
  }
  return out.toString();
}

/// Birleştirilen kişiye verilecek ad: gerçek ada benzeyen başlık
/// ("Yağız Arda", "yagiz.arda" değil).
String personNameFor(Conversation a, Conversation b) {
  final existing = a.personName ?? b.personName;
  if (existing != null) return existing;
  bool looksLikeName(String t) =>
      t.contains(' ') && !t.contains(RegExp(r'[._@]'));
  if (looksLikeName(a.title)) return a.title;
  if (looksLikeName(b.title)) return b.title;
  return a.title;
}
