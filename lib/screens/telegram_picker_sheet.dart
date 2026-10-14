import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/telegram.dart';

/// Telegram sohbetinde çıkartma ya da GIF seçip gönderen alt panel.
/// Seçim gönderilince panel kapanır.
class TelegramPickerSheet extends StatefulWidget {
  const TelegramPickerSheet({
    super.key,
    required this.bridge,
    required this.conversationKey,
  });

  final CoreBridge bridge;
  final String conversationKey;

  @override
  State<TelegramPickerSheet> createState() => _TelegramPickerSheetState();
}

class _TelegramPickerSheetState extends State<TelegramPickerSheet>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  final _query = TextEditingController();
  Timer? _debounce;

  List<StickerSetInfo>? _sets;
  String? _setId;
  List<PickItem>? _stickers;
  List<PickItem>? _gifs;

  /// Arama yazılırken eski isteklerin sonucu yenisinin üstüne yazmasın.
  int _gifRequest = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadSets();
    _loadGifs('');
  }

  @override
  void dispose() {
    _tabs.dispose();
    _query.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSets() async {
    final sets = await widget.bridge.telegramStickerSets();
    if (!mounted) return;
    setState(() => _sets = sets);
    if (sets.isNotEmpty) await _selectSet(sets.first.id);
  }

  Future<void> _selectSet(String id) async {
    setState(() {
      _setId = id;
      _stickers = null;
    });
    final stickers = await widget.bridge.telegramStickers(id);
    if (mounted && _setId == id) setState(() => _stickers = stickers);
  }

  Future<void> _loadGifs(String query) async {
    final request = ++_gifRequest;
    setState(() => _gifs = null);
    final gifs = await widget.bridge.telegramGifs(
      widget.conversationKey,
      query,
    );
    if (mounted && request == _gifRequest) setState(() => _gifs = gifs);
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _loadGifs(query),
    );
  }

  Future<void> _send(PickItem item) async {
    if (_sending) return;
    setState(() => _sending = true);
    final sent = await widget.bridge.telegramSendPick(
      widget.conversationKey,
      item.token,
    );
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _sending = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr('Gönderilemedi.'))));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          children: [
            TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: tr('Çıkartmalar')),
                Tab(text: 'GIF'),
              ],
            ),
            if (_sending) const LinearProgressIndicator(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [_stickerTab(), _gifTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stickerTab() {
    final sets = _sets;
    if (sets == null) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              for (final set in sets)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: set.thumbPath == null
                        ? null
                        : Image.file(
                            File(set.thumbPath!),
                            cacheWidth: 72,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                    label: Text(set.title),
                    selected: set.id == _setId,
                    onSelected: (_) => _selectSet(set.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _grid(
            _stickers,
            maxExtent: 88,
            empty: tr('Bu bölümde çıkartma yok.'),
          ),
        ),
      ],
    );
  }

  Widget _gifTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _query,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: tr('GIF ara (boşsa kaydedilenler)'),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: _grid(
            _gifs,
            maxExtent: 130,
            empty: _query.text.trim().isEmpty
                ? tr('Kaydedilmiş GIF yok. Yukarıdan arayabilirsiniz.')
                : tr('GIF bulunamadı.'),
          ),
        ),
      ],
    );
  }

  Widget _grid(
    List<PickItem>? items, {
    required double maxExtent,
    required String empty,
  }) {
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => InkWell(
        onTap: () => _send(items[i]),
        borderRadius: BorderRadius.circular(8),
        child: PickThumb(item: items[i]),
      ),
    );
  }
}

/// Önizleme: indirilmiş dosya, yoksa gömülü bulanık resim, o da yoksa emoji.
class PickThumb extends StatelessWidget {
  const PickThumb({super.key, required this.item});

  final PickItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(item.emoji ?? 'GIF', style: const TextStyle(fontSize: 28)),
    );
    if (item.thumbPath case final path?) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        cacheWidth: 256,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (item.miniThumb case final bytes?) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}
