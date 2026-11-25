import 'package:mesaj_merkezi/l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/models.dart';
import '../core/open_conversation.dart';
import 'chat_screen.dart';

/// Sohbet balonunun içi: bildirimdeki sohbet (BubbleActivity'nin niyetinden).
class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _BubbleScreenState extends State<BubbleScreen> {
  ({Conversation conversation, List<Conversation> members})? _loaded;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await widget.bridge.takeLaunchConversation();
    final loaded = key == null
        ? null
        : await loadConversation(widget.bridge, key);
    if (!mounted) return;
    setState(() {
      _loaded = loaded;
      _missing = loaded == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _loaded;
    if (loaded != null) {
      return ChatScreen(
        bridge: widget.bridge,
        conversation: loaded.conversation,
        members: loaded.members,
      );
    }
    return Scaffold(
      body: Center(
        child: _missing
            ? Text(tr('Sohbet bulunamadı.'))
            : const CircularProgressIndicator(),
      ),
    );
  }
}
