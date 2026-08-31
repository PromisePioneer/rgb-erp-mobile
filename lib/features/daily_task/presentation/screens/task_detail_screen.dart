import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/daily_task.dart';
import '../providers/daily_task_provider.dart';

/// Task detail screen - shows task info and allows start/finish
class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ImagePicker _picker = ImagePicker();

  // Form state for start - multiple photos
  final List<String> _beforePhotoPaths = [];
  final Set<int> _selectedTools = {};
  final Set<int> _selectedChemicals = {};
  final Set<int> _selectedPpes = {};

  // Form state for finish - multiple photos
  final List<String> _afterPhotoPaths = [];
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final notifier = context.read<DailyTaskNotifier>();
    // Run both requests in parallel - they update separate state fields now
    // so there's no race condition
    await Future.wait([
      notifier.loadTaskDetail(widget.taskId),
      notifier.loadMasterData(),
    ]);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({
    required bool isBefore,
    required ImageSource source,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isBefore) {
            _beforePhotoPaths.add(image.path);
          } else {
            _afterPhotoPaths.add(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _removePhoto({required bool isBefore, required int index}) {
    setState(() {
      if (isBefore) {
        _beforePhotoPaths.removeAt(index);
      } else {
        _afterPhotoPaths.removeAt(index);
      }
    });
  }

  void _showFullScreenPhoto(String imageUrl, String type) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            type.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLocalFullScreenPhoto(String filePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'FOTO',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartTask() async {
    if (_beforePhotoPaths.isEmpty) {
      _showErrorDialog('Foto Sebelum', 'Silakan ambil foto sebelum bekerja.');
      return;
    }

    final notifier = context.read<DailyTaskNotifier>();
    final success = await notifier.startTask(
      taskId: widget.taskId,
      photos: _beforePhotoPaths,
      toolIds: _selectedTools.toList(),
      chemicalIds: _selectedChemicals.toList(),
      ppeIds: _selectedPpes.toList(),
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog('Tugas dimulai', 'Tugas berhasil dimulai. Selamat bekerja!');
    } else {
      _showErrorDialog('Gagal', notifier.error ?? 'Terjadi kesalahan.');
    }
  }

  Future<void> _handleFinishTask() async {
    if (_afterPhotoPaths.isEmpty) {
      _showErrorDialog('Foto Sesudah', 'Silakan ambil foto setelah bekerja.');
      return;
    }

    final notifier = context.read<DailyTaskNotifier>();
    final success = await notifier.finishTask(
      taskId: widget.taskId,
      photos: _afterPhotoPaths,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog('Tugas Selesai', 'Tugas berhasil diselesaikan!');
    } else {
      _showErrorDialog('Gagal', notifier.error ?? 'Terjadi kesalahan.');
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

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(IconMap.checkCircle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
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
        title: const Text('Detail Tugas'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
      ),
      body: Consumer<DailyTaskNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoading && notifier.selectedTask == null) {
            return const Center(child: LoadingIndicator());
          }

          final task = notifier.selectedTask;
          if (task == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconMap.errorOutline,
                      size: 48, color: theme.colors.destructive),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tugas tidak ditemukan',
                    style: TextStyle(color: theme.colors.foreground),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FButton(
                    onPress: () => context.pop(),
                    variant: FButtonVariant.outline,
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Task info card
                  _buildTaskInfoCard(task, theme),
                  const SizedBox(height: AppSpacing.md),

                  // Form based on status
                  if (task.canStart) ...[
                    // Start form
                    _buildPhotoSection(
                      label: 'Foto Sebelum',
                      photoPaths: _beforePhotoPaths,
                      isBefore: true,
                      enabled: true,
                      theme: theme,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Tools selection
                    _buildChoiceChipSection(
                      label: 'Alat yang Digunakan',
                      items: notifier.tools,
                      selectedIds: _selectedTools,
                      theme: theme,
                      isLoading: notifier.isLoadingMasterData && !notifier.masterDataWasLoaded,
                      errorMessage: notifier.masterDataError,
                      onRetry: () => notifier.retryLoadMasterData(),
                      onToggle: (id) {
                        setState(() {
                          if (_selectedTools.contains(id)) {
                            _selectedTools.remove(id);
                          } else {
                            _selectedTools.add(id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Chemicals selection
                    _buildChoiceChipSection(
                      label: 'Chemical yang Digunakan',
                      items: notifier.chemicals,
                      selectedIds: _selectedChemicals,
                      theme: theme,
                      isLoading: notifier.isLoadingMasterData && !notifier.masterDataWasLoaded,
                      errorMessage: notifier.masterDataError,
                      onRetry: () => notifier.retryLoadMasterData(),
                      onToggle: (id) {
                        setState(() {
                          if (_selectedChemicals.contains(id)) {
                            _selectedChemicals.remove(id);
                          } else {
                            _selectedChemicals.add(id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // PPE selection
                    _buildChoiceChipSection(
                      label: 'Alat Pelindung Diri',
                      items: notifier.ppes,
                      selectedIds: _selectedPpes,
                      theme: theme,
                      isLoading: notifier.isLoadingMasterData && !notifier.masterDataWasLoaded,
                      errorMessage: notifier.masterDataError,
                      onRetry: () => notifier.retryLoadMasterData(),
                      onToggle: (id) {
                        setState(() {
                          if (_selectedPpes.contains(id)) {
                            _selectedPpes.remove(id);
                          } else {
                            _selectedPpes.add(id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    PrimaryButton(
                      label: 'Mulai Kerjakan',
                      icon: IconMap.playCircle,
                      isLoading: notifier.isSubmitting,
                      onPressed: _handleStartTask,
                    ),
                  ] else if (task.canFinish) ...[
                    // Finish form
                    _buildInProgressInfo(task, theme),
                    const SizedBox(height: AppSpacing.md),

                    _buildPhotoSection(
                      label: 'Foto Sesudah',
                      photoPaths: _afterPhotoPaths,
                      isBefore: false,
                      enabled: true,
                      theme: theme,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Notes field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATATAN (OPSIONAL)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colors.mutedForeground,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Tambahkan catatan...',
                            hintStyle:
                                TextStyle(color: theme.colors.mutedForeground),
                            filled: true,
                            fillColor: theme.colors.card,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.radiusMd,
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.all(AppSpacing.md),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    PrimaryButton(
                      label: 'Selesai',
                      icon: IconMap.checkCircle,
                      isLoading: notifier.isSubmitting,
                      onPressed: _handleFinishTask,
                    ),
                  ] else ...[
                    // Read-only view (completed/reviewed)
                    _buildReadOnlyView(task, theme),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),

              if (notifier.isLoading)
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

  Widget _buildPhotoSection({
    required String label,
    required List<String> photoPaths,
    required bool isBefore,
    required bool enabled,
    required FThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (photoPaths.isNotEmpty)
              Text(
                '${photoPaths.length} foto',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colors.mutedForeground,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: theme.colors.border),
          ),
          child: photoPaths.isNotEmpty
              ? Column(
                  children: [
                    // Photo grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1,
                      ),
                      itemCount: photoPaths.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            GestureDetector(
                              onTap: () => _showLocalFullScreenPhoto(photoPaths[index]),
                              child: ClipRRect(
                                borderRadius: AppRadius.radiusSm,
                                child: Image.file(
                                  File(photoPaths[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: theme.colors.muted,
                                    child: Icon(
                                      IconMap.brokenImage,
                                      size: 32,
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (enabled)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(
                                    isBefore: isBefore,
                                    index: index,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
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
                    if (enabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: FButton(
                              onPress: () => _pickPhoto(
                                isBefore: isBefore,
                                source: ImageSource.camera,
                              ),
                              variant: FButtonVariant.outline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconMap.cameraAlt, size: 18),
                                  const SizedBox(width: 4),
                                  const Text('Kamera'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FButton(
                              onPress: () => _pickPhoto(
                                isBefore: isBefore,
                                source: ImageSource.gallery,
                              ),
                              variant: FButtonVariant.outline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconMap.photoLibrary, size: 18),
                                  const SizedBox(width: 4),
                                  const Text('Galeri'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      IconMap.cameraAlt,
                      size: 48,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      enabled ? 'Ambil foto' : 'Belum ada foto',
                      style: TextStyle(color: theme.colors.mutedForeground),
                    ),
                    if (enabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: FButton(
                              onPress: () => _pickPhoto(
                                isBefore: isBefore,
                                source: ImageSource.camera,
                              ),
                              variant: FButtonVariant.outline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconMap.cameraAlt, size: 18),
                                  const SizedBox(width: 4),
                                  const Text('Kamera'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FButton(
                              onPress: () => _pickPhoto(
                                isBefore: isBefore,
                                source: ImageSource.gallery,
                              ),
                              variant: FButtonVariant.outline,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(IconMap.photoLibrary, size: 18),
                                  const SizedBox(width: 4),
                                  const Text('Galeri'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildChoiceChipSection({
    required String label,
    required List items,
    required Set<int> selectedIds,
    required FThemeData theme,
    required void Function(int id) onToggle,
    // State indicators for proper UI feedback
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    // Show skeleton while loading
    if (isLoading) {
      return _buildChoiceChipSkeleton(label: label, theme: theme);
    }

    // Show error state with retry button
    if (errorMessage != null) {
      return _buildChoiceChipError(
        label: label,
        errorMessage: errorMessage,
        theme: theme,
        onRetry: onRetry,
      );
    }

    // Show "Belum ada data" when API succeeded but empty
    if (items.isEmpty) {
      return _buildChoiceChipEmpty(label: label, theme: theme);
    }

    // Normal state - show chips
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
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
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: items.map((item) {
              final id = item.id as int;
              final name = item.name as String;
              final isSelected = selectedIds.contains(id);

              return FilterChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) => onToggle(id),
                backgroundColor: theme.colors.card,
                selectedColor: AppColors.primary.withAlpha(51),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : theme.colors.border,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : theme.colors.foreground,
                  fontSize: 14,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading state for choice chip section
  Widget _buildChoiceChipSkeleton({
    required String label,
    required FThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label skeleton
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Chip skeletons
          Row(
            children: [
              _buildChipSkeleton(theme: theme),
              const SizedBox(width: AppSpacing.xs),
              _buildChipSkeleton(theme: theme),
              const SizedBox(width: AppSpacing.xs),
              _buildChipSkeleton(theme: theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipSkeleton({required FThemeData theme}) {
    return Container(
      width: 80,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// Error state with retry button
  Widget _buildChoiceChipError({
    required String label,
    required String errorMessage,
    required FThemeData theme,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.danger.withAlpha(77)),
      ),
      child: Column(
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                IconMap.errorOutline,
                size: 16,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Gagal memuat data',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.danger,
                  ),
                ),
              ),
              if (onRetry != null)
                FButton(
                  onPress: onRetry,
                  variant: FButtonVariant.ghost,
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty state when API succeeds but returns no data
  Widget _buildChoiceChipEmpty({
    required String label,
    required FThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada data',
            style: TextStyle(
              fontSize: 13,
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoCard(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(task, theme).withAlpha(26),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  task.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(task, theme),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            task.itemName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
          ),
          if (task.itemDescription != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              task.itemDescription!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
          if (task.areaName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(IconMap.locationOn,
                    size: 18, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  task.areaName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ],
          if (task.targetMinutes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(IconMap.timer, size: 18, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Target: ${task.targetMinutes} menit',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colors.foreground,
                  ),
                ),
                if (task.targetNote != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(${task.targetNote})',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInProgressInfo(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(26),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.warning.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.timer, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Sedang Dikerjakan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          if (task.startAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mulai: ${_formatDateTime(task.startAt!)}',
              style: TextStyle(
                fontSize: 13,
                color: theme.colors.foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyView(DailyTask task, FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos
        if (task.photos.isNotEmpty) ...[
          Text(
            'FOTO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colors.mutedForeground,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: task.photos.length,
              itemBuilder: (ctx, i) {
                final photo = task.photos[i];
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: i < task.photos.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFullScreenPhoto(photo.url, photo.type),
                          child: Hero(
                            tag: 'photo_${photo.id}',
                            child: ClipRRect(
                              borderRadius: AppRadius.radiusSm,
                              child: Image.network(
                                photo.url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (c, e, s) => Container(
                                  color: theme.colors.muted,
                                  child: Icon(
                                    IconMap.brokenImage,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                loadingBuilder: (c, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: theme.colors.muted,
                                    child: const Center(
                                      child: LoadingIndicator(size: 24),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        photo.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Equipment used
        _buildUsedItemsList('Alat', task.tools, theme),
        _buildUsedItemsList('Chemical', task.chemicals, theme),
        _buildUsedItemsList('APD', task.ppes, theme),

        // Time info
        if (task.startAt != null || task.endAt != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Column(
              children: [
                if (task.startAt != null)
                  _buildTimeRow('Mulai', task.startAt!, theme),
                if (task.startAt != null && task.endAt != null)
                  const Divider(height: AppSpacing.md),
                if (task.endAt != null)
                  _buildTimeRow('Selesai', task.endAt!, theme),
                if (task.durationMinutes != null) ...[
                  const Divider(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Durasi',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        '${task.durationMinutes} menit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Notes
        if (task.notes != null && task.notes!.isNotEmpty) ...[
          Text(
            'CATATAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colors.mutedForeground,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Text(
              task.notes!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.foreground,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Review
        if (task.reviews != null && task.reviews!.isNotEmpty) ...[
          Text(
            'REVIEW LEADER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colors.mutedForeground,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final review in task.reviews!)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colors.card,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (review.reviewerName != null)
                        Text(
                          review.reviewerName!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colors.foreground,
                          ),
                        ),
                      if (review.averageScore != null)
                        Row(
                          children: [
                            Icon(IconMap.star, size: 18, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              review.averageScore!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colors.foreground,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (review.notes != null && review.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      review.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                  if (review.scores.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ...review.scores.map((s) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.criteriaName ?? 'Kriteria ${s.criteriaId}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colors.foreground,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    IconMap.star,
                                    size: 14,
                                    color: i < s.score
                                        ? AppColors.warning
                                        : theme.colors.mutedForeground,
                                  );
                                }),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildUsedItemsList(
    String label,
    List<dynamic>? items,
    FThemeData theme,
  ) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

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
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: items.map((item) {
            final name = item is DailyTaskTool
                ? item.name
                : item is DailyTaskChemical
                    ? item.name
                    : item is DailyTaskPpe
                        ? item.name
                        : 'Unknown';
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colors.foreground,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildTimeRow(String label, DateTime time, FThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          _formatDateTime(time),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(DailyTask task, FThemeData theme) {
    switch (task.status) {
      case 'assigned':
        return theme.colors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'reviewed':
        return AppColors.info;
      default:
        return theme.colors.mutedForeground;
    }
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
