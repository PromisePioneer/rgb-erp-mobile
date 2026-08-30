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

  ReviewData? _getReviewData() {
    final reviewJson = widget.taskData['review'];
    if (reviewJson == null) return null;
    return ReviewData.fromJson(reviewJson as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final taskName = widget.taskData['item_name'] ?? widget.taskData['employee_name'] ?? 'Tugas';
    final employeeName = widget.taskData['employee_name'];
    final status = widget.taskData['status'] as String? ?? 'completed';
    final isReviewed = status == 'reviewed';
    final reviewData = _getReviewData();

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
              padding: const EdgeInsets.all(AppSpacing.md),
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
                      if (employeeName != null) ...[
                        Row(
                          children: [
                            Icon(IconMap.person, size: 18, color: theme.colors.primary),
                            const SizedBox(width: 8),
                            Text(
                              employeeName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colors.foreground,
                              ),
                            ),
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
                const SizedBox(height: AppSpacing.xxl),
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
              return Container(
                width: 120,
                margin: EdgeInsets.only(
                  right: i < photos.length - 1 ? AppSpacing.sm : 0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.radiusSm,
                        child: Image.network(
                          photo['url'] ?? '',
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (photo['type'] ?? 'photo').toString().toUpperCase(),
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
      ],
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
            label: 'ALAT DIGUNAKAN',
            items: tools,
            theme: theme,
            icon: IconMap.build,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (chemicals.isNotEmpty) ...[
          _buildUsedItemsCard(
            label: 'CHEMICAL DIGUNAKAN',
            items: chemicals,
            theme: theme,
            icon: IconMap.flaskConical,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (ppes.isNotEmpty) ...[
          _buildUsedItemsCard(
            label: 'ALAT PELINDUNG DIRI',
            items: ppes,
            theme: theme,
            icon: IconMap.shieldCheck,
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
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: items.map((item) {
              final name = item['name']?.toString() ?? 'Unknown';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  border: Border.all(color: AppColors.primary.withAlpha(51)),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
