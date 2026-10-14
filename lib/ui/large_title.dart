import 'package:flutter/material.dart';

/// Sekme ekranlarının büyük başlığı ("Mesajlar", "Kurallar", "Ayarlar").
AppBar largeTitleAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
}) {
  final theme = Theme.of(context);
  return AppBar(
    toolbarHeight: 72,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marka degradesiyle başlık: düz ekranlara biraz kimlik.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? const [Color(0xFF8C9EFF), Color(0xFFB388FF)]
                : const [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
          ).createShader(bounds),
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
      ],
    ),
    actions: actions,
  );
}

/// Ayarlar ve benzeri ekranlarda yuvarlak köşeli bölüm: başlık + kart.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
