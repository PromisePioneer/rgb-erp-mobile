import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';

/// Edit Main Menu screen - for configuring which menu items to show
class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  // Track excluded menu items
  final Set<String> _excludedLabels = {};

  // Minimum items required to be visible
  static const int _minItems = 3;

  // Menu items data (reuse from _menuGrid)
  final List<Map<String, dynamic>> _menuItems = [
    {'label': 'Pendaftaran Wajah', 'icon': Icons.face, 'bg': AppColors.indigo100, 'fg': AppColors.indigo600, 'route': '/face-enrollment', 'badge': 'NEW'},
    {'label': 'Jadwal', 'icon': Icons.calendar_today, 'bg': AppColors.amber100, 'fg': AppColors.amber600, 'route': '/schedule', 'badge': null},
    {'label': 'Cuti', 'icon': Icons.beach_access, 'bg': AppColors.emerald100, 'fg': AppColors.emerald600, 'route': '/leave', 'badge': null},
    {'label': 'Payroll', 'icon': Icons.account_balance_wallet, 'bg': AppColors.amber100, 'fg': AppColors.amber600, 'route': '/payroll', 'badge': null},
    {'label': 'Training', 'icon': Icons.school, 'bg': AppColors.rose100, 'fg': AppColors.rose600, 'route': null, 'badge': null},
    {'label': 'Approval', 'icon': Icons.checklist, 'bg': AppColors.indigo100, 'fg': AppColors.indigo600, 'route': null, 'badge': null},
    {'label': 'Patroli', 'icon': Icons.security, 'bg': AppColors.teal100, 'fg': AppColors.teal600, 'route': null, 'badge': null},
  ];

  int get _visibleCount => _menuItems.length - _excludedLabels.length;

  bool get _canSave => _visibleCount >= _minItems;

  void _toggleExclude(String label) {
    setState(() {
      if (_excludedLabels.contains(label)) {
        _excludedLabels.remove(label);
      } else {
        _excludedLabels.add(label);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _excludedLabels.addAll(_menuItems.map((item) => item['label'] as String));
    });
  }

  void _save() {
    if (!_canSave) return;
    // TODO: Persist excluded items to backend/preferences
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: Column(
        children: [
          // Header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.indigo600, AppColors.indigo500],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Edit Main Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Menu Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Main Menu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              TextButton(
                                onPressed: _clearAll,
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Menu items grid
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _menuItems.map((item) {
                              final label = item['label'] as String;
                              final isExcluded = _excludedLabels.contains(label);

                              return _EditMenuItem(
                                label: label,
                                icon: item['icon'] as IconData,
                                bg: item['bg'] as Color,
                                fg: item['fg'] as Color,
                                isExcluded: isExcluded,
                                onToggle: () => _toggleExclude(label),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Select Features Card (placeholder)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Features',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih minimal $_minItems fitur untuk ditampilkan di Main Menu',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TODO: Add additional features checklist here
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Segera hadir',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.slate400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate300.withAlpha(77),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.slate300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    _canSave ? 'Simpan' : 'Minimal $_minItems item harus ditampilkan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool isExcluded;
  final VoidCallback onToggle;

  const _EditMenuItem({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.isExcluded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isExcluded ? 0.4 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with toggle badge
          GestureDetector(
            onTap: onToggle,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Icon container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: fg, size: 30),
                ),

                // Toggle badge
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isExcluded ? AppColors.emerald500 : AppColors.red500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      isExcluded ? Icons.add : Icons.remove,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Label
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slate600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
