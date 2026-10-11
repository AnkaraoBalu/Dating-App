import 'package:flutter/material.dart';

abstract final class AppGradients {
  static const match = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8B72), Color(0xFFFF5E78)],
  );
  static const sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD0A6), Color(0xFFFF9B83), Color(0xFFFF6678)],
  );
  static const forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF234F42), Color(0xFF0C2922)],
  );
  static const photoOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.45, 1],
    colors: [Colors.transparent, Color(0xD9000000)],
  );
}
