import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Imagen de un huarique con fallback elegante al emoji 🍽️ cuando no hay
/// `imageUrl` o la descarga falla. Reutilizable en tarjetas, detalle y mapa.
class HuariqueImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final double emojiSize;

  const HuariqueImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 12,
    this.emojiSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kOrangeLight, kOrangeLight],
        ),
        color: kOrangeLight,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text('🍽️', style: TextStyle(fontSize: emojiSize)),
    );

    if (url == null || url!.trim().isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }
}
