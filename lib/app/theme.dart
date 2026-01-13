import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: Colors.black,
      secondary: Colors.blueGrey,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: Colors.white,
      secondary: Colors.blueGrey,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),
  );
}
