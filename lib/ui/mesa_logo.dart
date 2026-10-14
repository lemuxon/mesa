import 'package:flutter/material.dart';

import 'theme.dart';

/// Mesa logosu: marka geçişi üstünde, farklı uygulamalardan gelen sohbetleri
/// temsil eden üç renkli çizgili tek balon. Geometri ana ekran simgesiyle
/// aynı (tool/branding/make_icons.py; 108'lik tuvalin ortadaki 72'si).
class MesaLogo extends StatelessWidget {
  const MesaLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Mesa',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.29),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.35),
            blurRadius: size / 4,
            offset: Offset(0, size / 10),
          ),
        ],
      ),
      child: CustomPaint(painter: _BubblePainter()),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  static const _bars = [
    (36.0, 38.0, 32.0, Color(0xFF34D399)),
    (36.0, 47.0, 24.0, Color(0xFF60A5FA)),
    (36.0, 56.0, 28.0, Color(0xFFF472B6)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 108'lik tuvalin 18..90 aralığı bileşeni doldurur.
    final k = size.width / 72;
    canvas.scale(k);
    canvas.translate(-18, -18);
    final white = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromLTRBR(28, 30, 80, 70, const Radius.circular(10)),
      white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 70)
        ..lineTo(38, 79)
        ..lineTo(38, 70)
        ..close(),
      white,
    );
    for (final (x, y, w, color) in _bars) {
      canvas.drawRRect(
        RRect.fromLTRBR(x, y, x + w, y + 6, const Radius.circular(3)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
