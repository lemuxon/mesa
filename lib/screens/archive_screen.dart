import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/models.dart';
import 'chat_screen.dart';
import 'conversation_widgets.dart';

/// Arşivlenmiş sohbetler. Uzun basınca arşivden çıkarılabilir.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Conversation>? _conversations;
  StreamSubscription<String>? _changes;

  @override
  void initState() {
    super.initState();
    _changes = widget.bridge.changes.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final conversations = await widget.bridge.conversations(archived: true);
    if (mounted) setState(() => _conversations = conversations);
  }

  Future<void> _open(Conversation c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(bridge: widget.bridge, conversation: c),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _conversations;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Arşiv'))),
      body: switch (conversations) {
        null => const Center(child: CircularProgressIndicator()),
        [] => Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              tr(
                'Arşivde sohbet yok.\nGelen kutusunda bir sohbete uzun basıp "Arşivle"yi seçebilirsiniz.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, i) => ConversationTile(
            conversation: conversations[i],
            onTap: () => _open(conversations[i]),
            onLongPress: () async {
              final changed = await showConversationActions(
                context,
                widget.bridge,
                conversations[i],
              );
              if (changed) await _load();
            },
          ),
        ),
      },
    );
  }
}
