import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../domain/entities/korwil_visit_entity.dart';
import '../providers/korwil_visit_provider.dart';

/// Korwil Visit List Screen
class KorwilVisitScreen extends StatefulWidget {
  const KorwilVisitScreen({super.key});

  @override
  State<KorwilVisitScreen> createState() => _KorwilVisitScreenState();
}

class _KorwilVisitScreenState extends State<KorwilVisitScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KorwilVisitNotifier>().loadVisits(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<KorwilVisitNotifier>().loadMoreVisits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kunjungan'),
        actions: [
          IconButton(
            icon: Icon(IconMap.refresh),
            onPressed: () {
              context.read<KorwilVisitNotifier>().loadVisits(refresh: true);
            },
          ),
        ],
      ),
      body: Consumer<KorwilVisitNotifier>(
        builder: (context, notifier, _) {
          return RefreshIndicator(
            onRefresh: () => notifier.loadVisits(refresh: true),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kunjungan...',
                      prefixIcon: Icon(IconMap.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(IconMap.close),
                              onPressed: () {
                                _searchController.clear();
                                notifier.loadVisits(refresh: true);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) {
                      notifier.loadVisits(refresh: true, search: value);
                    },
                  ),
                ),

                // Visit list
                Expanded(
                  child: _buildContent(notifier),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => context.push('/korwil-visit/create'),
          backgroundColor: AppColors.rgbPrimary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent(KorwilVisitNotifier notifier) {
    if (notifier.state.isLoading && notifier.state.visits.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (notifier.state.error != null && notifier.state.visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.errorOutline, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              notifier.state.error!,
              style: TextStyle(color: AppColors.slate500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () => notifier.loadVisits(refresh: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (notifier.state.visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconMap.locationOff, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              'Belum ada kunjungan',
              style: TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan + untuk membuat laporan kunjungan',
              style: TextStyle(color: AppColors.slate400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: notifier.state.visits.length + (notifier.state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= notifier.state.visits.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final visit = notifier.state.visits[index];
        return _VisitCard(visit: visit);
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  final KorwilVisitEntity visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/korwil-visit/${visit.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.rgbPrimary.withAlpha(26),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    IconMap.locationOn,
                    color: AppColors.rgbPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.clientName ?? 'Klien',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visit.areaName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconMap.chevronRight,
                  color: AppColors.slate400,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: IconMap.accessTime,
                  label: _formatTime(visit.inTime),
                ),
                const SizedBox(width: 12),
                if (visit.outTime != null)
                  _InfoChip(
                    icon: IconMap.checkCircle,
                    label: _formatTime(visit.outTime),
                  ),
                const Spacer(),
                if (visit.photoCount > 0)
                  Row(
                    children: [
                      Icon(IconMap.photoLibrary, size: 14, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Text(
                        '${visit.photoCount}',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                if (visit.videoCount > 0) ...[
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Icon(IconMap.videocam, size: 14, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Text(
                        '${visit.videoCount}',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.slate500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: chipColor),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: chipColor)),
      ],
    );
  }
}
