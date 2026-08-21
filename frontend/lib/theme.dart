import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1B6F5C); // deep teal, evokes gas/industrial + trust
  static const accent = Color(0xFFEF8354); // warm orange accent (flame)

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, secondary: accent),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: const StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

/// Human-readable label + color for order/payment/delivery statuses.
class StatusStyle {
  static String label(String status) {
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static Color color(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.indigo;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
      case 'successful':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'failed':
      case 'failed_delivery':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
