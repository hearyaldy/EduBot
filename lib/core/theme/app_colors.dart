import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const secondary = Color(0xFFFBBF24);

  // Gradient Colors
  static const gradientStart = Color(0xFF667EEA);
  static const gradientMiddle = Color(0xFF764BA2);
  static const gradientEnd = Color(0xFFF093FB);

  // Success Gradient
  static const successStart = Color(0xFF10B981);
  static const successMiddle = Color(0xFF059669);
  static const successEnd = Color(0xFF047857);

  // Analytics Gradient
  static const analyticsStart = Color(0xFF8B5CF6);
  static const analyticsMiddle = Color(0xFFA855F7);
  static const analyticsEnd = Color(0xFFC084FC);

  // Semantic Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF6366F1);

  // Neutral Colors
  static const white = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);
  static const gray800 = Color(0xFF1E293B);
  static const gray900 = Color(0xFF0F172A);

  // Page-specific gradient colors
  static const scanGradient1 = Color(0xFF3B82F6); // Blue
  static const scanGradient2 = Color(0xFF8B5CF6); // Purple
  static const scanGradient3 = Color(0xFF06B6D4); // Cyan

  static const askGradient1 = Color(0xFF10B981); // Emerald
  static const askGradient2 = Color(0xFF3B82F6); // Blue
  static const askGradient3 = Color(0xFF8B5CF6); // Purple

  static const historyGradient1 = Color(0xFFF59E0B); // Amber
  static const historyGradient2 = Color(0xFFEF4444); // Red
  static const historyGradient3 = Color(0xFFEC4899); // Pink

  static const settingsGradient1 = Color(0xFF6B7280); // Gray
  static const settingsGradient2 = Color(0xFF374151); // Gray
  static const settingsGradient3 = Color(0xFF1F2937); // Dark Gray

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successStart, successMiddle, successEnd],
  );

  static const LinearGradient analyticsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [analyticsStart, analyticsMiddle, analyticsEnd],
  );
}
