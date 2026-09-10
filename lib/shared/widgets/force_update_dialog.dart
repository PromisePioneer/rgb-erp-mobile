import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_update_service.dart';

class ForceUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const ForceUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Update Tersedia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi ${widget.updateInfo.version} sudah tersedia!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ukuran: ${widget.updateInfo.fileSizeFormatted}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (widget.updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Release Notes:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                widget.updateInfo.releaseNotes!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text(
                'Mengunduh... ${(_downloadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading)
            TextButton(
              onPressed: () {
                // Force update - tidak bisa dismiss
                _startDownload();
              },
              child: const Text('Update Sekarang'),
            ),
        ],
      );
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final success = await AppUpdateService.downloadAndInstall(widget.updateInfo);

    if (!success && mounted) {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh update. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Show force update dialog
Future<void> showForceUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) async {
  await showDialog(
    context: context,
    barrierDismissible: false, // Cannot dismiss by tapping outside
    builder: (context) => ForceUpdateDialog(updateInfo: updateInfo),
  );
}
