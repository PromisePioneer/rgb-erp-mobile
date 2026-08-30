import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../providers/daily_task_provider.dart';

/// Form screen for creating a new daily task assignment
class TaskAssignmentFormScreen extends StatefulWidget {
  const TaskAssignmentFormScreen({super.key});

  @override
  State<TaskAssignmentFormScreen> createState() => _TaskAssignmentFormScreenState();
}

class _TaskAssignmentFormScreenState extends State<TaskAssignmentFormScreen> {
  int? _selectedEmployeeId;
  int? _selectedItemId;
  final _targetMinutesController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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
    // Load employees and items on mount - use mobile API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<DailyTaskNotifier>();
      notifier.loadMobileAssignEmployees();
      notifier.loadItems();
    });
  }

  @override
  void dispose() {
    _targetMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih karyawan terlebih dahulu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis tugas terlebih dahulu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final targetMinutes = int.tryParse(_targetMinutesController.text);
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final assignedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final notifier = context.read<DailyTaskNotifier>();
    final success = await notifier.mobileAssignTask(
      employeeId: _selectedEmployeeId!,
      itemId: _selectedItemId,
      targetMinutes: targetMinutes,
      notes: notes,
      assignedDate: assignedDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil ditugaskan'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.error ?? 'Gagal membuat tugas'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DailyTaskNotifier>();
    final employees = notifier.mobileAssignEmployees;
    final items = notifier.items;
    final isLoading = notifier.isLoading;
    final isSubmitting = notifier.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Tugaskan Tugas Harian'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Item/Jenis Tugas dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading && items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tidak ada jenis tugas tersedia'),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedItemId,
                          hint: const Text('Pilih Jenis Tugas'),
                          isExpanded: true,
                          items: items.map((item) {
                            return DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            );
                          }).toList(),
                          onChanged: (isSubmitting || isLoading)
                              ? null
                              : (value) => setState(() => _selectedItemId = value),
                        ),
                      ),
          ),
          const SizedBox(height: 16),

          // Employee dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading && employees.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : employees.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tidak ada karyawan tersedia'),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedEmployeeId,
                          hint: const Text('Pilih Karyawan'),
                          isExpanded: true,
                          items: employees.map((emp) {
                            final id = emp['id'] as int?;
                            final name = emp['name'] as String? ?? '';
                            final code = emp['code'] as String? ?? '';
                            return DropdownMenuItem(
                              value: id,
                              child: Text('$name ($code)'),
                            );
                          }).toList(),
                          onChanged: (isSubmitting || isLoading)
                              ? null
                              : (value) => setState(() => _selectedEmployeeId = value),
                        ),
                      ),
          ),
          const SizedBox(height: 16),

          // Date picker
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.slate500, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.slate800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _targetMinutesController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Target durasi (menit)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _notesController,
              enabled: !isSubmitting,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Catatan (opsional)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting || _selectedEmployeeId == null || _selectedItemId == null ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.slate300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Tugaskan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
