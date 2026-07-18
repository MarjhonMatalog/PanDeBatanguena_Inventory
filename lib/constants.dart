import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// App-wide pink palette (light mode)
// ---------------------------------------------------------------------------
const Color kPinkPrimary = Color(0xFFE85D8A);
const Color kPinkAccent = Color(0xFFFF7FAA);
const Color kPinkSoft = Color(0xFFFFE3ED);
const Color kInk = Color(0xFF1B1B29);

// ---------------------------------------------------------------------------
// Bakery-inspired dark palette
// ---------------------------------------------------------------------------
const Color kDarkBackground = Color(0xFF121212);
const Color kDarkBackgroundAlt = Color(0xFF1A1A1A);
const Color kDarkCard = Color(0xFF232323);
const Color kDarkSurface = Color(0xFF2C2C2C);
const Color kPurplePrimary = Color(0xFF6C3FA8); // matches the logo's purple
const Color kInkDark = Color(0xFFF2F2F2);

const String kAppName = 'Pan de Batangueña';
const String kLogoAssetPath = 'assets/images/logo.png';
const String kLogoUrl =
    'https://cdn.phototourl.com/free/2026-07-18-307f855c-3d97-410a-a2e8-45985431f824.png';

/// Bakery logo, loaded from [kLogoUrl]. Falls back to the bundled local
/// asset (and finally a plain icon) if the network image can't load, so the
/// logo still renders offline or if the URL ever goes away.
class BakeryLogo extends StatelessWidget {
  const BakeryLogo({super.key, this.size = 44, this.fit = BoxFit.contain});

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      kLogoUrl,
      width: size,
      height: size,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: kPinkPrimary),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Image.asset(
        kLogoAssetPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => Icon(Icons.cake_rounded, color: kPinkPrimary, size: size * 0.7),
      ),
    );
  }
}

/// Theme-adaptive replacement for the old hardcoded `kInk` text color.
/// Light mode keeps the original ink color; dark mode switches to a
/// near-white so labels/headings stay readable on dark surfaces.
Color inkOn(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? kInkDark : kInk;