import 'package:flutter/material.dart';
import '../services/auto_start_service.dart';

/// Screen untuk guide user mengaktifkan auto-start
class AutoStartGuideScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool isRequired;

  const AutoStartGuideScreen({
    super.key,
    this.onCompleted,
    this.isRequired = false,
  });

  @override
  State<AutoStartGuideScreen> createState() => _AutoStartGuideScreenState();
}

class _AutoStartGuideScreenState extends State<AutoStartGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late String _deviceBrand;
  AutoStartBrandConfig? _brandConfig;
  bool _hasOpenedSettings = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _detectDevice();
  }

  void _detectDevice() {
    _deviceBrand = AutoStartService.getDeviceBrand();
    _brandConfig = AutoStartBrandConfigs.getConfig(_deviceBrand);

    if (_brandConfig == null) {
      _brandConfig = AutoStartBrandConfig(
        brand: 'generic',
        displayName: _deviceBrand.isNotEmpty ? _deviceBrand : 'HP Anda',
        description: 'Anda perlu mengizinkan RGB 86 berjalan di background agar fitur patroli dan absensi tetap berjalan dengan baik.',
        steps: [
          'Buka Settings (Pengaturan)',
          'Pilih "Apps" atau "Aplikasi"',
          'Cari dan pilih "RGB 86"',
          'Cari opsi "Battery" atau "Baterai"',
          'Pilih "Don\'t optimize" atau "Jangan optimalkan"',
          'Aktifkan semua background permissions',
        ],
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openAutoStartSettings() async {
    setState(() => _hasOpenedSettings = true);
    await AutoStartService.openAutoStartSettings();
  }

  Future<void> _checkAndContinue() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isChecking = false);
      _proceed();
    }
  }

  void _proceed() {
    widget.onCompleted?.call();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _skip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lewati Langkah Ini?'),
        content: const Text('App mungkin tidak berjalan optimal di background jika auto-start tidak diaktifkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _proceed();
            },
            child: const Text('Ya, Lewati'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktifkan Auto-Start'),
        automaticallyImplyLeading: !widget.isRequired,
        actions: [
          if (!widget.isRequired)
            TextButton(
              onPressed: _skip,
              child: const Text('Lewati'),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 2,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildExplanationPage(colorScheme),
                _buildInstructionsPage(colorScheme),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Kembali'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _currentPage == 0
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : _checkAndContinue,
                      child: _isChecking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_currentPage == 0 ? 'Lanjut' : 'Selesai'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationPage(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 60,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Aktifkan Auto-Start',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Agar RGB 86 tetap berjalan di background meskipun aplikasi ditutup, Anda perlu mengaktifkan auto-start.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_brandConfig != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android, size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Terdeteksi: ${_brandConfig!.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsPage(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah-Langkah',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _brandConfig?.description ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          if (_brandConfig != null)
            ...List.generate(_brandConfig!.steps.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _brandConfig!.steps[index],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAutoStartSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan Auto-Start'),
            ),
          ),
        ],
      ),
    );
  }
}
