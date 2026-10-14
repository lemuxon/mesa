import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/bridge.dart';
import '../core/telegram.dart';

/// Telegram hesabını TDLib ile bağlama: giriş adımları ve bağlantı durumu.
class TelegramScreen extends StatefulWidget {
  const TelegramScreen({super.key, required this.bridge});

  final CoreBridge bridge;

  @override
  State<TelegramScreen> createState() => _TelegramScreenState();
}

class _TelegramScreenState extends State<TelegramScreen> {
  TelegramStatus? _status;
  StreamSubscription<TelegramStatus>? _changes;
  final _input = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _changes = widget.bridge.telegramChanges.listen(_apply);
    widget.bridge.telegramStatus().then(_apply);
  }

  @override
  void dispose() {
    _changes?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _apply(TelegramStatus status) {
    if (!mounted) return;
    setState(() {
      // Yeni adıma geçildi: önceki adımın girdisi ve hatası temizlenir.
      if (status.state != _status?.state) {
        _input.clear();
        _error = null;
      }
      _status = status;
    });
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    await widget.bridge.telegramConnect();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _submit(TelegramState state) async {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.bridge.telegramSubmit(state, value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Telegram bağlantısı kapatılsın mı?')),
        content: Text(
          tr(
            'Bu cihazın oturumu Telegram\'dan çıkarılır. Daha önce alınan mesajlar Mesa\'da kalır.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Çıkış yap')),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    setState(() => _busy = true);
    final error = await widget.bridge.telegramLogout();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Telegram bağlantısı'))),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _content(context, status),
            ),
    );
  }

  List<Widget> _content(BuildContext context, TelegramStatus status) {
    final theme = Theme.of(context);
    if (!status.configured) {
      return [
        _InfoCard(
          icon: Icons.build_outlined,
          text: tr(
            'Bu derlemede Telegram uygulama kimliği yok. my.telegram.org → "API development tools" bölümünden api_id ve api_hash alınıp android/local.properties dosyasına telegram.apiId ve telegram.apiHash olarak yazılmalı, ardından uygulama yeniden derlenmeli.',
          ),
        ),
      ];
    }

    final state = status.state;
    if (state.needsInput) {
      return [
        Text(_stepTitle(state), style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (status.hint != null) Text(status.hint!),
        const SizedBox(height: 16),
        TextField(
          controller: _input,
          autofocus: true,
          obscureText: state == TelegramState.waitPassword,
          keyboardType: switch (state) {
            TelegramState.waitPhone => TextInputType.phone,
            TelegramState.waitPassword => TextInputType.visiblePassword,
            _ => TextInputType.number,
          },
          decoration: InputDecoration(
            labelText: _stepLabel(state),
            hintText: state == TelegramState.waitPhone
                ? tr('+90 5xx xxx xx xx')
                : null,
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(state),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : () => _submit(state),
          child: Text(tr('Devam')),
        ),
      ];
    }

    return switch (state) {
      TelegramState.ready => [
        _InfoCard(
          icon: Icons.check_circle_outline,
          text: tr(
            'Telegram hesabınız bağlı. Sessizdeki gruplar dahil yeni mesajlar gelen kutusuna düşer. Bir sohbeti açınca son mesajları da indirilir.',
          ),
        ),
        const SizedBox(height: 16),
        const _PrivacyNotes(),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _busy ? null : _logout,
          child: Text(tr('Çıkış yap')),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
      TelegramState.unsupported => [
        _InfoCard(
          icon: Icons.error_outline,
          text: status.hint ?? tr('Bu giriş adımı desteklenmiyor.'),
        ),
      ],
      TelegramState.stopped when !status.enabled => [
        Text(
          tr('Telegram hesabınızı bağlayın'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          tr(
            'Mesa, Telegram\'ın resmi kütüphanesiyle hesabınıza doğrudan bağlanır. Böylece bildirim üretmeyen sessiz grupların mesajları da gelir.',
          ),
        ),
        const SizedBox(height: 16),
        const _PrivacyNotes(),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _connect,
          icon: const Icon(Icons.telegram),
          label: Text(tr('Telegram\'a bağlan')),
        ),
      ],
      // Başlıyor, çıkış yapılıyor ya da açık ama henüz ilk durum gelmedi.
      _ => [
        const SizedBox(height: 48),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Center(
          child: Text(
            state == TelegramState.loggingOut
                ? tr('Çıkış yapılıyor…')
                : tr('Telegram\'a bağlanılıyor…'),
          ),
        ),
      ],
    };
  }

  String _stepTitle(TelegramState state) => switch (state) {
    TelegramState.waitPhone => tr('Telefon numaranız'),
    TelegramState.waitCode => tr('Doğrulama kodu'),
    TelegramState.waitEmailCode => tr('E-posta kodu'),
    _ => tr('İki adımlı doğrulama şifresi'),
  };

  String _stepLabel(TelegramState state) => switch (state) {
    TelegramState.waitPhone => tr('Telefon numarası (ülke koduyla)'),
    TelegramState.waitCode => tr('Kod'),
    TelegramState.waitEmailCode => tr('E-posta kodu'),
    _ => tr('Şifre'),
  };
}

class _PrivacyNotes extends StatelessWidget {
  const _PrivacyNotes();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.lock_outline,
      text: tr(
        '• Bağlantı yalnızca Telegram sunucularına gider; mesajlar yalnızca bu telefonda saklanır.\n• Okundu bilgisi gönderilmez, çevrimiçi görünmezsiniz.\n• Bu cihaz Telegram\'da "Etkin oturumlar" listesinde görünür.\n• Bağlıyken bildirim çubuğunda sessiz bir "Telegram\'a bağlı" bildirimi durur.',
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
