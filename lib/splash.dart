import 'dart:async';

import 'package:flutter/material.dart';

import 'constants.dart';

// ---------------------------------------------------------------------------
// Splash Screen
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kPinkSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: kPinkAccent.withOpacity(0.6),
                  width: 1.4,
                ),
              ),
              child: Icon(Icons.cake_rounded, color: kPinkPrimary, size: 42),
            ),
            const SizedBox(height: 24),
            Text(
              kAppName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastries & Cakes Inventory\nManagement System',
              textAlign: TextAlign.center,
              style: TextStyle(color: kPinkPrimary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 90,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
                color: kPinkPrimary,
                backgroundColor: kPinkSoft,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'LOADING...',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
