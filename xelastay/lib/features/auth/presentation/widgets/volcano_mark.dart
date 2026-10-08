import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class VolcanoMark extends StatelessWidget {
  const VolcanoMark({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * .68,
    child: CustomPaint(painter: _SantaMariaPainter()),
  );
}

class _SantaMariaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mountain = Path()
      ..moveTo(0, size.height * .9)
      ..lineTo(size.width * .36, size.height * .18)
      ..lineTo(size.width * .49, size.height * .42)
      ..lineTo(size.width * .58, size.height * .25)
      ..lineTo(size.width, size.height * .9)
      ..close();
    canvas.drawPath(mountain, Paint()..color = AppColors.blue);

    final snow = Path()
      ..moveTo(size.width * .31, size.height * .28)
      ..lineTo(size.width * .36, size.height * .18)
      ..lineTo(size.width * .42, size.height * .3)
      ..lineTo(size.width * .36, size.height * .27)
      ..lineTo(size.width * .33, size.height * .33)
      ..close();
    canvas.drawPath(snow, Paint()..color = AppColors.surface);

    final horizon = Path()
      ..moveTo(0, size.height * .9)
      ..quadraticBezierTo(size.width * .42, size.height * .76, size.width, size.height * .89);
    canvas.drawPath(
      horizon,
      Paint()
        ..color = AppColors.red
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
