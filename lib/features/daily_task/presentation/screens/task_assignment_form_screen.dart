import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/inputs/async_select_field.dart';
import '../../domain/models/daily_task.dart';
import '../providers/daily_task_provider.dart';

/// Step indicator widget
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor: AppColors.slate200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Step labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              final isCurrent = index == currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors
                            .slate200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isActive && !isCurrent
                            ? const Icon(
                            Icons.check, color: Colors.white, size: 16)
                            : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.slate500,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight
                            .normal,
                        color: isActive ? AppColors.primary : AppColors
                            .slate500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Reusable form field card widget for consistent styling
class FormFieldCard extends StatelessWidget {
  final Widget child;

  const FormFieldCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}

/// Form wizard screen for creating or editing a daily task assignment
class TaskAssignmentFormScreen extends StatefulWidget {
  final Map<String, dynamic>? editData; // Data for edit mode

  const TaskAssignmentFormScreen({super.key, this.editData});

  @override
  State<TaskAssignmentFormScreen> createState() =>
      _TaskAssignmentFormScreenState();
}

class _TaskAssignmentFormScreenState extends State<TaskAssignmentFormScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Edit mode flag
  bool get _isEditMode => widget.editData != null;
  int? _editTaskId;

  // Form data
  final Set<int> _selectedRoleIds = {};
  String? _selectedRoleName;
  final Set<int> _selectedEmployeeIds = {};
  final Set<String> _selectedEmployeeNames = {};
  int? _selectedItemId;
  String? _selectedItemName;
  final _targetMinutesController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Tools, Chemicals, PPE, Machine selection
  final Set<int> _selectedToolIds = {};
  final Set<String> _selectedToolNames = {};
  final Set<int> _selectedChemicalIds = {};
  final Set<String> _selectedChemicalNames = {};
  final Set<int> _selectedPpeIds = {};
  final Set<String> _selectedPpeNames = {};
  final Set<int> _selectedMachineIds = {};
  final Set<String> _selectedMachineNames = {};

  final List<String> _stepLabels = [
    'Info',
    'Detail',
    'Peralatan',
    'Konfirmasi'
  ];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final notifier = context.read<DailyTaskNotifier>();

    // Load master data
    notifier.loadMobileAssignEmployees();
    notifier.loadRoles(); // Load roles first
    notifier.loadItems();
    notifier.loadMasterData();

    // If edit mode, pre-fill data
    if (_isEditMode) {
      _prefillFromEditData();
    }
  }

  /// Get areaId from selected employee (employee's stationed area)
  int? get _currentAreaId {
    // For edit mode, use area_id from edit data
    if (_isEditMode && widget.editData != null) {
      return widget.editData!['area_id'] as int?;
    }
    // Get area_id from selected employee(s) - their stationed area from placement
    if (_selectedEmployeeIds.isNotEmpty) {
      // Find the first selected employee in the loaded employees list
      final notifier = context.read<DailyTaskNotifier>();
      final selectedEmp = notifier.mobileAssignEmployees.cast<Map<String, dynamic>>().firstWhere(
        (e) => _selectedEmployeeIds.contains(e['id']),
        orElse: () => {},
      );
      if (selectedEmp.containsKey('area_id') && selectedEmp['area_id'] != null) {
        return selectedEmp['area_id'] as int;
      }
    }
    return null;
  }

  void _prefillFromEditData() {
    final data = widget.editData!;

    _editTaskId = data['id'] as int?;

    // Prefill employees
    if (data.containsKey('employees') && data['employees'] != null) {
      final employees = data['employees'] as List;
      for (final emp in employees) {
        if (emp is Map) {
          final id = emp['id'] as int?;
          final name = emp['name'] as String?;
          if (id != null && name != null) {
            _selectedEmployeeIds.add(id);
            _selectedEmployeeNames.add(name);
          }
        }
      }
    }

    // Prefill item
    if (data.containsKey('item_id') && data['item_id'] != null) {
      _selectedItemId = data['item_id'] as int;
    }
    if (data.containsKey('item_name') && data['item_name'] != null) {
      _selectedItemName = data['item_name'] as String;
    }
    // Also check nested item object
    if (data.containsKey('item') && data['item'] != null) {
      final item = data['item'] as Map;
      _selectedItemId = item['id'] as int?;
      _selectedItemName = item['name'] as String?;
    }

    // Prefill target minutes
    if (data.containsKey('target_minutes') && data['target_minutes'] != null) {
      _targetMinutesController.text = data['target_minutes'].toString();
    }

    // Prefill notes
    if (data.containsKey('notes') && data['notes'] != null) {
      _notesController.text = data['notes'] as String;
    }

    // Prefill date
    if (data.containsKey('assigned_date') && data['assigned_date'] != null) {
      try {
        _selectedDate = DateTime.parse(data['assigned_date'] as String);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    }

    // Prefill tools
    if (data.containsKey('tools') && data['tools'] != null) {
      final tools = data['tools'] as List;
      for (final tool in tools) {
        if (tool is Map) {
          final id = tool['id'] as int?;
          final name = tool['name'] as String?;
          if (id != null && name != null) {
            _selectedToolIds.add(id);
            _selectedToolNames.add(name);
          }
        }
      }
    }

    // Prefill chemicals
    if (data.containsKey('chemicals') && data['chemicals'] != null) {
      final chemicals = data['chemicals'] as List;
      for (final chem in chemicals) {
        if (chem is Map) {
          final id = chem['id'] as int?;
          final name = chem['name'] as String?;
          if (id != null && name != null) {
            _selectedChemicalIds.add(id);
            _selectedChemicalNames.add(name);
          }
        }
      }
    }

    // Prefill ppes
    if (data.containsKey('ppes') && data['ppes'] != null) {
      final ppes = data['ppes'] as List;
      for (final ppe in ppes) {
        if (ppe is Map) {
          final id = ppe['id'] as int?;
          final name = ppe['name'] as String?;
          if (id != null && name != null) {
            _selectedPpeIds.add(id);
            _selectedPpeNames.add(name);
          }
        }
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _targetMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
      // Step 1: Role dan jenis tugas wajib, minimal 1 karyawan wajib
        return _selectedRoleIds.isNotEmpty &&
            _selectedEmployeeIds.isNotEmpty &&
            _selectedItemId != null;
      case 1:
      // Step 2: Target durasi dan catatan wajib
        final hasTargetMinutes = _targetMinutesController.text
            .trim()
            .isNotEmpty;
        final hasNotes = _notesController.text
            .trim()
            .isNotEmpty;
        return hasTargetMinutes && hasNotes;
      case 2:
      // Step 3: Alat, Chemical, dan APD wajib (Mesin optional)
        return _selectedToolIds.isNotEmpty &&
            _selectedChemicalIds.isNotEmpty &&
            _selectedPpeIds.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    } else {
      String message;
      switch (_currentStep) {
        case 0:
          message = 'Pilih posisi, jenis tugas, dan minimal 1 karyawan';
          break;
        case 1:
          message = 'Target durasi dan catatan wajib diisi';
          break;
        case 2:
          message = 'Alat, chemical, dan APD wajib dipilih';
          break;
        default:
          message = 'Lengkapi data yang diperlukan';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    final targetMinutes = int.tryParse(_targetMinutesController.text);
    final notes = _notesController.text
        .trim()
        .isEmpty ? null : _notesController.text.trim();
    final assignedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final notifier = context.read<DailyTaskNotifier>();

    bool success = false;

    if (_isEditMode && _editTaskId != null) {
      // Edit mode - update existing task
      success = await notifier.updateTask(
        taskId: _editTaskId!,
        employeeIds: _selectedEmployeeIds.isEmpty ? null : _selectedEmployeeIds
            .toList(),
        itemId: _selectedItemId,
        assignedDate: assignedDate,
        targetMinutes: targetMinutes,
        notes: notes,
        toolIds: _selectedToolIds.isEmpty ? null : _selectedToolIds.toList(),
        chemicalIds: _selectedChemicalIds.isEmpty ? null : _selectedChemicalIds
            .toList(),
        ppeIds: _selectedPpeIds.isEmpty ? null : _selectedPpeIds.toList(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
        context.pop(); // Also pop the detail screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notifier.error ?? 'Gagal memperbarui tugas'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else {
      // Create mode - create new task
      final result = await notifier.mobileAssignTask(
        employeeIds: _selectedEmployeeIds.toList(),
        itemId: _selectedItemId,
        targetMinutes: targetMinutes,
        notes: notes,
        assignedDate: assignedDate,
        toolIds: _selectedToolIds.isEmpty ? null : _selectedToolIds.toList(),
        chemicalIds: _selectedChemicalIds.isEmpty ? null : _selectedChemicalIds
            .toList(),
        ppeIds: _selectedPpeIds.isEmpty ? null : _selectedPpeIds.toList(),
        machineIds: _selectedMachineIds.isEmpty ? null : _selectedMachineIds
            .toList(),
      );

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas berhasil ditugaskan ke ${_selectedEmployeeIds
                .length} karyawan'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        // Tampilkan validation errors per field
        final validationErrors = notifier.validationErrors;
        if (validationErrors != null && validationErrors.isNotEmpty) {
          final List<String> errorMessages = [];
          validationErrors.forEach((field, errors) {
            for (final error in errors) {
              errorMessages.add(error);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessages.join('\n'),
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notifier.error ?? 'Gagal membuat tugas'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Widget _buildStepContent(DailyTaskNotifier notifier, bool isSubmitting) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Info(notifier, isSubmitting);
      case 1:
        return _buildStep2Detail(isSubmitting);
      case 2:
        return _buildStep3Peralatan(notifier, isSubmitting);
      case 3:
        return _buildStep4Konfirmasi();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Info(DailyTaskNotifier notifier, bool isSubmitting) {
    // Build initial options for edit mode
    final initialItemOptions = _isEditMode && _selectedItemId != null
        ? [
      AsyncSelectOption(
          id: _selectedItemId!, name: _selectedItemName ?? 'Memuat...')
    ]
        : <AsyncSelectOption>[];

    final initialEmployeeOptions = _isEditMode &&
        _selectedEmployeeIds.isNotEmpty
        ? _selectedEmployeeIds.map((id) {
      final name = _selectedEmployeeNames.firstWhere(
            (n) =>
            notifier.mobileAssignEmployees.any((e) =>
        e['id'] == id && e['name'] == n),
        orElse: () => 'Memuat...',
      );
      final emp = notifier.mobileAssignEmployees
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (e) => e?['id'] == id,
        orElse: () => null,
      );
      final displayName = emp != null
          ? '${emp['name']} (${emp['code'] ?? ''})'
          : name;
      return AsyncSelectOption(id: id, name: displayName);
    }).toList()
        : <AsyncSelectOption>[];

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Role - AsyncSelectField (Single-select) - Select first to filter items
        FormFieldCard(
          child: AsyncSelectField(
            label: 'ROLE/JABATAN',
            placeholder: 'Pilih role untuk filter tugas',
            loadOptions: (query) async {
              final roles = notifier.roles;

              // Calculate hierarchy levels
              final roleMap = {for (var r in roles) r.id: r};
              List<({int id, String name, int level})> buildHierarchy() {
                final result = <({int id, String name, int level})>[];

                void addWithLevel(int id, int level) {
                  final role = roleMap[id];
                  if (role == null) return;
                  // Avoid infinite loop for circular references
                  if (result.any((r) => r.id == id)) return;

                  result.add((id: role.id, name: role.name, level: level));

                  // Add children (roles that have this as parent)
                  for (final child in roles.where((r) => r.parentRoleId == id)) {
                    addWithLevel(child.id, level + 1);
                  }
                }

                // Start with root roles (no parent)
                for (final role in roles.where((r) => r.parentRoleId == null)) {
                  addWithLevel(role.id, 0);
                }

                return result;
              }

              final hierarchy = buildHierarchy();

              // If no hierarchy (all roles have parents), use flat list
              final displayRoles = hierarchy.isNotEmpty ? hierarchy : roles
                  .map((r) => (id: r.id, name: r.name, level: 0))
                  .toList();

              // Filter by query if needed
              final filtered = query.isEmpty
                  ? displayRoles
                  : displayRoles.where((r) => r.name.toLowerCase().contains(query.toLowerCase())).toList();

              return filtered.map((r) {
                final indent = '  ' * r.level + (r.level > 0 ? '└─ ' : '');
                return AsyncSelectOption(id: r.id, name: '$indent${r.name}');
              }).toList();
            },
            selectedIds: _selectedRoleIds,
            initialOptions: _selectedRoleIds.isNotEmpty
                ? _selectedRoleIds.map((id) {
              return AsyncSelectOption(
                  id: id, name: _selectedRoleName ?? 'Memuat...');
            }).toList()
                : null,
            onSelectionChanged: (ids) {
              final previousRoleId = _selectedRoleIds.isNotEmpty
                  ? _selectedRoleIds.first
                  : null;

              setState(() {
                _selectedRoleIds.clear();
                if (ids.isNotEmpty) {
                  final roleId = ids.first;
                  _selectedRoleIds.add(roleId);
                  // Store role name
                  final role = notifier.roles.firstWhere(
                        (r) => r.id == roleId,
                    orElse: () =>
                        DailyTaskRole(id: roleId, name: 'Unknown'),
                  );
                  _selectedRoleName = role.name;
                } else {
                  _selectedRoleName = null;
                }

                // Reset Jenis Tugas when role changes
                _selectedItemId = null;
                _selectedItemName = null;

                // Reset Karyawan when role changes (different role = different employees)
                if (previousRoleId != null && ids.isNotEmpty &&
                    ids.first != previousRoleId) {
                  _selectedEmployeeIds.clear();
                  _selectedEmployeeNames.clear();
                }
              });
            },
            multiSelect: false,
            disabled: isSubmitting,
          ),
        ),
        const SizedBox(height: 16),

        // Karyawan - AsyncSelectField (Multi-select)
        FormFieldCard(
          child: AsyncSelectField(
            label: 'KARYAWAN (TIM)',
            placeholder: _selectedRoleIds.isEmpty
                ? 'Pilih role terlebih dahulu'
                : 'Pilih karyawan untuk tugas tim',
            loadOptions: (query) async {
              // Filter by selected role if any
              final roleIds = _selectedRoleIds.isNotEmpty
                  ? _selectedRoleIds.toList()
                  : null;
              final employees = await notifier.searchMobileAssignEmployees(
                  query, roleIds: roleIds);
              return employees
                  .map((emp) =>
                  AsyncSelectOption(
                    id: emp['id'] as int,
                    name: '${emp['name']} (${emp['code'] ?? ''})',
                  ))
                  .toList();
            },
            selectedIds: _selectedEmployeeIds,
            initialOptions: initialEmployeeOptions.isNotEmpty
                ? initialEmployeeOptions
                : null,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedEmployeeIds.clear();
                _selectedEmployeeNames.clear();
                _selectedEmployeeIds.addAll(ids);
                // Store employee names
                for (final id in ids) {
                  final emp = notifier.mobileAssignEmployees.firstWhere(
                        (e) => e['id'] == id,
                    orElse: () => {'name': 'Unknown'},
                  );
                  _selectedEmployeeNames.add(emp['name'] as String);
                }
              });
            },
            multiSelect: true,
            disabled: isSubmitting || _selectedRoleIds.isEmpty,
          ),
        ),
        const SizedBox(height: 16),

        // Jenis Tugas - AsyncSelectField
        FormFieldCard(
          child: AsyncSelectField(
            label: 'JENIS TUGAS',
            placeholder: _selectedRoleIds.isEmpty
                ? 'Pilih role terlebih dahulu'
                : 'Pilih Jenis Tugas',
            loadOptions: (query) async {
              final roleIds = _selectedRoleIds.isNotEmpty
                  ? _selectedRoleIds.toList()
                  : null;
              final items = await notifier.searchItems(
                  query, roleIds: roleIds);
              return items
                  .map((item) =>
                  AsyncSelectOption(id: item.id, name: item.name))
                  .toList();
            },
            selectedIds: _selectedItemId != null ? {_selectedItemId!} : {},
            initialOptions: initialItemOptions.isNotEmpty
                ? initialItemOptions
                : null,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedItemId = ids.isNotEmpty ? ids.first : null;
                if (_selectedItemId != null) {
                  final item = notifier.items.firstWhere((i) =>
                  i.id == _selectedItemId);
                  _selectedItemName = item.name;
                }
              });
            },
            multiSelect: false,
            disabled: isSubmitting || _selectedRoleIds.isEmpty,
          ),
        ),
        const SizedBox(height: 16),

        // Tanggal - Card
        FormFieldCard(
          child: InkWell(
            onTap: isSubmitting ? null : _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.slate500,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TANGGAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(
                              _selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.slate800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                      Icons.keyboard_arrow_down, color: AppColors.slate500,
                      size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Detail(bool isSubmitting) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Target Durasi - Card with FTextField
        FormFieldCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TARGET DURASI (MENIT)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 8),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _targetMinutesController,
                ),
                size: FTextFieldSizeVariant.sm,
                hint: 'Masukkan target durasi',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Catatan - Card with FTextField
        FormFieldCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CATATAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 8),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _notesController,
                ),
                size: FTextFieldSizeVariant.sm,
                hint: 'Masukkan catatan (Wajib)',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Peralatan(DailyTaskNotifier notifier, bool isSubmitting) {
    // Build initial options for edit mode
    final initialToolOptions = _isEditMode && _selectedToolIds.isNotEmpty
        ? _selectedToolIds.map((id) {
      final name = _selectedToolNames.firstWhere(
            (n) => notifier.tools.any((t) => t.id == id && t.name == n),
        orElse: () => 'Memuat...',
      );
      return AsyncSelectOption(id: id, name: name);
    }).toList()
        : <AsyncSelectOption>[];

    final initialChemicalOptions = _isEditMode &&
        _selectedChemicalIds.isNotEmpty
        ? _selectedChemicalIds.map((id) {
      final name = _selectedChemicalNames.firstWhere(
            (n) => notifier.chemicals.any((c) => c.id == id && c.name == n),
        orElse: () => 'Memuat...',
      );
      return AsyncSelectOption(id: id, name: name);
    }).toList()
        : <AsyncSelectOption>[];

    final initialPpeOptions = _isEditMode && _selectedPpeIds.isNotEmpty
        ? _selectedPpeIds.map((id) {
      final name = _selectedPpeNames.firstWhere(
            (n) => notifier.ppes.any((p) => p.id == id && p.name == n),
        orElse: () => 'Memuat...',
      );
      return AsyncSelectOption(id: id, name: name);
    }).toList()
        : <AsyncSelectOption>[];

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Info text - area stock
        if (_currentAreaId != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withAlpha(51)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stok diambil dari stok produk di area ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Alat - AsyncSelectField
        FormFieldCard(
          child: AsyncSelectField(
            label: 'ALAT YANG DIGUNAKAN',
            placeholder: 'Ketik untuk mencari alat...',
            loadOptions: (query) async {
              final areaId = _currentAreaId;
              final tools = await notifier.searchTools(
                query,
                areaId: areaId,
                categoryType: areaId != null ? 1 : null, // Tools category
              );
              return tools
                  .map((t) => AsyncSelectOption(id: t.id, name: t.name))
                  .toList();
            },
            selectedIds: _selectedToolIds,
            initialOptions: initialToolOptions.isNotEmpty
                ? initialToolOptions
                : null,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedToolIds.clear();
                _selectedToolNames.clear();
                _selectedToolIds.addAll(ids);
                // Store tool names
                for (final id in ids) {
                  final tool = notifier.tools.firstWhere(
                        (t) => t.id == id,
                    orElse: () => DailyTaskTool(id: id, name: 'Unknown'),
                  );
                  _selectedToolNames.add(tool.name);
                }
              });
            },
            disabled: isSubmitting,
          ),
        ),
        const SizedBox(height: 16),

        // Chemical - AsyncSelectField
        FormFieldCard(
          child: AsyncSelectField(
            label: 'CHEMICAL YANG DIGUNAKAN',
            placeholder: 'Ketik untuk mencari chemical...',
            loadOptions: (query) async {
              final areaId = _currentAreaId;
              final chemicals = await notifier.searchChemicals(
                query,
                areaId: areaId,
                categoryType: areaId != null ? 2 : null, // Chemicals category
              );
              return chemicals
                  .map((c) => AsyncSelectOption(id: c.id, name: c.name))
                  .toList();
            },
            selectedIds: _selectedChemicalIds,
            initialOptions: initialChemicalOptions.isNotEmpty
                ? initialChemicalOptions
                : null,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedChemicalIds.clear();
                _selectedChemicalNames.clear();
                _selectedChemicalIds.addAll(ids);
                // Store chemical names
                for (final id in ids) {
                  final chemical = notifier.chemicals.firstWhere(
                        (c) => c.id == id,
                    orElse: () => DailyTaskChemical(id: id, name: 'Unknown'),
                  );
                  _selectedChemicalNames.add(chemical.name);
                }
              });
            },
            disabled: isSubmitting,
          ),
        ),
        const SizedBox(height: 16),

        // APD - AsyncSelectField
        FormFieldCard(
          child: AsyncSelectField(
            label: 'ALAT PELINDUNG DIRI',
            placeholder: 'Ketik untuk mencari APD...',
            loadOptions: (query) async {
              final areaId = _currentAreaId;
              final ppes = await notifier.searchPpes(
                query,
                areaId: areaId,
                categoryType: areaId != null ? 3 : null, // PPEs category
              );
              return ppes
                  .map((p) => AsyncSelectOption(id: p.id, name: p.name))
                  .toList();
            },
            selectedIds: _selectedPpeIds,
            initialOptions: initialPpeOptions.isNotEmpty
                ? initialPpeOptions
                : null,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedPpeIds.clear();
                _selectedPpeNames.clear();
                _selectedPpeIds.addAll(ids);
                // Store PPE names
                for (final id in ids) {
                  final ppe = notifier.ppes.firstWhere(
                        (p) => p.id == id,
                    orElse: () => DailyTaskPpe(id: id, name: 'Unknown'),
                  );
                  _selectedPpeNames.add(ppe.name);
                }
              });
            },
            disabled: isSubmitting,
          ),
        ),
        const SizedBox(height: 16),

        // Mesin - AsyncSelectField (Optional)
        FormFieldCard(
          child: AsyncSelectField(
            label: 'MESIN (OPSIONAL)',
            placeholder: 'Ketik untuk mencari mesin...',
            loadOptions: (query) async {
              final areaId = _currentAreaId;
              final machines = await notifier.searchMachines(
                query,
                areaId: areaId,
                categoryType: areaId != null ? 4 : null, // Machines category
              );
              return machines
                  .map((m) => AsyncSelectOption(id: m.id, name: m.name))
                  .toList();
            },
            selectedIds: _selectedMachineIds,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedMachineIds.clear();
                _selectedMachineNames.clear();
                _selectedMachineIds.addAll(ids);
                // Store machine names
                for (final id in ids) {
                  final machine = notifier.machines.firstWhere(
                        (m) => m.id == id,
                    orElse: () => DailyTaskMachine(id: id, name: 'Unknown'),
                  );
                  _selectedMachineNames.add(machine.name);
                }
              });
            },
            disabled: isSubmitting,
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Konfirmasi() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Info Tugas
        FormFieldCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'INFO TUGAS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildKonfirmasiRow('Role/Jabatan', _selectedRoleName ?? '-'),
              const SizedBox(height: 8),
              _buildKonfirmasiRow('Jenis Tugas', _selectedItemName ?? '-'),
              const SizedBox(height: 8),
              _buildKonfirmasiRow(
                  'Jumlah Karyawan', '${_selectedEmployeeIds.length} orang'),
              if (_selectedEmployeeNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedEmployeeNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              _buildKonfirmasiRow('Tanggal',
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detail
        FormFieldCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.description, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'DETAIL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildKonfirmasiRow('Target Durasi',
                  _targetMinutesController.text.isEmpty
                      ? '-'
                      : '${_targetMinutesController.text} menit'),
              const SizedBox(height: 8),
              _buildKonfirmasiRow('Catatan',
                  _notesController.text.isEmpty ? '-' : _notesController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Peralatan
        FormFieldCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.build, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'PERALATAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Alat
              if (_selectedToolNames.isNotEmpty) ...[
                const Text(
                  'Alat:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedToolNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.slate300),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Chemical
              if (_selectedChemicalNames.isNotEmpty) ...[
                const Text(
                  'Chemical:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedChemicalNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.slate300),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // APD
              if (_selectedPpeNames.isNotEmpty) ...[
                const Text(
                  'APD:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedPpeNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.slate300),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Mesin (Optional)
              if (_selectedMachineNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Mesin:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedMachineNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.slate300),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKonfirmasiRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DailyTaskNotifier>();
    final isSubmitting = notifier.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Tugas' : 'Step ${_currentStep +
            1} dari $_totalSteps'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepLabels: _stepLabels,
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(notifier, isSubmitting),
                ),
              ),
            ),
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: FButton(
                        onPress: _previousStep,
                        variant: FButtonVariant.outline,
                        child: const Text('SEBELUMNYA'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 1,
                    child: FButton(
                      onPress: isSubmitting ? null : _nextStep,
                      variant: FButtonVariant.primary,
                      child: isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: LoadingIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(_currentStep == _totalSteps - 1
                          ? (_isEditMode ? 'SIMPAN' : 'TUGASKAN')
                          : 'SELANJUTNYA'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
