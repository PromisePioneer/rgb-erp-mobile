import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../providers/daily_task_provider.dart';

/// Review criteria model
class ReviewCriteria {
  final int id;
  final String name;
  final String? description;

  ReviewCriteria({
    required this.id,
    required this.name,
    this.description,
  });

  factory ReviewCriteria.fromJson(Map<String, dynamic> json) {
    return ReviewCriteria(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

/// Review data model
class ReviewData {
  final String? reviewerName;
  final String? reviewedAt;
  final String? notes;
  final List<ReviewScore> scores;

  ReviewData({
    this.reviewerName,
    this.reviewedAt,
    this.notes,
    required this.scores,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      reviewerName: json['reviewer_name'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      notes: json['notes'] as String?,
      scores: (json['scores'] as List<dynamic>?)
              ?.map((s) => ReviewScore.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.score).reduce((a, b) => a + b) / scores.length;
  }
}

class ReviewScore {
  final int criteriaId;
  final String? criteriaName;
  final int score;

  ReviewScore({
    required this.criteriaId,
    this.criteriaName,
    required this.score,
  });

  factory ReviewScore.fromJson(Map<String, dynamic> json) {
    return ReviewScore(
      criteriaId: json['criteria_id'] as int,
      criteriaName: json['criteria_name'] as String?,
      score: json['score'] as int,
    );
  }
}

/// Task review screen for Team Leader
class TaskReviewScreen extends StatefulWidget {
  final int taskId;
  final Map<String, dynamic> taskData;

  const TaskReviewScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  List<ReviewCriteria> _criteria = [];
  Map<int, int> _scores = {}; // criteriaId -> score (1-5)
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCriteria();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCriteria() async {
    try {
      final notifier = context.read<DailyTaskNotifier>();
      final criteriaData = await notifier.getReviewCriteria();
      setState(() {
        _criteria = criteriaData.map((c) => ReviewCriteria.fromJson(c)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat kriteria review: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    // Validate all criteria have scores
    for (final criteria in _criteria) {
      if (!_scores.containsKey(criteria.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silakan berikan rating untuk "${criteria.name}"'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    final scores = _scores.entries
        .map((e) => {
              'criteria_id': e.key,
              'score': e.value,
            })
        .toList();

    setState(() => _isSubmitting = true);

    try {
      final notifier = context.read<DailyTaskNotifier>();
      final success = await notifier.submitReview(
        taskId: widget.taskId,
        scores: scores,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review berhasil disimpan!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notifier.error ?? 'Gagal menyimpan review'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Extract employee names from various API response formats
  List<String> _extractEmployeeNames() {
    final taskData = widget.taskData;

    // Format 1: employees array with id, name, code
    if (taskData.containsKey('employees') && taskData['employees'] != null) {
      final employees = taskData['employees'];
      if (employees is List) {
        return employees
            .map((e) {
              if (e is String) return e;
              if (e is Map) {
                return e['name'] as String? ?? e['employee_name'] as String? ?? '';
              }
              return '';
            })
            .where((name) => name.isNotEmpty)
            .toList();
      }
    }

    // Format 2: employee_names array
    if (taskData.containsKey('employee_names') && taskData['employee_names'] != null) {
      final names = taskData['employee_names'];
      if (names is List) {
        return names.whereType<String>().toList();
      }
    }

    // Format 3: Single employee_name field
    if (taskData.containsKey('employee_name') && taskData['employee_name'] != null) {
      final name = taskData['employee_name'];
      if (name is String) {
        return [name];
      }
    }

    return [];
  }

  /// Get employee count from task data
  int _getEmployeeCount() {
    final taskData = widget.taskData;

    // Use employee_count if available
    if (taskData.containsKey('employee_count') && taskData['employee_count'] != null) {
      return taskData['employee_count'] as int;
    }

    // Count from employees array
    if (taskData.containsKey('employees') && taskData['employees'] != null) {
      final employees = taskData['employees'];
      if (employees is List) {
        return employees.length;
      }
    }

    // Count from employee_names array
    if (taskData.containsKey('employee_names') && taskData['employee_names'] != null) {
      final names = taskData['employee_names'];
      if (names is List) {
        return names.length;
      }
    }

    // Single employee
    if (taskData.containsKey('employee_name') && taskData['employee_name'] != null) {
      return 1;
    }

    return 1;
  }

  ReviewData? _getReviewData() {
    final reviewJson = widget.taskData['review'];
    if (reviewJson == null) return null;
    return ReviewData.fromJson(reviewJson as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final taskName = widget.taskData['item_name'] ?? widget.taskData['employee_name'] ?? 'Tugas';
    final status = widget.taskData['status'] as String? ?? 'completed';
    final isReviewed = status == 'reviewed';
    final reviewData = _getReviewData();

    // Extract all employee names
    final employeeNames = _extractEmployeeNames();
    final employeeCount = _getEmployeeCount();
    final displayNames = employeeCount > 2
        ? '${employeeNames.take(2).join(", ")} +${employeeCount - 2}'
        : employeeNames.join(", ");

    return Scaffold(
      backgroundColor: theme.colors.muted,
      appBar: AppBar(
        title: const Text('Review Tugas'),
        backgroundColor: theme.colors.card,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + 56 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                // Task info card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colors.card,
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (employeeNames.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(employeeCount > 1 ? IconMap.users : IconMap.person, size: 18, color: theme.colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayNames,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colors.foreground,
                                ),
                              ),
                            ),
                            if (employeeCount > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$employeeCount orang',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        taskName,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isReviewed ? AppColors.primary.withAlpha(26) : AppColors.success.withAlpha(26),
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Text(
                          isReviewed ? 'Sudah Direview' : 'Menunggu Review',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isReviewed ? AppColors.primary : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Photos section
                _buildPhotosSection(theme),
                const SizedBox(height: AppSpacing.md),

                // Tools, Chemicals, PPE used section
                _buildUsedItemsSection(theme),

                // If already reviewed, show review data
                if (isReviewed && reviewData != null) ...[
                  _buildReviewResultSection(reviewData, theme),
                ] else ...[
                  // Rating section
                  _buildRatingForm(theme),
                  const SizedBox(height: AppSpacing.md),

                  // Notes section
                  _buildNotesForm(theme),
                  const SizedBox(height: AppSpacing.xl),

                  PrimaryButton(
                    label: 'Simpan Review',
                    icon: IconMap.checkCircle,
                    isLoading: _isSubmitting,
                    onPressed: _submitReview,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildReviewResultSection(ReviewData reviewData, FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Review result header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.primary.withAlpha(51)),
          ),
          child: Column(
            children: [
              Icon(
                IconMap.checkCircle,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tugas Sudah Direview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (reviewData.reviewerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'oleh ${reviewData.reviewerName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
              if (reviewData.reviewedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDate(reviewData.reviewedAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              // Average score
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reviewData.averageScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          final avg = reviewData.averageScore;
                          if (i < avg.floor()) {
                            return Icon(IconMap.star, size: 20, color: AppColors.warning);
                          } else if (i < avg) {
                            return Icon(IconMap.star, size: 20, color: AppColors.warning.withAlpha(128));
                          } else {
                            return Icon(IconMap.star, size: 20, color: theme.colors.mutedForeground);
                          }
                        }),
                      ),
                      Text(
                        'dari 5',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Individual scores
        Text(
          'DETAIL RATING',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: AppRadius.radiusMd,
          ),
          child: Column(
            children: reviewData.scores.map((score) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        score.criteriaName ?? 'Kriteria #${score.criteriaId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          IconMap.star,
                          size: 18,
                          color: i < score.score ? AppColors.warning : theme.colors.mutedForeground,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${score.score}/5',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Notes
        if (reviewData.notes != null && reviewData.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'CATATAN REVIEWER',
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
              reviewData.notes!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.foreground,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingForm(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATING',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: AppRadius.radiusMd,
          ),
          child: Column(
            children: _criteria.map((c) => _buildCriteriaRating(c, theme)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesForm(FThemeData theme) {
    return Column(
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
        Container(
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: AppRadius.radiusMd,
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan review...',
              hintStyle: TextStyle(color: theme.colors.mutedForeground),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(FThemeData theme) {
    final photos = widget.taskData['photos'] as List<dynamic>? ?? [];
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            itemCount: photos.length,
            itemBuilder: (ctx, i) {
              final photo = photos[i];
              final photoUrl = photo['url']?.toString() ?? '';
              final photoType = photo['type']?.toString() ?? 'photo';
              return GestureDetector(
                onTap: () => _showFullScreenPhoto(photoUrl, photoType),
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: i < photos.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.radiusSm,
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: theme.colors.muted,
                                  child: Icon(
                                    IconMap.brokenImage,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
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
                      const SizedBox(height: 4),
                      Text(
                        photoType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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

  Widget _buildUsedItemsSection(FThemeData theme) {
    final tools = widget.taskData['tools'] as List<dynamic>? ?? [];
    final chemicals = widget.taskData['chemicals'] as List<dynamic>? ?? [];
    final ppes = widget.taskData['ppes'] as List<dynamic>? ?? [];

    // Only show if at least one has items
    if (tools.isEmpty && chemicals.isEmpty && ppes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tools.isNotEmpty) ...[
          _buildUsedItemsCard(
            label: 'ALAT & APD',
            items: tools,
            theme: theme,
            icon: IconMap.build,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (chemicals.isNotEmpty) ...[
          _buildUsedItemsCard(
            label: 'CHEMICAL',
            items: chemicals,
            theme: theme,
            icon: IconMap.flaskConical,
            isChemical: true,
          ),
        ],
      ],
    );
  }

  Widget _buildUsedItemsCard({
    required String label,
    required List<dynamic> items,
    required FThemeData theme,
    required IconData icon,
    bool isChemical = false,
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
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colors.mutedForeground,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((item) {
            final name = item['name']?.toString() ?? 'Unknown';
            final initialCondition = item['initial_condition'] as String?;
            final finalCondition = item['final_condition'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Show conditions
                  Row(
                    children: [
                      // Initial condition
                      if (initialCondition != null) ...[
                        _buildConditionBadge(
                          label: 'Awal: ${_formatCondition(initialCondition)}',
                          color: AppColors.warning,
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Final condition
                      if (finalCondition != null) ...[
                        _buildConditionBadge(
                          label: 'Akhir: ${_formatCondition(finalCondition)}',
                          color: AppColors.success,
                          theme: theme,
                        ),
                      ],
                      // Show "Belum diinput" if no conditions
                      if (initialCondition == null && finalCondition == null)
                        Text(
                          'Belum ada kondisi tercatat',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colors.mutedForeground,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConditionBadge({
    required String label,
    required Color color,
    required FThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatCondition(String condition) {
    switch (condition) {
      case 'excellent':
        return 'SB (100-85%)';
      case 'good':
        return 'B (85-65%)';
      case 'fair':
        return 'CB (65-45%)';
      case 'poor':
        return 'KB (45-25%)';
      case 'replace':
        return 'Ganti (<25%)';
      case 'full':
        return 'Full (100%)';
      case 'half':
        return 'Setengah (50%)';
      case 'low':
        return 'Sedikit (30%)';
      default:
        return condition;
    }
  }

  Widget _buildCriteriaRating(ReviewCriteria criteria, FThemeData theme) {
    final selectedScore = _scores[criteria.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criteria.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colors.foreground,
                      ),
                    ),
                    if (criteria.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        criteria.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = selectedScore != null && starIndex <= selectedScore;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _scores[criteria.id] = starIndex;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    IconMap.star,
                    size: 32,
                    color: isSelected ? AppColors.warning : theme.colors.mutedForeground,
                  ),
                ),
              );
            }),
          ),
          if (selectedScore != null) ...[
            const SizedBox(height: 4),
            Text(
              '$selectedScore / 5',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}
