import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/domain.dart';
import '../providers/violation_report_provider.dart';

/// Violation report detail screen
class ViolationReportDetailScreen extends StatelessWidget {
  final int violationId;

  const ViolationReportDetailScreen({
    super.key,
    required this.violationId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return TopGradientBackground(
      gradientHeight: 120,
      child: Scaffold(
        backgroundColor: theme.colors.muted,
        appBar: AppBar(
          title: const Text('Detail Laporan Patroli'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(IconMap.arrowBack, color: theme.colors.foreground),
            onPressed: () => context.pop(),
          ),
        ),
        body: Consumer<ViolationReportNotifier>(
          builder: (context, notifier, child) {
            final violation = notifier.state.violations
                .where((v) => v.id == violationId)
                .firstOrNull;

            if (violation == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconMap.errorOutline, size: 64, color: theme.colors.destructive),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Laporan tidak ditemukan',
                      style: TextStyle(color: theme.colors.mutedForeground),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(violation, context),
                  SizedBox(height: AppSpacing.md),

                  // Info Section
                  _buildSectionTitle('Informasi Pelanggaran', context),
                  SizedBox(height: AppSpacing.sm),
                  _buildInfoCard([
                    _InfoItem(
                      icon: IconMap.business,
                      label: 'Project/Site',
                      value: violation.areaName ?? '-',
                    ),
                    _InfoItem(
                      icon: IconMap.person,
                      label: 'Karyawan Pelanggar',
                      value: violation.employeeName ?? '-',
                    ),
                    _InfoItem(
                      icon: IconMap.warning,
                      label: 'Jenis Pelanggaran',
                      value: violation.violationTypeName ?? '-',
                    ),
                  ], context),
                  SizedBox(height: AppSpacing.md),

                  // Waktu Section
                  _buildSectionTitle('Waktu & Lokasi', context),
                  SizedBox(height: AppSpacing.sm),
                  _buildInfoCard([
                    _InfoItem(
                      icon: IconMap.calendarToday,
                      label: 'Tanggal & Waktu',
                      value: _formatDateTime(violation.capturedAt),
                    ),
                  ], context),
                  SizedBox(height: AppSpacing.md),

                  // Catatan Section
                  if (violation.notes != null && violation.notes!.isNotEmpty) ...[
                    _buildSectionTitle('Catatan', context),
                    SizedBox(height: AppSpacing.sm),
                    _buildTextCard(violation.notes!, context),
                    SizedBox(height: AppSpacing.md),
                  ],

                  // Tindakan Section
                  if (violation.action != null && violation.action!.isNotEmpty) ...[
                    _buildSectionTitle('Tindakan yang Dilakukan', context),
                    SizedBox(height: AppSpacing.sm),
                    _buildTextCard(violation.action!, context),
                    SizedBox(height: AppSpacing.md),
                  ],

                  // Photos Section
                  if (violation.photos.isNotEmpty) ...[
                    _buildSectionTitle('Foto Bukti (${violation.photoCount})', context),
                    SizedBox(height: AppSpacing.sm),
                    _buildPhotoGallery(violation.photos, context),
                    SizedBox(height: AppSpacing.md),
                  ],

                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final theme = FTheme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colors.foreground,
      ),
    );
  }

  Widget _buildHeaderCard(ViolationReportResult violation, BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colors.destructive, theme.colors.destructive.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colors.destructive.withAlpha(128),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colors.destructiveForeground.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID #${violation.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.destructiveForeground,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(IconMap.warning, color: theme.colors.destructiveForeground, size: 28),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  violation.violationTypeName ?? 'Pelanggaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colors.destructiveForeground,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(IconMap.business, color: theme.colors.destructiveForeground.withAlpha(179), size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                violation.areaName ?? '-',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colors.destructiveForeground.withAlpha(179),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(IconMap.person, color: theme.colors.destructiveForeground.withAlpha(179), size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Pelanggar: ${violation.employeeName ?? '-'}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colors.destructiveForeground.withAlpha(179),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colors.destructiveForeground.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(IconMap.accessTime, color: theme.colors.destructiveForeground, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text(
                  _formatDateTime(violation.capturedAt),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.destructiveForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items, BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (index > 0) Divider(height: AppSpacing.md, color: theme.colors.muted),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: theme.colors.mutedForeground, size: 20),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextCard(String text, BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: theme.colors.foreground,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<ViolationPhoto> photos, BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: photos.length == 1 ? 1 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: photos.length == 1 ? 16 / 9 : 1,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () {
                  if (photo.url != null) {
                    _showPhotoDialog(context, photo.url!);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photo.url != null
                        ? Image.network(
                            photo.url!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (ctx, error, stack) => _buildPhotoError(context),
                            loadingBuilder: (ctx, child, loading) {
                              if (loading == null) return child;
                              return Center(
                                child: LoadingIndicator(size: 24),
                              );
                            },
                          )
                        : _buildPhotoError(context),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Tap foto untuk memperbesar',
            style: TextStyle(
              fontSize: 12,
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoError(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      color: theme.colors.muted,
      child: Center(
        child: Icon(
          IconMap.brokenImage,
          color: theme.colors.mutedForeground,
          size: 40,
        ),
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String url) {
    final theme = FTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(AppSpacing.md),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, error, stack) => Container(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      color: theme.colors.card,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(IconMap.brokenImage, size: 64, color: theme.colors.destructive),
                          SizedBox(height: AppSpacing.md),
                          Text('Gagal memuat foto', style: TextStyle(color: theme.colors.foreground)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colors.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(IconMap.close, color: theme.colors.foreground, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (e) {
      return isoDate;
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
