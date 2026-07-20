import 'package:flutter/material.dart';

// App-wide pink palette (light mode)
const Color kPinkPrimary = Color(0xFFE85D8A);
const Color kPinkAccent = Color(0xFFFF7FAA);
const Color kPinkSoft = Color(0xFFFFE3ED);
const Color kInk = Color(0xFF1B1B29);

// Bakery-inspired dark palette
const Color kDarkBackground = Color(0xFF121212);
const Color kDarkBackgroundAlt = Color(0xFF1A1A1A);
const Color kDarkCard = Color(0xFF232323);
const Color kDarkSurface = Color(0xFF2C2C2C);
const Color kPurplePrimary = Color(0xFF6C3FA8); // matches the logo's purple
const Color kInkDark = Color(0xFFF2F2F2);

const String kAppName = 'Pan de Batangueña';

const String kLogoAssetPath = 'assets/images/logo.png';

const String kLogoMarkAssetPath = 'assets/images/logo_mark.png';

class BakeryLogo extends StatelessWidget {
  const BakeryLogo({super.key, this.size = 44, this.fit = BoxFit.contain, this.mark = false});

  final double size;
  final BoxFit fit;
  final bool mark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mark ? kLogoMarkAssetPath : kLogoAssetPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => Icon(Icons.cake_rounded, color: kPinkPrimary, size: size * 0.7),
    );
  }
}

Color inkOn(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? kInkDark : kInk;