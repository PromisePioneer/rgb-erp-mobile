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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                        color: isActive ? AppColors.primary : AppColors.slate200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isActive && !isCurrent
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
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
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? AppColors.primary : AppColors.slate500,
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

/// Form wizard screen for creating a new daily task assignment
class TaskAssignmentFormScreen extends StatefulWidget {
  const TaskAssignmentFormScreen({super.key});

  @override
  State<TaskAssignmentFormScreen> createState() => _TaskAssignmentFormScreenState();
}

class _TaskAssignmentFormScreenState extends State<TaskAssignmentFormScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form data
  final Set<int> _selectedEmployeeIds = {};
  final Set<String> _selectedEmployeeNames = {};
  int? _selectedItemId;
  String? _selectedItemName;
  final _targetMinutesController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Tools, Chemicals, PPE selection
  final Set<int> _selectedToolIds = {};
  final Set<String> _selectedToolNames = {};
  final Set<int> _selectedChemicalIds = {};
  final Set<String> _selectedChemicalNames = {};
  final Set<int> _selectedPpeIds = {};
  final Set<String> _selectedPpeNames = {};

  final List<String> _stepLabels = ['Info', 'Detail', 'Peralatan', 'Konfirmasi'];

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
      final notifier = context.read<DailyTaskNotifier>();
      notifier.loadMobileAssignEmployees();
      notifier.loadItems();
      notifier.loadMasterData();
    });
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
        // Step 1: Jenis tugas dan minimal 1 karyawan wajib
        return _selectedEmployeeIds.isNotEmpty && _selectedItemId != null;
      case 1:
        // Step 2: Target durasi dan catatan wajib
        final hasTargetMinutes = _targetMinutesController.text.trim().isNotEmpty;
        final hasNotes = _notesController.text.trim().isNotEmpty;
        return hasTargetMinutes && hasNotes;
      case 2:
        // Step 3: Alat, Chemical, dan APD wajib
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
          message = 'Pilih jenis tugas dan minimal 1 karyawan';
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
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final assignedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final notifier = context.read<DailyTaskNotifier>();
    final result = await notifier.mobileAssignTask(
      employeeIds: _selectedEmployeeIds.toList(),
      itemId: _selectedItemId,
      targetMinutes: targetMinutes,
      notes: notes,
      assignedDate: assignedDate,
      toolIds: _selectedToolIds.isEmpty ? null : _selectedToolIds.toList(),
      chemicalIds: _selectedChemicalIds.isEmpty ? null : _selectedChemicalIds.toList(),
      ppeIds: _selectedPpeIds.isEmpty ? null : _selectedPpeIds.toList(),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas berhasil ditugaskan ke ${_selectedEmployeeIds.length} karyawan'),
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
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Jenis Tugas - AsyncSelectField
        FormFieldCard(
          child: AsyncSelectField(
            label: 'JENIS TUGAS',
            placeholder: 'Pilih Jenis Tugas',
            loadOptions: (query) async {
              final items = await notifier.searchItems(query);
              return items
                  .map((item) => AsyncSelectOption(id: item.id, name: item.name))
                  .toList();
            },
            selectedIds: _selectedItemId != null ? {_selectedItemId!} : {},
            onSelectionChanged: (ids) {
              setState(() {
                _selectedItemId = ids.isNotEmpty ? ids.first : null;
                if (_selectedItemId != null) {
                  final item = notifier.items.firstWhere((i) => i.id == _selectedItemId);
                  _selectedItemName = item.name;
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
            placeholder: 'Pilih karyawan untuk tugas tim',
            loadOptions: (query) async {
              final employees = await notifier.searchMobileAssignEmployees(query);
              return employees
                  .map((emp) => AsyncSelectOption(
                        id: emp['id'] as int,
                        name: '${emp['name']} (${emp['code'] ?? ''})',
                      ))
                  .toList();
            },
            selectedIds: _selectedEmployeeIds,
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
            disabled: isSubmitting,
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
                  const Icon(Icons.calendar_today, color: AppColors.slate500, size: 20),
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
                          DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.slate800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.slate500, size: 20),
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
                hint: 'Masukkan catatan (opsional)',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Peralatan(DailyTaskNotifier notifier, bool isSubmitting) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Alat - AsyncSelectField
        FormFieldCard(
          child: AsyncSelectField(
            label: 'ALAT YANG DIGUNAKAN',
            placeholder: 'Ketik untuk mencari alat...',
            loadOptions: (query) async {
              final tools = await notifier.searchTools(query);
              return tools
                  .map((t) => AsyncSelectOption(id: t.id, name: t.name))
                  .toList();
            },
            selectedIds: _selectedToolIds,
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
              final chemicals = await notifier.searchChemicals(query);
              return chemicals
                  .map((c) => AsyncSelectOption(id: c.id, name: c.name))
                  .toList();
            },
            selectedIds: _selectedChemicalIds,
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
              final ppes = await notifier.searchPpes(query);
              return ppes
                  .map((p) => AsyncSelectOption(id: p.id, name: p.name))
                  .toList();
            },
            selectedIds: _selectedPpeIds,
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
              _buildKonfirmasiRow('Jenis Tugas', _selectedItemName ?? '-'),
              const SizedBox(height: 8),
              _buildKonfirmasiRow('Jumlah Karyawan', '${_selectedEmployeeIds.length} orang'),
              if (_selectedEmployeeNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedEmployeeNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              _buildKonfirmasiRow('Tanggal', DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)),
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
              _buildKonfirmasiRow('Target Durasi', _targetMinutesController.text.isEmpty ? '-' : '${_targetMinutesController.text} menit'),
              const SizedBox(height: 8),
              _buildKonfirmasiRow('Catatan', _notesController.text.isEmpty ? '-' : _notesController.text),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        title: Text('Step ${_currentStep + 1} dari $_totalSteps'),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep == _totalSteps - 1 ? 'TUGASKAN' : 'SELANJUTNYA'),
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
