import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
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
    final theme = FTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Row(
          children: [
            Icon(IconMap.errorOutline, color: theme.colors.destructive),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          FButton(
            onPress: () => Navigator.pop(ctx),
            variant: FButtonVariant.ghost,
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    final theme = FTheme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(IconMap.checkCircle, color: theme.colors.primary),
            const SizedBox(width: 8),
            const Text('Berhasil'),
          ],
        ),
        content: const Text('Temuan pelanggaran berhasil disimpan.'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'OK',
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Lapor Pelanggaran'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
      ),
      body: Consumer<ViolationReportNotifier>(
        builder: (context, notifier, child) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Area dropdown
                  _buildSection(
                    'Area/Site',
                    _buildAreaDropdown(notifier),
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
                    icon: IconMap.send,
                    isLoading: notifier.state.isSubmitting,
                    onPressed: notifier.state.canSubmit ? _handleSubmit : null,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),

              // Loading overlay
              if (notifier.state.isLoadingAreas || notifier.state.isLoadingTypes)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: LoadingIndicator(size: 48),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String label, Widget child) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildAreaDropdown(ViolationReportNotifier notifier) {
    final theme = FTheme.of(context);
    final areas = notifier.state.areas;
    final selected = notifier.state.selectedArea;
    final isLoading = notifier.state.isLoadingAreas;
    final error = notifier.state.areasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: BorderRadius.circular(12),
            border: error != null ? Border.all(color: theme.colors.destructive) : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ViolationArea>(
              value: selected,
              hint: Text(
                isLoading
                    ? 'Memuat...'
                    : areas.isEmpty
                        ? 'Tidak ada site'
                        : 'Pilih area',
                style: TextStyle(
                  color: theme.colors.mutedForeground,
                ),
              ),
              isExpanded: true,
              items: areas.map((p) {
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
                      if (v != null) notifier.selectArea(v);
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
              color: theme.colors.destructive,
            ),
          ),
        ],
        if (areas.isEmpty && !isLoading && error == null) ...[
          const SizedBox(height: 4),
          Text(
            'Tidak ada area yang tersedia',
            style: TextStyle(
              fontSize: 12,
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmployeeDropdown(ViolationReportNotifier notifier) {
    final theme = FTheme.of(context);
    final employees = notifier.state.employees;
    final selected = notifier.state.selectedEmployee;
    final isLoading = notifier.state.isLoadingEmployees;
    final error = notifier.state.employeesError;
    final hasArea = notifier.state.selectedArea != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
        border: error != null ? Border.all(color: theme.colors.destructive) : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ViolationEmployee>(
          value: selected,
          hint: Text(
            !hasArea
                ? 'Pilih site dulu'
                : isLoading
                    ? 'Memuat...'
                    : 'Pilih karyawan',
            style: TextStyle(color: theme.colors.mutedForeground),
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
          onChanged: !hasArea || isLoading
              ? null
              : (v) {
                  if (v != null) notifier.selectEmployee(v);
                },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ViolationReportNotifier notifier) {
    final theme = FTheme.of(context);
    final types = notifier.state.violationTypes;
    final selected = notifier.state.selectedCategory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ViolationType>(
          value: selected,
          hint: Text(
            'Pilih kategori',
            style: TextStyle(color: theme.colors.mutedForeground),
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
    final theme = FTheme.of(context);
    final children = notifier.state.selectedCategory?.children ?? [];
    final selected = notifier.state.selectedViolationType;

    if (children.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Tidak ada sub-kategori',
          style: TextStyle(color: theme.colors.mutedForeground),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ViolationType>(
          value: selected,
          hint: Text(
            'Pilih jenis pelanggaran',
            style: TextStyle(color: theme.colors.mutedForeground),
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
    final theme = FTheme.of(context);
    final photos = notifier.state.photos;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: () => notifier.addPhoto(),
                  variant: FButtonVariant.outline,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconMap.cameraAlt),
                      const SizedBox(width: 8),
                      const Text('Kamera'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FButton(
                  onPress: () => notifier.pickPhotoFromGallery(),
                  variant: FButtonVariant.outline,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconMap.photoLibrary),
                      const SizedBox(width: 8),
                      const Text('Galeri'),
                    ],
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
                              color: theme.colors.muted,
                              child: Icon(
                                IconMap.brokenImage,
                                color: theme.colors.mutedForeground,
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
                              color: theme.colors.destructive,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconMap.close,
                              size: 16,
                              color: theme.colors.destructiveForeground,
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
    final theme = FTheme.of(context);
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Tambahkan catatan...',
        hintStyle: TextStyle(color: theme.colors.mutedForeground),
        filled: true,
        fillColor: theme.colors.card,
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
    final theme = FTheme.of(context);
    return TextField(
      controller: _actionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Tindakan yang dilakukan...',
        hintStyle: TextStyle(color: theme.colors.mutedForeground),
        filled: true,
        fillColor: theme.colors.card,
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
    final theme = FTheme.of(context);
    final location = notifier.state.location;
    final error = notifier.state.locationError;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: location != null ? theme.colors.primary.withAlpha(25) : theme.colors.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: location != null ? theme.colors.primary : theme.colors.destructive,
        ),
      ),
      child: Row(
        children: [
          Icon(
            location != null ? IconMap.locationOn : IconMap.locationOff,
            color: location != null ? theme.colors.primary : theme.colors.destructive,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              location != null
                  ? 'Lokasi: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'
                  : error ?? 'Lokasi belum tersedia',
              style: TextStyle(
                color: location != null ? theme.colors.primary : theme.colors.destructive,
                fontSize: 14,
              ),
            ),
          ),
          if (location == null)
            TextButton(
              onPressed: () => notifier.getLocation(),
              child: Text(
                'Coba Lagi',
                style: TextStyle(color: theme.colors.destructive),
              ),
            ),
        ],
      ),
    );
  }
}
