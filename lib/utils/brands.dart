import 'package:flutter/material.dart';
import 'app_theme.dart';

class BrandInfo {
  final String name;
  final Color primaryColor;
  final List<Color>? gradientColors;
  final IconData icon;

  const BrandInfo({
    required this.name,
    required this.primaryColor,
    this.gradientColors,
    required this.icon,
  });
}

class Brands {
  Brands._();

  static const List<String> serviceOptions = [
    'Netflix',
    'Prime',
    'Canva',
    'ChatGPT',
    'Claude',
    'Custom',
  ];

  static const Map<String, BrandInfo> all = {
    'Netflix': BrandInfo(
      name: 'Netflix',
      primaryColor: Color(0xFFE50914),
      icon: Icons.tv_rounded,
    ),
    'Prime': BrandInfo(
      name: 'Prime',
      primaryColor: Color(0xFF00A8E1),
      icon: Icons.shopping_bag_rounded,
    ),
    'Canva': BrandInfo(
      name: 'Canva',
      primaryColor: Color(0xFF00C4CC),
      gradientColors: [Color(0xFF00C4CC), Color(0xFF7D2AE8)],
      icon: Icons.palette_rounded,
    ),
    'ChatGPT': BrandInfo(
      name: 'ChatGPT',
      primaryColor: Color(0xFF10A37F),
      icon: Icons.auto_awesome_rounded,
    ),
    'Claude': BrandInfo(
      name: 'Claude',
      primaryColor: Color(0xFFD97757),
      icon: Icons.psychology_rounded,
    ),
  };

  static BrandInfo? find(String? brandKey) {
    if (brandKey == null) return null;
    return all[brandKey];
  }
}

class BrandIcon extends StatelessWidget {
  final String? brandKey;
  final double size;

  const BrandIcon({
    super.key,
    required this.brandKey,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Brands.find(brandKey);
    if (brand == null) {
      final colors = AppColors.of(context);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Icon(
          Icons.layers_outlined,
          color: colors.foreground,
          size: size * 0.52,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brand.gradientColors == null ? brand.primaryColor : null,
        gradient: brand.gradientColors != null
            ? LinearGradient(
                colors: brand.gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        brand.icon,
        color: Colors.white,
        size: size * 0.54,
      ),
    );
  }
}
