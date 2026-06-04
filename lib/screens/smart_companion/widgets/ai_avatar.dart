import 'package:flutter/material.dart';

import '../../../constants/app_ai_images.dart';

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, this.size = _defaultSize});

  static const double _defaultSize = 44.936;
  static const double _refImageWidth = 34.864;
  static const double _refImageHeight = 34.286;

  final double size;

  @override
  Widget build(BuildContext context) {
    final double imageWidth = size * (_refImageWidth / _defaultSize);
    final double imageHeight = size * (_refImageHeight / _defaultSize);
    return Semantics(
      label: 'مِشْكَاة',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          AppAiImages.smileCharacter,
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
