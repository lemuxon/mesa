import 'package:mesaj_merkezi/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/bridge.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../ui/large_title.dart';

/// Ayarlar'da "Yedek": şifreli yedek alma ve geri yükleme. Dosyanın yerini
/// kullanıcı seçer; şifre hiçbir yerde saklanmaz.
class BackupCard extends StatefulWidget {
  const BackupCard({super.key, required this.bridge, this.prefs});

  final CoreBridge bridge;
  final LocalPrefs? prefs;

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  AutoBackupStatus? _auto;

  @override
  void initState() {
    super.initState();
    _loadAuto();
  }

  Future<void> _loadAuto() async {
    try {
      final status = await widget.bridge.autoBackupStatus();
      if (mounted) setState(() => _auto = status);
    } catch (_) {
      // Eski yerel taraf ya da test: otomatik yedek bölümü gösterilmez.
    }
  }

  Future<void> _setAuto(bool on) async {
    if (!on) {
      final status = await widget.bridge.disableAutoBackup();
      if (mounted) setState(() => _auto = status);
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Otomatik yedek')),
        content: Text(
          tr(
            'Seçtiğiniz klasöre düzenli olarak şifreli yedek alınır; en yeni 5 otomatik yedek saklanır. Otomatik çalışabilmesi için parola bu telefonda, telefonun güvenli donanım anahtarıyla şifrelenip saklanır.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Klasör seç')),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final folder = await widget.bridge.pickBackupFolder();
    if (folder == null || !mounted) return;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const BackupPasswordDialog(confirm: true),
    );
    if (password == null || !mounted) return;
    final days = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today_rounded),
              title: Text(tr('Her gün')),
              onTap: () => Navigator.of(context).pop(1),
            ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded),
              title: Text(tr('Her hafta')),
              onTap: () => Navigator.of(context).pop(7),
            ),
          ],
        ),
      ),
    );
    if (days == null || !mounted) return;
    final status = await widget.bridge.enableAutoBackup(folder, password, days);
    if (!mounted) return;
    setState(() => _auto = status);
    _snack(tr('Otomatik yedek açıldı; ilk yedek şimdi alınıyor.'));
    // İlk yedeğin sonucu birkaç saniye içinde görünsün.
    await Future<void>.delayed(const Duration(seconds: 6));
    await _loadAuto();
  }

  Future<void> _runAutoNow() async {
    await widget.bridge.runAutoBackupNow();
    _snack(tr('Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.'));
    await Future<void>.delayed(const Duration(seconds: 6));
    await _loadAuto();
  }

  String _autoSubtitle(AutoBackupStatus s) {
    if (!s.enabled) {
      return tr('Seçtiğiniz klasöre düzenli, şifreli yedek');
    }
    final parts = <String>[
      s.days == 1 ? tr('Her gün') : tr('Her hafta'),
      ?s.folder,
      if (s.lastTime case final last?)
        tr('son: {when}', {'when': formatListTime(last, DateTime.now())}),
    ];
    final error = switch (s.lastError) {
      null => null,
      'PASSWORD' => tr(
        'Kayıtlı parola açılamadı; otomatik yedeği yeniden açın.',
      ),
      'WRITE' => tr('Yedek yazılamadı; yer kalmamış olabilir.'),
      _ => tr('Klasöre yazılamadı; klasörü yeniden seçin.'),
    };
    return [parts.join(' · '), ?error].join('\n');
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Uzun süren iş boyunca kapatılamayan bekleme penceresi.
  Future<T> _withProgress<T>(String text, Future<T> Function() work) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      ),
    );
    try {
      return await work();
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _backup() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const BackupPasswordDialog(confirm: true),
    );
    if (password == null || !mounted) return;
    try {
      final result = await _withProgress(
        tr('Yedekleniyor… Fotoğraflar çoksa biraz sürebilir.'),
        () => widget.bridge.createBackup(password),
      );
      if (result == null) return; // Kullanıcı konum seçmedi.
      await widget.prefs?.setLastBackupAt(DateTime.now());
      if (mounted) setState(() {});
      _snack(
        tr('Yedek kaydedildi: {messages} mesaj, {files} fotoğraf ({bytes}).', {
          'messages': result.messages,
          'files': result.files,
          'bytes': formatSize(result.bytes),
        }),
      );
    } on PlatformException catch (e) {
      _snack(
        tr('Yedek alınamadı: {error}', {
          'error': e.message ?? tr('bilinmeyen hata'),
        }),
      );
    }
  }

  Future<void> _restore() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Yedekten geri yüklensin mi?')),
        content: Text(
          tr(
            'Bu telefondaki Mesa mesajları, kişileri ve kuralları yedektekilerle değiştirilir. Telegram ve web servisi girişleri yedekte yoktur; gerekirse yeniden giriş yaparsınız.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr('Dosya seç')),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final uri = await widget.bridge.pickBackupFile();
    if (uri == null || !mounted) return;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const BackupPasswordDialog(confirm: false),
    );
    if (password == null || !mounted) return;
    try {
      final result = await _withProgress(
        tr('Geri yükleniyor…'),
        () => widget.bridge.restoreBackup(uri, password),
      );
      _snack(
        tr('Geri yüklendi: {messages} mesaj, {files} fotoğraf.', {
          'messages': result.messages,
          'files': result.files,
        }),
      );
    } on PlatformException catch (e) {
      _snack(switch (e.code) {
        'WRONG_PASSWORD' => tr(
          'Şifre yanlış. Yedeği alırken girdiğiniz şifreyi deneyin.',
        ),
        'CORRUPT' => tr('Dosya açılamadı: {error}', {
          'error': e.message ?? tr('yedek bozuk'),
        }),
        _ => tr('Geri yüklenemedi: {error}', {
          'error': e.message ?? tr('bilinmeyen hata'),
        }),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.prefs?.lastBackupAt;
    return SectionCard(
      title: tr('Yedek'),
      children: [
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: Text(tr('Yedekle')),
          subtitle: Text(
            last == null
                ? tr(
                    'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Henüz yedek alınmadı.',
                  )
                : tr(
                    'Mesajlar, kişiler, kurallar ve fotoğraflar; şifreli dosya. Son yedek: {when}',
                    {'when': formatListTime(last, DateTime.now())},
                  ),
          ),
          onTap: _backup,
        ),
        if (_auto case final auto?) ...[
          SwitchListTile(
            secondary: const Icon(Icons.update_rounded),
            title: Text(tr('Otomatik yedek')),
            subtitle: Text(_autoSubtitle(auto)),
            isThreeLine: auto.enabled && auto.lastError != null,
            value: auto.enabled,
            onChanged: _setAuto,
          ),
          if (auto.enabled)
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(tr('Şimdi yedekle')),
              onTap: _runAutoNow,
            ),
        ],
        ListTile(
          leading: const Icon(Icons.settings_backup_restore_rounded),
          title: Text(tr('Yedekten geri yükle')),
          subtitle: Text(tr('Yeni telefonda ya da sıfırlamadan sonra')),
          onTap: _restore,
        ),
      ],
    );
  }
}

/// Yedek şifresi. Yedeklerken iki kez girilir (en az 8 karakter).
class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({super.key, required this.confirm});

  /// Yedek alınırken: şifre tekrar istenir ve uyarı gösterilir.
  final bool confirm;

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;
  bool _hidden = true;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _first.text;
    if (widget.confirm) {
      if (password.length < 8) {
        setState(() => _error = tr('En az 8 karakter olmalı.'));
        return;
      }
      if (password != _second.text) {
        setState(() => _error = tr('Şifreler aynı değil.'));
        return;
      }
    } else if (password.isEmpty) {
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.confirm ? tr('Yedek şifresi') : tr('Yedeğin şifresi')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.confirm)
              Text(
                tr(
                  'Bu şifreyi unutursanız yedek açılamaz; kimse kurtaramaz. Bir yere not edin.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            TextField(
              controller: _first,
              obscureText: _hidden,
              autofocus: true,
              decoration: InputDecoration(
                labelText: tr('Şifre'),
                suffixIcon: IconButton(
                  tooltip: _hidden ? tr('Göster') : tr('Gizle'),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
              onSubmitted: widget.confirm ? null : (_) => _submit(),
            ),
            if (widget.confirm)
              TextField(
                controller: _second,
                obscureText: _hidden,
                decoration: InputDecoration(labelText: tr('Şifre (tekrar)')),
                onSubmitted: (_) => _submit(),
              ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Vazgeç')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirm ? tr('Yedekle') : tr('Aç')),
        ),
      ],
    );
  }
}
