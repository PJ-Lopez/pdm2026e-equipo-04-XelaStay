import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.label = 'Aquí va una imagen',
    this.icon = Icons.image_outlined,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.blueSoft,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 24 : 32, color: AppColors.blue),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.blue,
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
