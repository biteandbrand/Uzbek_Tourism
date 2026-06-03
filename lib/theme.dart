import 'package:flutter/material.dart';

/// Uygulama tohum rengi (Özbekistan yeşili).
const Color kSeedColor = Color(0xFF1D9E75);

/// Uygulama geneli tema — tek kaynaktan, tutarlı.
ThemeData buildAppTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: kSeedColor),
      useMaterial3: true,
    );
