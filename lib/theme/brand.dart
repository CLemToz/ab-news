import 'package:flutter/material.dart';

class Brand {
  static const blue = Color(0xFF293493);
  static const red  = Color(0xFFEE1A24);

// Helpful gradients
  static const headerGrad = LinearGradient(
    colors: [blue, red],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const chipGrad = LinearGradient(
    colors: [red, Color(0xFFE94C57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
