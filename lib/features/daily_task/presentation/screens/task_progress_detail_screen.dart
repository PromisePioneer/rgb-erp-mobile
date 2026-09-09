import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/toast/app_toast.dart';
import '../../../../shared/utils/watermark_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/daily_task_provider.dart';

/// Task Progress Detail Screen - Submit progress check for a task
class TaskProgressDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskProgressDetailScreen({super.key, required this.taskId});

  @override
  State<TaskProgressDetailScreen> createState() => _TaskProgressDetailScreenState();
}

class _TaskProgressDetailScreenState extends State<TaskProgressDetailScreen> {
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();
  final WatermarkService _watermarkService = WatermarkService();

  int? _selectedEmployeeId;
  String? _photoPath;
  String? _videoPath;

  // Loading states
  bool _isSubmitting = false;
  bool _isProcessingWatermark = false;
  double _videoWatermarkProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<DailyTaskNotifier>();
      notifier.loadProgressChecks(widget.taskId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image != null) {
        // Show loading indicator
        setState(() {
          _isProcessingWatermark = true;
        });

        try {
          // Get user info from AuthNotifier
          final authNotifier = context.read<AuthNotifier>();
          final userName = authNotifier.state.user?.name ?? 'Unknown';

          // Get area name - try multiple sources
          String areaName = 'Unknown Area';
          String? itemName = null;

          final notifier = context.read<DailyTaskNotifier>();

          // 1. Try from progressTasks first
          if (notifier.progressTasks.isNotEmpty) {
            final progressTask = notifier.progressTasks.firstWhere(
              (t) => t['id'] == widget.taskId,
              orElse: () => <String, dynamic>{},
            );
            if (progressTask.isNotEmpty) {
              final progressAreaName = progressTask['area_name'] as String?;
              if (progressAreaName != null && progressAreaName.isNotEmpty) {
                areaName = progressAreaName;
                debugPrint('WatermarkService: Using areaName from progressTasks: $areaName');
              }
              itemName = progressTask['item_name'] as String?;
            }
          }
          // 2. Try from selectedTask (if user is also an employee)
          else {
            final task = notifier.selectedTask;
            if (task != null) {
              if (task.areaName != null && task.areaName!.isNotEmpty) {
                areaName = task.areaName!;
                debugPrint('WatermarkService: Using areaName from selectedTask: $areaName');
              }
              itemName = task.itemName;
            }
          }

          // 3. Fallback to item name if areaName is still Unknown
          if (areaName == 'Unknown Area' && itemName != null && itemName.isNotEmpty) {
            areaName = itemName;
            debugPrint('WatermarkService: Using itemName as fallback: $areaName');
          }

          debugPrint('WatermarkService: Final areaName for watermark: $areaName');

          // Add watermark to the image
          final watermarkedBytes = await _watermarkService.watermarkImage(
            image: image,
            areaName: areaName,
            userName: userName,
          );

          // Save watermarked image to temporary file
          final tempDir = await Directory.systemTemp.createTemp();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final watermarkedPath = '${tempDir.path}/watermarked_$timestamp.jpg';
          final watermarkedFile = File(watermarkedPath);
          await watermarkedFile.writeAsBytes(watermarkedBytes);

          setState(() {
            _photoPath = watermarkedPath;
            _videoPath = null; // Clear video if photo is selected
            _isProcessingWatermark = false;
          });

          debugPrint('WatermarkService: Photo watermarked and saved to $watermarkedPath');
        } catch (e) {
          debugPrint('WatermarkService: Failed to watermark image: $e');
          // Fallback: save original image without watermark
          setState(() {
            _photoPath = image.path;
            _videoPath = null;
            _isProcessingWatermark = false;
          });

          if (mounted) {
            AppToast.of(context).show(
              message: 'Foto disimpan tanpa watermark: $e',
              style: AppToastStyle.warning,
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isProcessingWatermark = false;
      });
      if (mounted) {
        AppToast.of(context).show(
          message: 'Gagal mengambil foto: $e',
          style: AppToastStyle.error,
        );
      }
    }
  }

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (video != null) {
        // Show loading indicator
        setState(() {
          _isProcessingWatermark = true;
          _videoWatermarkProgress = 0.0;
        });

        try {
          // Log video info
          final videoFile = File(video.path);
          final videoSize = await videoFile.length();
          debugPrint('WatermarkService: Video captured, size: ${videoSize / 1024 / 1024} MB');
          debugPrint('WatermarkService: Video will be compressed on server via Redis queue');

          // Save video directly - backend will handle compression
          // No local processing needed

          setState(() {
            _videoPath = video.path;
            _photoPath = null; // Clear photo if video is selected
            _isProcessingWatermark = false;
            _videoWatermarkProgress = 1.0;
          });

          debugPrint('WatermarkService: Video ready for upload');
        } catch (e) {
          debugPrint('WatermarkService: Failed to process video: $e');
          setState(() {
            _videoPath = video.path;
            _photoPath = null;
            _isProcessingWatermark = false;
          });

          if (mounted) {
            AppToast.of(context).show(
              message: 'Video disimpan: $e',
              style: AppToastStyle.warning,
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isProcessingWatermark = false;
      });
      if (mounted) {
        AppToast.of(context).show(
          message: 'Gagal mengambil video: $e',
          style: AppToastStyle.error,
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedEmployeeId == null) {
      AppToast.of(context).show(
        message: 'Pilih karyawan yang akan dicek',
        style: AppToastStyle.error,
      );
      return;
    }

    if (_photoPath == null && _videoPath == null) {
      AppToast.of(context).show(
        message: 'Ambil foto atau video sebagai bukti observasi',
        style: AppToastStyle.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = context.read<DailyTaskNotifier>();
    bool success = false;

    // DEBUG: Log what we're sending
    debugPrint('=== SUBMIT PROGRESS CHECK ===');
    debugPrint('taskId: ${widget.taskId}');
    debugPrint('employeeId: $_selectedEmployeeId');
    debugPrint('photoPath: $_photoPath');
    debugPrint('videoPath: $_videoPath');
    debugPrint('notes: ${_notesController.text}');
    debugPrint('=============================');

    try {
      if (_photoPath != null) {
        // Convert photo to base64
        final file = File(_photoPath!);
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        debugPrint('Photo base64 length: ${base64.length}');

        success = await notifier.submitProgressCheckPhoto(
          taskId: widget.taskId,
          employeeId: _selectedEmployeeId!,
          photoBase64: base64,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else if (_videoPath != null) {
        // Debug: check file size
        final file = File(_videoPath!);
        final size = await file.length();
        debugPrint('Video file size: $size bytes (${size / 1024 / 1024} MB)');

        success = await notifier.submitProgressCheckVideo(
          taskId: widget.taskId,
          employeeId: _selectedEmployeeId!,
          videoPath: _videoPath!,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      debugPrint('Submit result: $success');
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      if (mounted) {
        AppToast.of(context).show(
          message: 'Gagal menyimpan progress check: $e',
          style: AppToastStyle.error,
        );
      }
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      AppToast.of(context).show(
        message: 'Progress check berhasil disimpan',
        style: AppToastStyle.success,
      );
      // Clear form
      setState(() {
        _photoPath = null;
        _videoPath = null;
        _notesController.clear();
      });
    } else if (mounted) {
      // Show error from provider
      final error = notifier.error ?? 'Terjadi kesalahan saat menyimpan';
      AppToast.of(context).show(
        message: error,
        style: AppToastStyle.error,
        duration: const Duration(seconds: 4),
      );
      notifier.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Progress Check'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconMap.chevronLeft),
          onPressed: () {
            context.read<DailyTaskNotifier>().clearProgressChecks();
            context.pop();
          },
        ),
      ),
      body: Consumer<DailyTaskNotifier>(
        builder: (context, notifier, _) {
          if (notifier.isLoading && notifier.progressChecks.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          final task = notifier.progressTasks.firstWhere(
            (t) => t['id'] == widget.taskId,
            orElse: () => <String, dynamic>{},
          );

          return RefreshIndicator(
            onRefresh: () => notifier.loadProgressChecks(widget.taskId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task info
                  _buildTaskInfo(task),
                  const SizedBox(height: 24),

                  // Employee selection
                  _buildEmployeeSelection(task, notifier),
                  const SizedBox(height: 24),

                  // Media capture
                  _buildMediaCapture(),
                  const SizedBox(height: 24),

                  // Notes
                  _buildNotesField(),
                  const SizedBox(height: 24),

                  // Submit button
                  _buildSubmitButton(),
                  const SizedBox(height: 32),

                  // History
                  _buildHistorySection(notifier),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskInfo(Map<String, dynamic> task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconMap.task, size: 16, color: AppColors.slate500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task['item_name'] as String? ?? 'Tugas',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.slate800,
                  ),
                ),
              ),
            ],
          ),
          if (task['area_name'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(IconMap.locationOn, size: 16, color: AppColors.slate500),
                const SizedBox(width: 8),
                Text(
                  task['area_name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeSelection(Map<String, dynamic> task, DailyTaskNotifier notifier) {
    final isCompleted = task['status'] == 'completed';

    // If task is completed, show message instead of selection
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(IconMap.checkCircle, color: AppColors.success),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tugas sudah selesai. Progress check tidak bisa ditambahkan.',
                style: TextStyle(
                  color: AppColors.slate600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final employees = task['employees'] as List<dynamic>? ?? [];
    final primaryEmployee = {
      'id': task['employee_id'],
      'name': task['employee_name'] ?? 'Karyawan',
      'code': task['employee_code'],
    };

    // Combine primary and assigned employees
    final allEmployees = <Map<String, dynamic>>[primaryEmployee];
    for (final emp in employees) {
      if (emp['id'] != primaryEmployee['id']) {
        allEmployees.add(emp as Map<String, dynamic>);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Karyawan yang Dicek',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allEmployees.map((emp) {
            final isSelected = _selectedEmployeeId == emp['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEmployeeId = emp['id'] as int;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.slate200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? IconMap.checkCircle : IconMap.person,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.slate500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      emp['name'] as String? ?? 'Unknown',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.slate700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaCapture() {
    // If task is completed, don't show media capture
    final task = context.read<DailyTaskNotifier>().progressTasks.firstWhere(
      (t) => t['id'] == widget.taskId,
      orElse: () => <String, dynamic>{},
    );
    if (task['status'] == 'completed') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambil Bukti Observasi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih foto atau video (hanya salah satu)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 12),

        // Loading indicator for watermark processing
        if (_isProcessingWatermark) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_videoPath == null && _photoPath == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text(
                    'Menambahkan watermark ke foto...',
                    style: TextStyle(color: AppColors.slate600),
                  ),
                ] else ...[
                  if (_videoWatermarkProgress > 0) ...[
                    LinearProgressIndicator(value: _videoWatermarkProgress),
                    const SizedBox(height: 12),
                    Text(
                      'Memproses video... ${(_videoWatermarkProgress * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.slate600),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text(
                      'Menambahkan watermark ke video...',
                      style: TextStyle(color: AppColors.slate600),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            // Photo button
            Expanded(
              child: GestureDetector(
                onTap: _isProcessingWatermark ? null : _takePhoto,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _photoPath != null ? AppColors.primary.withAlpha(25) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _photoPath != null ? AppColors.primary : AppColors.slate200,
                      width: _photoPath != null ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        IconMap.camera,
                        size: 32,
                        color: _isProcessingWatermark
                            ? AppColors.slate300
                            : (_photoPath != null ? AppColors.primary : AppColors.slate500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _photoPath != null ? 'Foto Dipilih' : 'Ambil Foto',
                        style: TextStyle(
                          color: _isProcessingWatermark
                              ? AppColors.slate300
                              : (_photoPath != null ? AppColors.primary : AppColors.slate600),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Video button
            Expanded(
              child: GestureDetector(
                onTap: _isProcessingWatermark ? null : _takeVideo,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _videoPath != null ? AppColors.info.withAlpha(25) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _videoPath != null ? AppColors.info : AppColors.slate200,
                      width: _videoPath != null ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        IconMap.videocam,
                        size: 32,
                        color: _isProcessingWatermark
                            ? AppColors.slate300
                            : (_videoPath != null ? AppColors.info : AppColors.slate500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _videoPath != null ? 'Video Dipilih' : 'Ambil Video',
                        style: TextStyle(
                          color: _isProcessingWatermark
                              ? AppColors.slate300
                              : (_videoPath != null ? AppColors.info : AppColors.slate600),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Show preview if media selected
        if (_photoPath != null && !_isProcessingWatermark) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_photoPath!),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        if (_videoPath != null && !_isProcessingWatermark) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(IconMap.videocam, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Video: ${_videoPath!.split('/').last}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesField() {
    // If task is completed, don't show notes field
    final task = context.read<DailyTaskNotifier>().progressTasks.firstWhere(
      (t) => t['id'] == widget.taskId,
      orElse: () => <String, dynamic>{},
    );
    if (task['status'] == 'completed') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan (Opsional)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Contoh: Karyawan sedang menyapu lantai dengan benar...',
            hintStyle: const TextStyle(color: AppColors.slate500),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    // If task is completed, don't show submit button
    final task = context.read<DailyTaskNotifier>().progressTasks.firstWhere(
      (t) => t['id'] == widget.taskId,
      orElse: () => <String, dynamic>{},
    );
    if (task['status'] == 'completed') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FButton(
        onPress: _isSubmitting ? null : _submit,
        variant: FButtonVariant.primary,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Simpan Progress Check'),
      ),
    );
  }

  Widget _buildHistorySection(DailyTaskNotifier notifier) {
    final checks = notifier.progressChecks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Progress Check',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 12),
        if (checks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Belum ada progress check',
                style: TextStyle(color: AppColors.slate500),
              ),
            ),
          )
        else
          ...checks.map((check) => _ProgressCheckCard(check: check)),
      ],
    );
  }
}

class _ProgressCheckCard extends StatelessWidget {
  final Map<String, dynamic> check;

  const _ProgressCheckCard({required this.check});

  @override
  Widget build(BuildContext context) {
    final mediaType = check['media_type'] as String? ?? 'photo';
    final mediaUrl = check['media_url'] as String? ?? '';
    final isPhoto = mediaType == 'photo';
    final checkedAt = check['checked_at'] != null
        ? _formatDateTime(check['checked_at'] as String)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media thumbnail/icon
          GestureDetector(
            onTap: () => _openMedia(context, mediaUrl, isPhoto),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          IconMap.brokenImage,
                          color: AppColors.slate500,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        IconMap.playCircle,
                        size: 32,
                        color: AppColors.info,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(IconMap.person, size: 14, color: AppColors.slate500),
                    const SizedBox(width: 4),
                    Text(
                      check['employee_name'] as String? ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  checkedAt,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                ),
                if (check['notes'] != null && (check['notes'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    check['notes'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Media type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPhoto ? AppColors.primary.withAlpha(25) : AppColors.info.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPhoto ? 'Foto' : 'Video',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isPhoto ? AppColors.primary : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMedia(BuildContext context, String url, bool isPhoto) async {
    if (isPhoto) {
      // Open image in full screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            extendBodyBehindAppBar: true,
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Open video URL - try multiple methods
      debugPrint('Opening video URL: $url');

      try {
        // Method 1: Try with in-app browser first
        final launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(
            headers: {'Accept': 'video/*'},
          ),
        );

        if (!launched) {
          // Method 2: Try external browser
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('Launch error: $e');
        if (context.mounted) {
          AppToast.of(context).show(
            message: 'Error: $e',
            style: AppToastStyle.error,
          );
        }
      }
    }
  }

  String _formatDateTime(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return isoDate;
    }
  }
}
