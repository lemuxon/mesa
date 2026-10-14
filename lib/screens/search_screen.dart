import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/stored_labels.dart';
import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import 'chat_screen.dart';
import '../ui/avatars.dart';

/// Tüm uygulamalardaki mesajlarda arama.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<SearchHit>? _hits;

  /// Yazarken eski isteğin sonucu yenisinin üstüne yazmasın.
  int _request = 0;

  @override
  void dispose() {
    _query.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(text));
  }

  Future<void> _search(String text) async {
    final request = ++_request;
    if (text.trim().length < 2) {
      setState(() => _hits = null);
      return;
    }
    final hits = await widget.bridge.search(text);
    if (mounted && request == _request) setState(() => _hits = hits);
  }

  Future<void> _open(SearchHit hit) async {
    // Sohbetin güncel hali (grup mu, yanıt verilebilir mi) gelen kutusu ya da arşivden.
    final all = [
      ...await widget.bridge.conversations(),
      ...await widget.bridge.conversations(archived: true),
    ];
    final conversation = all.where((c) => c.key == hit.key).firstOrNull;
    if (!mounted || conversation == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatScreen(bridge: widget.bridge, conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: tr('Mesajlarda ara'),
            border: InputBorder.none,
          ),
        ),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final hits = _hits;
    if (hits == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            tr('Bütün uygulamalardaki mesajlarda arar. En az iki harf yazın.'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (hits.isEmpty) {
      return Center(child: Text(tr('Sonuç bulunamadı.')));
    }
    final now = DateTime.now();
    return ListView.builder(
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        final who = hit.outgoing ? tr('Siz') : hit.sender;
        return ListTile(
          onTap: () => _open(hit),
          leading: ConversationAvatar(
            title: hit.title,
            packageName: hit.packageName,
            size: 44,
          ),
          title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            who == null || who == hit.title
                ? localizeStored(hit.text)
                : '$who: ${localizeStored(hit.text)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            formatListTime(hit.time, now),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}
