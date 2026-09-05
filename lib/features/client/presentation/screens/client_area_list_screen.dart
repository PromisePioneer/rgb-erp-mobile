import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../providers/client_dashboard_provider.dart';

/// Client area list screen with map
class ClientAreaListScreen extends StatelessWidget {
  const ClientAreaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Area'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ClientDashboardNotifier>().fetchAreas(),
          ),
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
                  const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text('Gagal memuat: ${notifier.areasError}'),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => notifier.fetchAreas(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (notifier.areas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: AppColors.gray400),
                  SizedBox(height: AppSpacing.md),
                  Text('Belum ada area'),
                ],
              ),
            );
          }

          return _AreaListContent(areas: notifier.areas);
        },
      ),
    );
  }
}

class _AreaListContent extends StatefulWidget {
  final List<ClientArea> areas;

  const _AreaListContent({required this.areas});

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
                              Icons.location_pin,
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
                        child: const Icon(
                          Icons.location_on,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (area.lat != null && area.lng != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${area.lat!.toStringAsFixed(5)}, ${area.lng!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
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
