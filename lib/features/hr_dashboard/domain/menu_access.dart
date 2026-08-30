import 'package:flutter/material.dart';
import '../../auth/domain/entities/user.dart';

/// Menu item data class
class MenuItemData {
  final String label;
  final IconData icon;
  final String? route;
  final String? badge;

  const MenuItemData({
    required this.label,
    required this.icon,
    this.route,
    this.badge,
  });
}

/// Mapping of menu labels to their required privilege keys
const Map<String, String> menuPrivilegeMapping = {
  'Absen': 'presensi',
  'Pendaftaran Wajah': 'face_enrollment',
  'Jadwal': 'schedule',
  'Cuti': 'leave',
  'Payroll': 'payroll',
  'Approval': 'approval',
  'Patroli': 'patrol',
  'Laporan Patroli': 'patrol_report',
  'Laporan Mutasi': 'field_report',
  'Tugas Harian': 'daily_task',
};

/// Menu labels that should be hidden when user already has the data
final Map<String, bool Function(User)> menuConditionalHide = {
  'Pendaftaran Wajah': (user) => user.hasFaceEnrollment,
};

/// Filters menu items based on user privileges and conditional rules
///
/// Takes a list of menu items and filters out:
/// 1. Items the user doesn't have privileges for
/// 2. Items that should be hidden based on user data (e.g., face enrollment done)
List<MenuItemData> filterMenuByPrivileges(
  List<MenuItemData> menuItems,
  User user,
) {
  return menuItems.where((item) {
    // Check conditional hide rules (e.g., face enrollment already done)
    if (menuConditionalHide.containsKey(item.label)) {
      if (menuConditionalHide[item.label]!(user)) {
        return false; // Hide this menu item
      }
    }

    // Check if this menu item requires a privilege
    final requiredPrivilege = menuPrivilegeMapping[item.label];

    // If no privilege mapping, allow access (item is not gated)
    if (requiredPrivilege == null) return true;

    // Check if user has the required privilege
    return user.hasPrivilege(requiredPrivilege);
  }).toList();
}

/// Check if user has access to a specific menu item
bool hasAccessToMenu(String menuLabel, User user) {
  // Check conditional hide rules
  if (menuConditionalHide.containsKey(menuLabel)) {
    if (menuConditionalHide[menuLabel]!(user)) {
      return false;
    }
  }

  final requiredPrivilege = menuPrivilegeMapping[menuLabel];

  // If no privilege mapping, allow access
  if (requiredPrivilege == null) return true;

  return user.hasPrivilege(requiredPrivilege);
}
