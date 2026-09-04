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
import '../../../../shared/widgets/inputs/app_text_field.dart';
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

  // Form state for finish - multiple photos
  final List<String> _afterPhotoPaths = [];
  final _notesController = TextEditingController();

  // Condition tracking state
  // For tools, PPEs, and Machines: excellent, good, fair, poor, replace
  // For chemicals: full, half, low
  final Map<int, String> _initialToolConditions = {};
  final Map<int, String> _initialPpeConditions = {};
  final Map<int, String> _initialMachineConditions = {};
  final Map<int, String> _initialChemicalConditions = {};
  final Map<int, String> _finalToolConditions = {};
  final Map<int, String> _finalPpeConditions = {};
  final Map<int, String> _finalMachineConditions = {};
  final Map<int, String> _finalChemicalConditions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final notifier = context.read<DailyTaskNotifier>();
    // Load task detail - tools/chemicals/ppes sudah dari API
    notifier.loadTaskDetail(widget.taskId);
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

  /// Validate that final condition is not better than initial condition
  /// Tools/PPE/Machine: SB > B > CB > KB > Ganti
  /// Chemical: Full > Setengah > 1/4
  String? _validateConditionProgression() {
    final task = context.read<DailyTaskNotifier>().selectedTask;
    if (task == null) return null;

    // Helper to compare conditions for tools/PPE
    int conditionRankTool(String? condition) {
      switch (condition) {
        case 'excellent': return 5; // SB (≥85%)
        case 'good': return 4;       // B (≥65%)
        case 'fair': return 3;       // CB (≥45%)
        case 'poor': return 2;        // KB (≥25%)
        case 'replace': return 1;     // Ganti (<25%)
        default: return 0;
      }
    }

    // Helper to compare conditions for chemicals
    int conditionRankChemical(String? condition) {
      switch (condition) {
        case 'full': return 3;     // Full (≥75%)
        case 'half': return 2;     // Setengah (≥50%)
        case 'low': return 1;      // 1/4 (<50%)
        default: return 0;
      }
    }

    // Check tools
    if (task.tools != null) {
      for (final tool in task.tools!) {
        final initial = _initialToolConditions[tool.id];
        final finalCond = _finalToolConditions[tool.id];
        if (initial != null && finalCond != null) {
          if (conditionRankTool(finalCond) > conditionRankTool(initial)) {
            return 'Kondisi akhir ${tool.name} tidak boleh lebih baik dari kondisi awal.\n'
                'Contoh: Jika kondisi awal CB, tidak boleh pilih SB atau B.';
          }
        }
      }
    }

    // Check PPEs
    if (task.ppes != null) {
      for (final ppe in task.ppes!) {
        final initial = _initialPpeConditions[ppe.id];
        final finalCond = _finalPpeConditions[ppe.id];
        if (initial != null && finalCond != null) {
          if (conditionRankTool(finalCond) > conditionRankTool(initial)) {
            return 'Kondisi akhir ${ppe.name} tidak boleh lebih baik dari kondisi awal.';
          }
        }
      }
    }

    // Check chemicals
    if (task.chemicals != null) {
      for (final chem in task.chemicals!) {
        final initial = _initialChemicalConditions[chem.id];
        final finalCond = _finalChemicalConditions[chem.id];
        if (initial != null && finalCond != null) {
          if (conditionRankChemical(finalCond) > conditionRankChemical(initial)) {
            return 'Kondisi akhir ${chem.name} tidak boleh lebih baik dari kondisi awal.';
          }
        }
      }
    }

    // Check machines (same condition as tools/PPE)
    if (task.machines != null) {
      for (final machine in task.machines!) {
        final initial = _initialMachineConditions[machine.id];
        final finalCond = _finalMachineConditions[machine.id];
        if (initial != null && finalCond != null) {
          if (conditionRankTool(finalCond) > conditionRankTool(initial)) {
            return 'Kondisi akhir ${machine.name} tidak boleh lebih baik dari kondisi awal.';
          }
        }
      }
    }

    return null;
  }

  Future<void> _handleStartTask() async {
    if (_beforePhotoPaths.isEmpty) {
      _showErrorDialog('Foto Sebelum', 'Silakan ambil foto sebelum bekerja.');
      return;
    }

    // Get task to check if there are tools/chemicals/ppes/machines that need conditions
    final task = context.read<DailyTaskNotifier>().selectedTask;
    final hasItems = (task?.tools?.isNotEmpty ?? false) ||
        (task?.chemicals?.isNotEmpty ?? false) ||
        (task?.ppes?.isNotEmpty ?? false) ||
        (task?.machines?.isNotEmpty ?? false);

    // Validate conditions if there are items
    if (hasItems) {
      final hasToolConditions = _initialToolConditions.isNotEmpty;
      final hasPpeConditions = _initialPpeConditions.isNotEmpty;
      final hasMachineConditions = _initialMachineConditions.isNotEmpty;
      final hasChemicalConditions = _initialChemicalConditions.isNotEmpty;

      if (!hasToolConditions && !hasPpeConditions && !hasMachineConditions && !hasChemicalConditions) {
        _showErrorDialog('Kondisi Awal', 'Silakan pilih kondisi alat, APD, mesin, dan chemical sebelum bekerja.');
        return;
      }
    }

    // Build condition data for tools
    final toolConditions = _initialToolConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    // Build condition data for PPEs
    final ppeConditions = _initialPpeConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    // Build condition data for machines
    final machineConditions = _initialMachineConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    // Build condition data for chemicals
    final chemicalConditions = _initialChemicalConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    final notifier = context.read<DailyTaskNotifier>();
    final success = await notifier.startTask(
      taskId: widget.taskId,
      photos: _beforePhotoPaths,
      toolConditions: toolConditions.isNotEmpty ? toolConditions : null,
      ppeConditions: ppeConditions.isNotEmpty ? ppeConditions : null,
      machineConditions: machineConditions.isNotEmpty ? machineConditions : null,
      chemicalConditions: chemicalConditions.isNotEmpty ? chemicalConditions : null,
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

    // Validate final conditions are not better than initial conditions
    final validationError = _validateConditionProgression();
    if (validationError != null) {
      _showErrorDialog('Kondisi Tidak Valid', validationError);
      return;
    }

    // Build condition data for tools
    final toolConditions = _finalToolConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    // Build condition data for PPEs
    final ppeConditions = _finalPpeConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    // Build condition data for machines
    final machineConditions = _finalMachineConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    // Build condition data for chemicals
    final chemicalConditions = _finalChemicalConditions.entries
        .map((e) => {'product_id': e.key.toString(), 'condition': e.value})
        .toList();

    final notifier = context.read<DailyTaskNotifier>();
    final success = await notifier.finishTask(
      taskId: widget.taskId,
      photos: _afterPhotoPaths,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      toolConditions: toolConditions.isNotEmpty ? toolConditions : null,
      ppeConditions: ppeConditions.isNotEmpty ? ppeConditions : null,
      machineConditions: machineConditions.isNotEmpty ? machineConditions : null,
      chemicalConditions: chemicalConditions.isNotEmpty ? chemicalConditions : null,
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
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md + MediaQuery.of(context).padding.bottom + 80,
                ),
                children: [
                  // Task info card
                  _buildTaskInfoCard(task, theme),
                  const SizedBox(height: AppSpacing.md),

                  // Form based on status
                  if (task.canStart) ...[
                    // Start form - employee perlu input kondisi awal alat & bahan
                    _buildPhotoSection(
                      label: 'Foto Sebelum',
                      photoPaths: _beforePhotoPaths,
                      isBefore: true,
                      enabled: true,
                      theme: theme,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Show tools/chemicals/ppes/machines with condition selection (initial)
                    if ((task.tools?.isNotEmpty ?? false) ||
                        (task.chemicals?.isNotEmpty ?? false) ||
                        (task.ppes?.isNotEmpty ?? false) ||
                        (task.machines?.isNotEmpty ?? false)) ...[
                      _buildInitialConditionSection(task, theme),
                      const SizedBox(height: AppSpacing.md),
                    ],

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

                    // Show "before" photo if exists
                    if (task.photos.any((p) => p.type == 'before')) ...[
                      _buildPhotoPreviewSection(
                        label: 'Foto Sebelum',
                        photos: task.photos.where((p) => p.type == 'before').toList(),
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Show tools/chemicals/ppes/machines used during start
                    if ((task.tools?.isNotEmpty ?? false) ||
                        (task.chemicals?.isNotEmpty ?? false) ||
                        (task.ppes?.isNotEmpty ?? false) ||
                        (task.machines?.isNotEmpty ?? false)) ...[
                      _buildUsedItemsPreview(task, theme),
                      const SizedBox(height: AppSpacing.md),

                      // Final condition selection
                      _buildFinalConditionSection(task, theme),
                      const SizedBox(height: AppSpacing.md),
                    ],

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
                        AppTextField(
                          controller: _notesController,
                          hint: 'Tambahkan catatan...',
                          maxLines: 3,
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
          // Status badge
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
          const SizedBox(height: AppSpacing.sm),

          // Assigned info - lebih rapat
          if (task.assignedBy != null && task.assignedBy!.isNotEmpty) ...[
            Row(
              children: [
                Icon(IconMap.person, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  task.assignedBy!,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
          if (task.assignedDate != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(IconMap.calendarToday, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  _formatDate(task.assignedDate!),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),

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
            const SizedBox(height: AppSpacing.sm),
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
          if (task.notes != null && task.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(IconMap.editNote, size: 14, color: theme.colors.mutedForeground),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
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

  /// Build photo preview section for network photos (in progress view)
  Widget _buildPhotoPreviewSection({
    required String label,
    required List<DailyTaskPhoto> photos,
    required FThemeData theme,
  }) {
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
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (ctx, i) {
              final photo = photos[i];
              return GestureDetector(
                onTap: () => _showFullScreenPhoto(photo.url, photo.type),
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right: i < photos.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.radiusSm,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photo.url,
                          fit: BoxFit.cover,
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
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build assigned items info (tools, chemicals, ppes) for "assigned" status view
  /// Read-only display of items set by TL during assignment - separated by category
  Widget _buildAssignedItemsInfo(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(13),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.flaskConical, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Alat & Bahan dari TL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tools section
          if (task.tools?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.build, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Alat:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.tools!.map((t) => _buildAssignedItemChip(t.name, theme)).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Chemicals section
          if (task.chemicals?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.flaskConical, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Chemical:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.chemicals!.map((c) => _buildAssignedItemChip(c.name, theme)).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // PPEs section
          if (task.ppes?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.shieldCheck, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Alat Pelindung Diri:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.ppes!.map((p) => _buildAssignedItemChip(p.name, theme)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedItemChip(String name, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Build initial condition selection section (shown when starting task)
  Widget _buildInitialConditionSection(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.primary.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.checklist, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Kondisi Awal Alat & Bahan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pilih kondisi alat, APD, mesin, dan chemical sebelum mulai bekerja',
            style: TextStyle(
              fontSize: 12,
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tools condition
          if (task.tools?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Alat', IconMap.build, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.tools!.map((t) => _buildToolConditionSelector(
              itemId: t.id,
              itemName: t.name,
              selectedCondition: _initialToolConditions[t.id],
              onChanged: (condition) {
                setState(() {
                  _initialToolConditions[t.id] = condition;
                });
              },
              theme: theme,
              currentCondition: t.currentConditionLabel,
              currentStock: t.currentStock,
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // PPEs condition
          if (task.ppes?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Alat Pelindung Diri (APD)', IconMap.shieldCheck, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.ppes!.map((p) => _buildToolConditionSelector(
              itemId: p.id,
              itemName: p.name,
              selectedCondition: _initialPpeConditions[p.id],
              onChanged: (condition) {
                setState(() {
                  _initialPpeConditions[p.id] = condition;
                });
              },
              theme: theme,
              currentCondition: p.currentConditionLabel,
              currentStock: p.currentStock,
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Machines condition
          if (task.machines?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Mesin', IconMap.build, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.machines!.map((m) => _buildToolConditionSelector(
              itemId: m.id,
              itemName: m.name,
              selectedCondition: _initialMachineConditions[m.id],
              onChanged: (condition) {
                setState(() {
                  _initialMachineConditions[m.id] = condition;
                });
              },
              theme: theme,
              currentCondition: m.currentConditionLabel,
              currentStock: m.currentStock,
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Chemicals condition
          if (task.chemicals?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Chemical', IconMap.flaskConical, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.chemicals!.map((c) => _buildChemicalConditionSelector(
              chemical: c,
              selectedCondition: _initialChemicalConditions[c.id],
              onChanged: (condition) {
                setState(() {
                  _initialChemicalConditions[c.id] = condition;
                });
              },
              theme: theme,
              currentCondition: c.currentConditionLabel,
              currentStock: c.currentStock,
            )),
          ],
        ],
      ),
    );
  }

  /// Build final condition selection section (shown when finishing task)
  Widget _buildFinalConditionSection(DailyTask task, FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.warning.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.checklist, size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Kondisi Akhir Alat & Bahan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pilih kondisi alat, APD, mesin, dan chemical setelah selesai bekerja',
            style: TextStyle(
              fontSize: 12,
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tools condition
          if (task.tools?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Alat', IconMap.build, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.tools!.map((t) => _buildToolConditionSelector(
              itemId: t.id,
              itemName: t.name,
              selectedCondition: _finalToolConditions[t.id],
              onChanged: (condition) {
                setState(() {
                  _finalToolConditions[t.id] = condition;
                });
              },
              theme: theme,
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // PPEs condition
          if (task.ppes?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Alat Pelindung Diri (APD)', IconMap.shieldCheck, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.ppes!.map((p) => _buildToolConditionSelector(
              itemId: p.id,
              itemName: p.name,
              selectedCondition: _finalPpeConditions[p.id],
              onChanged: (condition) {
                setState(() {
                  _finalPpeConditions[p.id] = condition;
                });
              },
              theme: theme,
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Machines condition
          if (task.machines?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Mesin', IconMap.build, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.machines!.map((m) => _buildToolConditionSelector(
              itemId: m.id,
              itemName: m.name,
              selectedCondition: _finalMachineConditions[m.id],
              onChanged: (condition) {
                setState(() {
                  _finalMachineConditions[m.id] = condition;
                });
              },
              theme: theme,
            )),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Chemicals condition
          if (task.chemicals?.isNotEmpty ?? false) ...[
            _buildConditionSectionHeader('Chemical', IconMap.flaskConical, theme),
            const SizedBox(height: AppSpacing.xs),
            ...task.chemicals!.map((c) => _buildChemicalConditionSelector(
              chemical: c,
              selectedCondition: _finalChemicalConditions[c.id],
              onChanged: (condition) {
                setState(() {
                  _finalChemicalConditions[c.id] = condition;
                });
              },
              theme: theme,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionSectionHeader(String title, IconData icon, FThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colors.mutedForeground),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }

  /// Build condition selector for tools/APD
  /// Shows current condition from ProductArea
  Widget _buildToolConditionSelector({
    required int itemId,
    required String itemName,
    required String? selectedCondition,
    required void Function(String) onChanged,
    required FThemeData theme,
    String? currentCondition,
    double? currentStock,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              if (currentCondition != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Saat ini: $currentCondition${currentStock != null ? ' ($currentStock)' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _buildConditionChip(
                label: 'SB (≥85%)',
                value: 'excellent',
                isSelected: selectedCondition == 'excellent',
                onTap: () => onChanged('excellent'),
                theme: theme,
              ),
              _buildConditionChip(
                label: 'B (≥65%)',
                value: 'good',
                isSelected: selectedCondition == 'good',
                onTap: () => onChanged('good'),
                theme: theme,
              ),
              _buildConditionChip(
                label: 'CB (≥45%)',
                value: 'fair',
                isSelected: selectedCondition == 'fair',
                onTap: () => onChanged('fair'),
                theme: theme,
              ),
              _buildConditionChip(
                label: 'KB (≥25%)',
                value: 'poor',
                isSelected: selectedCondition == 'poor',
                onTap: () => onChanged('poor'),
                theme: theme,
              ),
              _buildConditionChip(
                label: 'Ganti (<25%)',
                value: 'replace',
                isSelected: selectedCondition == 'replace',
                onTap: () => onChanged('replace'),
                theme: theme,
                isWarning: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build condition selector for chemicals
  /// Shows current condition from ProductArea
  Widget _buildChemicalConditionSelector({
    required DailyTaskChemical chemical,
    required String? selectedCondition,
    required void Function(String) onChanged,
    required FThemeData theme,
    String? currentCondition,
    double? currentStock,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chemical.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              if (currentCondition != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Saat ini: $currentCondition${currentStock != null ? ' ($currentStock)' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _buildConditionChip(
                label: 'Full (≥75%)',
                value: 'full',
                isSelected: selectedCondition == 'full',
                onTap: () => onChanged('full'),
                theme: theme,
              ),
              _buildConditionChip(
                label: 'Setengah (≥50%)',
                value: 'half',
                isSelected: selectedCondition == 'half',
                onTap: () => onChanged('half'),
                theme: theme,
              ),
              _buildConditionChip(
                label: '1/4 (<50%)',
                value: 'low',
                isSelected: selectedCondition == 'low',
                onTap: () => onChanged('low'),
                theme: theme,
                isWarning: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required FThemeData theme,
    bool isWarning = false,
  }) {
    final bgColor = isSelected
        ? (isWarning ? AppColors.warning : AppColors.primary).withAlpha(51)
        : theme.colors.muted;
    final borderColor = isSelected
        ? (isWarning ? AppColors.warning : AppColors.primary)
        : theme.colors.border;
    final textColor = isSelected
        ? (isWarning ? AppColors.warning : AppColors.primary)
        : theme.colors.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// Build used items preview (tools, chemicals, ppes) for in progress view - separated by category
  Widget _buildUsedItemsPreview(DailyTask task, FThemeData theme) {
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
            'ALAT YANG DIGUNAKAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colors.mutedForeground,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tools section
          if (task.tools?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.build, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Alat:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.tools!.map((t) => _buildUsedItemChip(t.name, theme)).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Chemicals section
          if (task.chemicals?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.flaskConical, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Chemical:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.chemicals!.map((c) => _buildUsedItemChip(c.name, theme)).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // PPEs section
          if (task.ppes?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.shieldCheck, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Alat Pelindung Diri:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.ppes!.map((p) => _buildUsedItemChip(p.name, theme)).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Machines section
          if (task.machines?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(IconMap.build, size: 14, color: theme.colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'Mesin:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: task.machines!.map((m) => _buildUsedItemChip(m.name, theme)).toList(),
            ),
          ],

          // Show message if no items
          if ((task.tools?.isEmpty ?? true) &&
              (task.chemicals?.isEmpty ?? true) &&
              (task.ppes?.isEmpty ?? true)) ...[
            Text(
              'Tidak ada alat yang digunakan',
              style: TextStyle(
                fontSize: 13,
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsedItemChip(String name, FThemeData theme) {
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
        _buildUsedItemsList('Mesin', task.machines, theme),

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
                        : item is DailyTaskMachine
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
