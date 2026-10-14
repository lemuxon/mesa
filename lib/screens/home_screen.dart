import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/presence.dart';
import '../core/web_services.dart';
import '../ui/avatars.dart';
import 'inbox_screen.dart';
import 'rules_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';

/// Alt sekmeler: Sohbetler, Servisler, Kurallar, Ayarlar. Sekmeler arası
/// geçişte her sekmenin durumu (kaydırma, filtre) korunur.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bridge, required this.web});

  final CoreBridge bridge;
  final WebBridge web;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  /// Ayarlar sekmesine her gelişte güncel ayarlar yeniden okunsun.
  int _settingsVisits = 0;

  static const _settingsTab = 3;

  /// Web servislerindeki toplam okunmamış (sekme rozeti; -1: sayısız okunmamış).
  int _webUnread = 0;
  StreamSubscription<void>? _webChanges;

  @override
  void initState() {
    super.initState();
    _webChanges = widget.web.changes.listen((_) => _loadWebUnread());
    PresenceHub.instance.attach(widget.bridge);
    _loadWebUnread();
  }

  @override
  void dispose() {
    _webChanges?.cancel();
    super.dispose();
  }

  Future<void> _loadWebUnread() async {
    final services = await widget.web.services();
    if (!mounted) return;
    // Sohbetler'deki web sohbetlerinin rozetleri de güncel simgeyi göstersin.
    for (final s in services) {
      AppIcons.refreshIfChanged(s.packageName, s.iconVersion);
    }
    final total = services
        .where((s) => s.unread > 0)
        .fold<int>(0, (sum, s) => sum + s.unread);
    final dot = services.any((s) => s.unread == WebService.unreadDot);
    setState(() => _webUnread = total > 0 ? total : (dot ? -1 : 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          InboxScreen(bridge: widget.bridge, web: widget.web),
          ServicesScreen(
            bridge: widget.web,
            inboxChanges: widget.bridge.changes,
          ),
          RulesScreen(bridge: widget.bridge),
          SettingsScreen(key: ValueKey(_settingsVisits), bridge: widget.bridge),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          if (i == _settingsTab && _tab != _settingsTab) _settingsVisits++;
          _tab = i;
        }),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: tr('Sohbetler'),
          ),
          NavigationDestination(
            icon: _webBadge(const Icon(Icons.apps_outlined)),
            selectedIcon: _webBadge(const Icon(Icons.apps_rounded)),
            label: tr('Servisler'),
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_mode_outlined),
            selectedIcon: Icon(Icons.auto_mode_rounded),
            label: tr('Kurallar'),
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: tr('Ayarlar'),
          ),
        ],
      ),
    );
  }

  Widget _webBadge(Widget icon) => Badge(
    isLabelVisible: _webUnread != 0,
    label: _webUnread > 0
        ? Text(_webUnread > 99 ? '99+' : '$_webUnread')
        : null,
    child: icon,
  );
}
