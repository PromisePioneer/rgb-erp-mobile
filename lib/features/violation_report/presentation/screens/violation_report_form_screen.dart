import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../domain/domain.dart';
import '../providers/violation_report_provider.dart';

/// Violation report form screen
class ViolationReportFormScreen extends StatefulWidget {
  const ViolationReportFormScreen({super.key});

  @override
  State<ViolationReportFormScreen> createState() => _ViolationReportFormScreenState();
}

class _ViolationReportFormScreenState extends State<ViolationReportFormScreen> {
  final _notesController = TextEditingController();
  final _actionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<ViolationReportNotifier>();
      notifier.reset();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notifier = context.read<ViolationReportNotifier>();

    // Get location first
    await notifier.getLocation();
    if (!mounted) return;

    // Validate time
    await notifier.validateTime();
    if (!mounted) return;

    if (notifier.state.locationError != null) {
      _showErrorDialog(
        'Lokasi Tidak Valid',
        notifier.state.locationError!,
      );
      return;
    }

    if (!notifier.state.isTimeValid) {
      _showErrorDialog(
        'Waktu Tidak Valid',
        'Waktu perangkat tidak valid. Mohon perbarui waktu otomatis di pengaturan perangkat.',
      );
      return;
    }

    // Submit
    final success = await notifier.submit();
    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(
        'Gagal',
        notifier.state.submitError ?? 'Terjadi kesalahan saat menyimpan temuan.',
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.danger),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Berhasil'),
          ],
        ),
        content: Text('Temuan pelanggaran berhasil disimpan.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Lapor Pelanggaran'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: Consumer<ViolationReportNotifier>(
        builder: (context, notifier, child) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Project dropdown
                  _buildSection(
                    'Project/Site',
                    _buildProjectDropdown(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Employee dropdown
                  _buildSection(
                    'Karyawan Pelanggar',
                    _buildEmployeeDropdown(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Violation category dropdown
                  _buildSection(
                    'Kategori Pelanggaran',
                    _buildCategoryDropdown(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Violation type dropdown (if category selected)
                  if (notifier.state.selectedCategory != null)
                    _buildSection(
                      'Jenis Pelanggaran',
                      _buildViolationTypeDropdown(notifier),
                    ),
                  if (notifier.state.selectedCategory != null)
                    const SizedBox(height: AppSpacing.md),

                  // Photos
                  _buildSection(
                    'Foto Bukti (Opsional)',
                    _buildPhotoSection(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  _buildSection(
                    'Catatan (Opsional)',
                    _buildNotesField(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Action
                  _buildSection(
                    'Tindakan yang Dilakukan',
                    _buildActionField(notifier),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location status
                  _buildLocationStatus(notifier),
                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  PrimaryButton(
                    label: 'Simpan Temuan',
                    icon: Icons.send,
                    isLoading: notifier.state.isSubmitting,
                    onPressed: notifier.state.canSubmit ? _handleSubmit : null,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),

              // Loading overlay
              if (notifier.state.isLoadingProjects || notifier.state.isLoadingTypes)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildProjectDropdown(ViolationReportNotifier notifier) {
    final projects = notifier.state.projects;
    final selected = notifier.state.selectedProject;
    final isLoading = notifier.state.isLoadingProjects;
    final error = notifier.state.projectsError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: error != null ? Border.all(color: AppColors.danger) : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ViolationProject>(
              value: selected,
              hint: Text(
                isLoading
                    ? 'Memuat...'
                    : projects.isEmpty
                        ? 'Tidak ada project'
                        : 'Pilih project/site',
                style: TextStyle(
                  color: projects.isEmpty ? AppColors.gray400 : AppColors.gray400,
                ),
              ),
              isExpanded: true,
              items: projects.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (v) {
                      if (v != null) notifier.selectProject(v);
                    },
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.danger,
            ),
          ),
        ],
        if (projects.isEmpty && !isLoading && error == null) ...[
          const SizedBox(height: 4),
          Text(
            'Tidak ada project/site yang tersedia',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmployeeDropdown(ViolationReportNotifier notifier) {
    final employees = notifier.state.employees;
    final selected = notifier.state.selectedEmployee;
    final isLoading = notifier.state.isLoadingEmployees;
    final error = notifier.state.employeesError;
    final hasProject = notifier.state.selectedProject != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: error != null ? Border.all(color: AppColors.danger) : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ViolationEmployee>(
          value: selected,
          hint: Text(
            !hasProject
                ? 'Pilih project dulu'
                : isLoading
                    ? 'Memuat...'
                    : 'Pilih karyawan',
            style: TextStyle(color: AppColors.gray400),
          ),
          isExpanded: true,
          items: employees.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(
                '${e.name} (${e.code})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: !hasProject || isLoading
              ? null
              : (v) {
                  if (v != null) notifier.selectEmployee(v);
                },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ViolationReportNotifier notifier) {
    final types = notifier.state.violationTypes;
    final selected = notifier.state.selectedCategory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ViolationType>(
          value: selected,
          hint: Text(
            'Pilih kategori',
            style: TextStyle(color: AppColors.gray400),
          ),
          isExpanded: true,
          items: types.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.name),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) notifier.selectCategory(v);
          },
        ),
      ),
    );
  }

  Widget _buildViolationTypeDropdown(ViolationReportNotifier notifier) {
    final children = notifier.state.selectedCategory?.children ?? [];
    final selected = notifier.state.selectedViolationType;

    if (children.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Tidak ada sub-kategori',
          style: TextStyle(color: AppColors.gray400),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ViolationType>(
          value: selected,
          hint: Text(
            'Pilih jenis pelanggaran',
            style: TextStyle(color: AppColors.gray400),
          ),
          isExpanded: true,
          items: children.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c.name),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) notifier.selectViolationType(v);
          },
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ViolationReportNotifier notifier) {
    final photos = notifier.state.photos;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.addPhoto(),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.pickPhotoFromGallery(),
                  icon: Icon(Icons.photo_library),
                  label: Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (ctx, i) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(photos[i].path),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.gray200,
                              child: Icon(
                                Icons.broken_image,
                                color: AppColors.gray400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => notifier.removePhoto(i),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesField(ViolationReportNotifier notifier) {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Tambahkan catatan...',
        hintStyle: TextStyle(color: AppColors.gray400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      onChanged: (v) => notifier.updateNotes(v),
    );
  }

  Widget _buildActionField(ViolationReportNotifier notifier) {
    return TextField(
      controller: _actionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Tindakan yang dilakukan...',
        hintStyle: TextStyle(color: AppColors.gray400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      onChanged: (v) => notifier.updateAction(v),
    );
  }

  Widget _buildLocationStatus(ViolationReportNotifier notifier) {
    final location = notifier.state.location;
    final error = notifier.state.locationError;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: location != null ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: location != null ? AppColors.success : AppColors.danger,
        ),
      ),
      child: Row(
        children: [
          Icon(
            location != null ? Icons.location_on : Icons.location_off,
            color: location != null ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              location != null
                  ? 'Lokasi: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'
                  : error ?? 'Lokasi belum tersedia',
              style: TextStyle(
                color: location != null ? AppColors.success : AppColors.danger,
                fontSize: 14,
              ),
            ),
          ),
          if (location == null)
            TextButton(
              onPressed: () => notifier.getLocation(),
              child: Text(
                'Coba Lagi',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
