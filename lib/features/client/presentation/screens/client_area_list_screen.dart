import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../providers/client_dashboard_provider.dart';

/// Client area list screen with map
class ClientAreaListScreen extends StatelessWidget {
  const ClientAreaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Area'),
        actions: [
          FButton.icon(
            onPress: () => context.read<ClientDashboardNotifier>().fetchAreas(),
            child: const Icon(FLucideIcons.refreshCcw),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ClientDashboardNotifier>(
        builder: (context, notifier, child) {
          if (notifier.isLoadingAreas) {
            return const Center(child: LoadingIndicator());
          }

          if (notifier.areasError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FLucideIcons.alertCircle, size: 64, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text('Gagal memuat: ${notifier.areasError}', style: theme.typography.body.md),
                  const SizedBox(height: AppSpacing.lg),
                  FButton(
                    onPress: () => notifier.fetchAreas(),
                    variant: FButtonVariant.primary,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (notifier.areas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FLucideIcons.mapPinOff, size: 64, color: AppColors.gray400),
                  const SizedBox(height: AppSpacing.md),
                  Text('Belum ada area', style: theme.typography.body.md),
                ],
              ),
            );
          }

          return _AreaListContent(areas: notifier.areas, theme: theme);
        },
      ),
    );
  }
}

class _AreaListContent extends StatefulWidget {
  final List<ClientArea> areas;
  final FThemeData theme;

  const _AreaListContent({required this.areas, required this.theme});

  @override
  State<_AreaListContent> createState() => _AreaListContentState();
}

class _AreaListContentState extends State<_AreaListContent> {
  ClientArea? _selectedArea;

  @override
  void initState() {
    super.initState();
    if (widget.areas.isNotEmpty) {
      _selectedArea = widget.areas.first;
    }
  }

  LatLng get _mapCenter {
    if (_selectedArea?.lat != null && _selectedArea?.lng != null) {
      return LatLng(_selectedArea!.lat!, _selectedArea!.lng!);
    }
    return const LatLng(-2.5, 118.0);
  }

  double get _mapZoom {
    if (_selectedArea?.lat != null && _selectedArea?.lng != null) {
      return 16;
    }
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map
        SizedBox(
          height: 250,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _mapZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rgb.erp_mobile_new',
              ),
              MarkerLayer(
                markers: widget.areas
                    .where((a) => a.lat != null && a.lng != null)
                    .map((area) => Marker(
                          point: LatLng(area.lat!, area.lng!),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedArea = area;
                              });
                            },
                            child: Icon(
                              FLucideIcons.mapPin,
                              color: area.id == _selectedArea?.id
                                  ? AppColors.danger
                                  : AppColors.primary,
                              size: 40,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        // Area list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: widget.areas.length,
            itemBuilder: (context, index) {
              final area = widget.areas[index];
              final isSelected = area.id == _selectedArea?.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedArea = area;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withAlpha(26) : Colors.white,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          FLucideIcons.mapPin,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area.name,
                              style: widget.theme.typography.body.md.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (area.lat != null && area.lng != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${area.lat!.toStringAsFixed(5)}, ${area.lng!.toStringAsFixed(5)}',
                                style: widget.theme.typography.body.xs.copyWith(
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          FLucideIcons.checkCircle,
                          color: AppColors.primary,
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
}
