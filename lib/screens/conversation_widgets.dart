import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'engagement.dart';
import '../ui/bidi.dart';
import '../l10n/stored_labels.dart';
import '../core/presence.dart';
import '../ui/theme.dart';
import '../core/apps.dart';
import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/people.dart';
import '../ui/avatars.dart';
import '../ui/text_dialog.dart';

/// Gelen kutusu ve arşivde bir sohbet satırı.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
    this.members = const [],
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Kişi satırı: kişinin sohbetleri (uygulama simgeleri ve "yazıyor…" için).
  final List<Conversation> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = conversation.unread > 0;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ConversationAvatar(
              title: conversation.title,
              packageName: conversation.packageName,
              avatarPath: conversation.avatarPath,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversation.title,
                                textDirection: textDirectionOf(
                                  conversation.title,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            // Kişi: hangi uygulamalarda yazışıldığı.
                            if (members.length > 1)
                              for (final pkg in <String>{
                                for (final m in members) m.packageName,
                              }.take(4))
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: AppIcon(packageName: pkg, size: 15),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatListTime(conversation.lastTime, DateTime.now()),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: unread ? scheme.primary : scheme.outline,
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        // Telegram'da karşı taraf yazarken son mesaj yerine "yazıyor…".
                        child:
                            ValueListenableBuilder<Map<String, PresenceState>>(
                              valueListenable: PresenceHub.instance,
                              builder: (context, presence, _) {
                                final typing =
                                    [
                                          if (members.isEmpty) conversation,
                                          ...members,
                                        ]
                                        .map((m) => presence[m.key]?.typing)
                                        .whereType<String>()
                                        .firstOrNull;
                                return Text(
                                  typing ??
                                      localizeStored(conversation.lastText),
                                  textDirection: typing != null
                                      ? null
                                      : textDirectionOf(conversation.lastText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: typing != null
                                        ? AppTheme.online
                                        : unread
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                    fontWeight: typing != null
                                        ? FontWeight.w600
                                        : null,
                                  ),
                                );
                              },
                            ),
                      ),
                      if (conversation.reminded)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.alarm_rounded,
                            size: 17,
                            color: AppTheme.brandEnd,
                            semanticLabel: tr('Hatırlatma'),
                          ),
                        ),
                      if (conversation.pinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: scheme.outline,
                            semanticLabel: tr('Sabitlendi'),
                          ),
                        ),
                      if (conversation.important)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber.shade700,
                            semanticLabel: tr('Önemli'),
                          ),
                        ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(minWidth: 22),
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            conversation.unread > 99
                                ? '99+'
                                : '${conversation.unread}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ConversationAction {
  snooze,
  pin,
  archive,
  merge,
  unmerge,
  openInApp,
  delete,
}

/// Uzun basınca açılan işlem menüsü. Sohbette değişiklik yapıldıysa true.
/// [others]: "Kişiyle birleştir" için seçilebilecek diğer sohbetler.
Future<bool> showConversationActions(
  BuildContext context,
  CoreBridge bridge,
  Conversation c, {
  List<Conversation> others = const [],
}) async {
  final mergeable = c.isGroup
      ? const <Conversation>[]
      : _mergeCandidates(c, others);
  final app = MessagingApp.of(c.packageName);
  final action = await showModalBottomSheet<_ConversationAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Küçük ekranda eylemler sığmazsa kaydırılır.
    builder: (context) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ConversationAvatar(
              title: c.title,
              packageName: c.packageName,
              avatarPath: c.avatarPath,
              size: 40,
            ),
            title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(app.name),
          ),
          const Divider(height: 8),
          ListTile(
            leading: Icon(c.pinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(c.pinned ? tr('Sabitlemeyi kaldır') : tr('Sabitle')),
            onTap: () => Navigator.of(context).pop(_ConversationAction.pin),
          ),
          ListTile(
            leading: const Icon(Icons.alarm_rounded),
            title: Text(tr('Sonra hatırlat')),
            onTap: () => Navigator.of(context).pop(_ConversationAction.snooze),
          ),
          ListTile(
            leading: Icon(
              c.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            title: Text(c.archived ? tr('Arşivden çıkar') : tr('Arşivle')),
            onTap: () => Navigator.of(context).pop(_ConversationAction.archive),
          ),
          if (mergeable.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(tr('Kişiyle birleştir')),
              subtitle: Text(
                tr('Aynı kişinin başka uygulamadaki sohbetiyle tek yerde'),
              ),
              onTap: () => Navigator.of(context).pop(_ConversationAction.merge),
            ),
          if (c.personId != null)
            ListTile(
              leading: const Icon(Icons.call_split_rounded),
              title: Text(
                tr('{name} kişisinden ayır', {
                  'name': c.personName ?? tr('Kişi'),
                }),
              ),
              onTap: () =>
                  Navigator.of(context).pop(_ConversationAction.unmerge),
            ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(tr('{name} uygulamasında aç', {'name': app.name})),
            onTap: () =>
                Navigator.of(context).pop(_ConversationAction.openInApp),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              tr('Sil'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.of(context).pop(_ConversationAction.delete),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return false;
  switch (action) {
    case null:
      return false;
    case _ConversationAction.pin:
      await bridge.setPinned(c.key, !c.pinned);
      return true;
    case _ConversationAction.archive:
      await bridge.setArchived(c.key, !c.archived);
      return true;
    case _ConversationAction.snooze:
      final at = await pickLaterTime(
        context,
        title: tr('Ne zaman hatırlatılsın?'),
      );
      if (at == null) return false;
      await bridge.snooze(c.key, at);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('⏰ {when} hatırlatılacak', {
                'when': formatWhen(at, DateTime.now()),
              }),
            ),
          ),
        );
      }
      return true;
    case _ConversationAction.merge:
      final target = await _pickMergeTarget(context, c, mergeable);
      if (target == null) return false;
      await bridge.mergePeople([
        c.key,
        target.key,
      ], name: personNameFor(c, target));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('{target}: {name} ve {name2} sohbetleri birleşti', {
                'target': personNameFor(c, target),
                'name': MessagingApp.of(c.packageName).name,
                'name2': MessagingApp.of(target.packageName).name,
              }),
            ),
          ),
        );
      }
      return true;
    case _ConversationAction.unmerge:
      await bridge.unmergePerson(c.key);
      return true;
    case _ConversationAction.openInApp:
      await bridge.openInSourceApp(c);
      return false;
    case _ConversationAction.delete:
      return _confirmDelete(context, bridge, c);
  }
}

Future<bool> _confirmDelete(
  BuildContext context,
  CoreBridge bridge,
  Conversation c,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('"{title}" silinsin mi?', {'title': c.title})),
      content: Text(
        tr(
          'Sohbet ve mesajları yalnızca Mesa\'dan silinir; {name} uygulamasındaki sohbete dokunulmaz.',
          {'name': MessagingApp.of(c.packageName).name},
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
  if (!(confirmed ?? false)) return false;
  await bridge.deleteConversation(c.key);
  return true;
}

/// Birleştirilebilecek sohbetler: grup olmayan, aynı kişide olmayan;
/// adı benzeyenler önce, sonra en yeni.
List<Conversation> _mergeCandidates(Conversation c, List<Conversation> all) {
  final name = nameKey(c.title);
  final list = all
      .where(
        (o) =>
            o.key != c.key &&
            !o.isGroup &&
            (c.personId == null || o.personId != c.personId),
      )
      .toList();
  int score(Conversation o) => nameKey(o.title) == name ? 0 : 1;
  list.sort((a, b) {
    final s = score(a).compareTo(score(b));
    return s != 0 ? s : b.lastTime.compareTo(a.lastTime);
  });
  return list;
}

/// Birleştirilecek sohbeti seçtirir (aramalı liste).
Future<Conversation?> _pickMergeTarget(
  BuildContext context,
  Conversation c,
  List<Conversation> candidates,
) => showModalBottomSheet<Conversation>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _MergePicker(conversation: c, candidates: candidates),
);

class _MergePicker extends StatefulWidget {
  const _MergePicker({required this.conversation, required this.candidates});

  final Conversation conversation;
  final List<Conversation> candidates;

  @override
  State<_MergePicker> createState() => _MergePickerState();
}

class _MergePickerState extends State<_MergePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = nameKey(_query);
    final shown = query.isEmpty
        ? widget.candidates
        : widget.candidates
              .where((o) => nameKey(o.title).contains(query))
              .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              tr('{title} ile birleştir', {'title': widget.conversation.title}),
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              tr(
                'Aynı kişinin başka uygulamadaki sohbetini seçin. Mesajlar tek yerde görünür; istediğiniz zaman ayırabilirsiniz.',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: tr('Ara'),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final o = shown[i];
                final app = MessagingApp.of(o.packageName).name;
                return ListTile(
                  leading: ConversationAvatar(
                    title: o.title,
                    packageName: o.packageName,
                    avatarPath: o.avatarPath,
                    size: 40,
                  ),
                  title: Text(
                    o.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    o.personName == null ? app : '$app · ${o.personName}',
                  ),
                  onTap: () => Navigator.of(context).pop(o),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _PersonAction { rename, pin, snooze, archive }

/// Kişi satırına uzun basınca: ad, sabitleme, hatırlatma, arşiv ve
/// sohbetleri ayırma. Değişiklik yapıldıysa true.
Future<bool> showPersonActions(
  BuildContext context,
  CoreBridge bridge,
  InboxEntry person,
) async {
  final summary = person.summary;
  final name = summary.title;
  final result = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ConversationAvatar(
              title: name,
              packageName: summary.packageName,
              avatarPath: summary.avatarPath,
              size: 40,
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              person.packages.map((p) => MessagingApp.of(p).name).join(' · '),
            ),
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(tr('Adını değiştir')),
            onTap: () => Navigator.of(context).pop(_PersonAction.rename),
          ),
          ListTile(
            leading: Icon(
              summary.pinned ? Icons.push_pin_outlined : Icons.push_pin,
            ),
            title: Text(
              summary.pinned ? tr('Sabitlemeyi kaldır') : tr('Sabitle'),
            ),
            onTap: () => Navigator.of(context).pop(_PersonAction.pin),
          ),
          ListTile(
            leading: const Icon(Icons.alarm_rounded),
            title: Text(tr('Sonra hatırlat')),
            onTap: () => Navigator.of(context).pop(_PersonAction.snooze),
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(tr('Arşivle')),
            onTap: () => Navigator.of(context).pop(_PersonAction.archive),
          ),
          const Divider(height: 8),
          for (final m in person.members)
            ListTile(
              leading: AppIcon(packageName: m.packageName, size: 24),
              title: Text(
                tr('{name} sohbetini ayır', {
                  'name': MessagingApp.of(m.packageName).name,
                }),
              ),
              subtitle: Text(
                m.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(m),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted) return false;
  final keys = [for (final m in person.members) m.key];
  switch (result) {
    case Conversation member:
      await bridge.unmergePerson(member.key);
      return true;
    case _PersonAction.rename:
      final id = person.personId;
      if (id == null) return false;
      final text = await showTextDialog(
        context,
        title: tr('Kişinin adı'),
        confirmLabel: tr('Kaydet'),
        initial: name,
      );
      if (text == null || text.isEmpty) return false;
      await bridge.renamePerson(id, text);
      return true;
    case _PersonAction.pin:
      for (final key in keys) {
        await bridge.setPinned(key, !summary.pinned);
      }
      return true;
    case _PersonAction.archive:
      for (final key in keys) {
        await bridge.setArchived(key, true);
      }
      return true;
    case _PersonAction.snooze:
      final at = await pickLaterTime(
        context,
        title: tr('Ne zaman hatırlatılsın?'),
      );
      if (at == null) return false;
      for (final key in keys) {
        await bridge.snooze(key, at);
      }
      return true;
    default:
      return false;
  }
}
