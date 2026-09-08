import 'package:flutter/material.dart';

/// Centralized condition values and helpers for daily task items.
///
/// ## Non-Chemical Conditions (tool/ppe/machine):
/// - sangat_baik (Sangat Baik/SB)
/// - baik (Baik/B)
/// - cukup_baik (Cukup Baik/CB)
/// - kurang_baik (Kurang Baik/KB)
/// - rusak (Rusak)
///
/// ## Chemical Conditions:
/// - full (Full/Penuh)
/// - half (Half/Setengah)
/// - quarter (Quarter/Seperempat)
/// - habis (Habis)

// ==================== Non-Chemical Conditions ====================

/// Non-chemical condition values (tools, PPEs, machines)
class NonChemicalConditions {
  static const String sangatBaik = 'sangat_baik';
  static const String baik = 'baik';
  static const String cukupBaik = 'cukup_baik';
  static const String kurangBaik = 'kurang_baik';
  static const String rusak = 'rusak';

  static const List<String> values = [
    sangatBaik,
    baik,
    cukupBaik,
    kurangBaik,
    rusak,
  ];

  /// Get short label (SB/B/CB/KB/Rusak)
  static String getShortLabel(String condition) {
    switch (condition) {
      case sangatBaik:
        return 'SB';
      case baik:
        return 'B';
      case cukupBaik:
        return 'CB';
      case kurangBaik:
        return 'KB';
      case rusak:
        return 'Rusak';
      default:
        return '-';
    }
  }

  /// Get full label (Sangat Baik/Baik/dll)
  static String getFullLabel(String condition) {
    switch (condition) {
      case sangatBaik:
        return 'Sangat Baik';
      case baik:
        return 'Baik';
      case cukupBaik:
        return 'Cukup Baik';
      case kurangBaik:
        return 'Kurang Baik';
      case rusak:
        return 'Rusak';
      default:
        return condition;
    }
  }

  /// Check if condition is non-chemical
  static bool isValid(String? condition) {
    return condition != null && values.contains(condition);
  }

  /// Get rank for comparison (higher = better)
  static int getRank(String? condition) {
    switch (condition) {
      case sangatBaik:
        return 5;
      case baik:
        return 4;
      case cukupBaik:
        return 3;
      case kurangBaik:
        return 2;
      case rusak:
        return 1;
      default:
        return 0;
    }
  }

  /// Get color for badge display
  static Color getColor(String? condition, {bool isSelected = false}) {
    switch (condition) {
      case sangatBaik:
        return isSelected
            ? const Color(0xFF16A34A) // green
            : const Color(0xFFDCFCE7); // green-100
      case baik:
        return isSelected
            ? const Color(0xFF059669) // emerald
            : const Color(0xFFD1FAE5); // emerald-100
      case cukupBaik:
        return isSelected
            ? const Color(0xFFD97706) // amber
            : const Color(0xFFFEF3C7); // yellow-100
      case kurangBaik:
        return isSelected
            ? const Color(0xFFEA580C) // orange
            : const Color(0xFFFFEDD5); // orange-100
      case rusak:
        return isSelected
            ? const Color(0xFFDC2626) // red
            : const Color(0xFFFEE2E2); // red-100
      default:
        return isSelected
            ? const Color(0xFF6B7280) // gray
            : const Color(0xFFF3F4F6); // gray-100
    }
  }
}

// ==================== Chemical Conditions ====================

/// Chemical condition values (stock-based)
class ChemicalConditions {
  static const String full = 'full';
  static const String half = 'half';
  static const String quarter = 'quarter';
  static const String habis = 'habis';

  static const List<String> values = [
    full,
    half,
    quarter,
    habis,
  ];

  /// Get short label (Full/Setengah/Quarter/Habis)
  static String getShortLabel(String condition) {
    switch (condition) {
      case full:
        return 'Full';
      case half:
        return 'Setengah';
      case quarter:
        return 'Seperempat';
      case habis:
        return 'Habis';
      default:
        return '-';
    }
  }

  /// Get full label
  static String getFullLabel(String condition) {
    switch (condition) {
      case full:
        return 'Full (≥75%)';
      case half:
        return 'Setengah (≥50%)';
      case quarter:
        return 'Seperempat (≥25%)';
      case habis:
        return 'Habis (<25%)';
      default:
        return condition;
    }
  }

  /// Check if condition is chemical
  static bool isValid(String? condition) {
    return condition != null && values.contains(condition);
  }

  /// Get rank for comparison (higher = better)
  static int getRank(String? condition) {
    switch (condition) {
      case full:
        return 4;
      case half:
        return 3;
      case quarter:
        return 2;
      case habis:
        return 1;
      default:
        return 0;
    }
  }

  /// Get color for badge display
  static Color getColor(String? condition, {bool isSelected = false}) {
    switch (condition) {
      case full:
        return isSelected
            ? const Color(0xFF16A34A) // green
            : const Color(0xFFDCFCE7); // green-100
      case half:
        return isSelected
            ? const Color(0xFFD97706) // amber
            : const Color(0xFFFEF3C7); // yellow-100
      case quarter:
        return isSelected
            ? const Color(0xFFEA580C) // orange
            : const Color(0xFFFFEDD5); // orange-100
      case habis:
        return isSelected
            ? const Color(0xFFDC2626) // red
            : const Color(0xFFFEE2E2); // red-100
      default:
        return isSelected
            ? const Color(0xFF6B7280) // gray
            : const Color(0xFFF3F4F6); // gray-100
    }
  }
}

// ==================== Unified Helpers ====================

/// All valid condition values (combined)
class ItemConditions {
  static const List<String> allValues = [
    ...NonChemicalConditions.values,
    ...ChemicalConditions.values,
  ];

  /// Get full label for any condition value
  static String getFullLabel(String? condition) {
    if (condition == null) return '-';
    if (NonChemicalConditions.isValid(condition)) {
      return NonChemicalConditions.getFullLabel(condition);
    }
    if (ChemicalConditions.isValid(condition)) {
      return ChemicalConditions.getFullLabel(condition);
    }
    return condition;
  }

  /// Get short label for any condition value
  static String getShortLabel(String? condition) {
    if (condition == null) return '-';
    if (NonChemicalConditions.isValid(condition)) {
      return NonChemicalConditions.getShortLabel(condition);
    }
    if (ChemicalConditions.isValid(condition)) {
      return ChemicalConditions.getShortLabel(condition);
    }
    return '-';
  }

  /// Get rank for comparison (higher = better)
  static int getRank(String? condition) {
    if (condition == null) return 0;
    if (NonChemicalConditions.isValid(condition)) {
      return NonChemicalConditions.getRank(condition);
    }
    if (ChemicalConditions.isValid(condition)) {
      return ChemicalConditions.getRank(condition);
    }
    return 0;
  }

  /// Check if final condition is better than initial (not allowed)
  static bool isBetterThan(String? finalCond, String? initialCond) {
    return getRank(finalCond) > getRank(initialCond);
  }

  /// Check if condition value is valid
  static bool isValid(String? condition) {
    return condition != null && allValues.contains(condition);
  }

  /// Check if condition is non-chemical type
  static bool isNonChemical(String? condition) {
    return NonChemicalConditions.isValid(condition);
  }

  /// Check if condition is chemical type
  static bool isChemical(String? condition) {
    return ChemicalConditions.isValid(condition);
  }

  /// Get text color for selected badge
  static Color getTextColor(String? condition) {
    if (condition == null) return const Color(0xFF374151); // gray-700
    if (NonChemicalConditions.isValid(condition)) {
      return NonChemicalConditions.getColor(condition, isSelected: true);
    }
    if (ChemicalConditions.isValid(condition)) {
      return ChemicalConditions.getColor(condition, isSelected: true);
    }
    return const Color(0xFF374151);
  }

  /// Get background color for badge
  static Color getBackgroundColor(String? condition) {
    if (condition == null) return const Color(0xFFF3F4F6); // gray-100
    if (NonChemicalConditions.isValid(condition)) {
      return NonChemicalConditions.getColor(condition, isSelected: false);
    }
    if (ChemicalConditions.isValid(condition)) {
      return ChemicalConditions.getColor(condition, isSelected: false);
    }
    return const Color(0xFFF3F4F6);
  }

  /// Get border color for badge (same as text color but darker)
  static Color getBorderColor(String? condition) {
    if (condition == null) return const Color(0xFFD1D5DB); // gray-300
    if (NonChemicalConditions.isValid(condition)) {
      return NonChemicalConditions.getColor(condition, isSelected: true)
          .withValues(alpha: 0.5);
    }
    if (ChemicalConditions.isValid(condition)) {
      return ChemicalConditions.getColor(condition, isSelected: true)
          .withValues(alpha: 0.5);
    }
    return const Color(0xFFD1D5DB);
  }
}
