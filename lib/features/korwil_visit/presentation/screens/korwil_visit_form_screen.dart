import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/feedback/loading_indicator.dart';
import '../../domain/entities/korwil_visit_entity.dart';
import '../providers/korwil_visit_provider.dart';

/// Korwil Visit Form Screen (Create/Edit)
class KorwilVisitFormScreen extends StatefulWidget {
  final int? visitId;

  const KorwilVisitFormScreen({super.key, this.visitId});

  @override
  State<KorwilVisitFormScreen> createState() => _KorwilVisitFormScreenState();
}

class _KorwilVisitFormScreenState extends State<KorwilVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inTimeController = TextEditingController();
  final _outTimeController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _clientNoteController = TextEditingController();
  final _fieldFindingsController = TextEditingController();
  final _fieldActionController = TextEditingController();
  final _solutionController = TextEditingController();

  final _imagePicker = ImagePicker();

  ClientOption? _selectedClient;
  DateTime? _inTime;
  DateTime? _outTime;
  List<String> _photoBase64List = [];
  List<String> _videoPathList = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  bool get isEditing => widget.visitId != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<KorwilVisitNotifier>();
      notifier.loadClientOptions();

      if (isEditing) {
        _loadVisitData();
      } else {
        _inTime = DateTime.now();
        _inTimeController.text = _formatDateTime(_inTime!);
      }
    });
  }

  Future<void> _loadVisitData() async {
    setState(() => _isLoading = true);

    final notifier = context.read<KorwilVisitNotifier>();

    // Load client options first
    await notifier.loadClientOptions();

    await notifier.loadVisitDetail(widget.visitId!);

    final visit = notifier.state.selectedVisit;
    if (visit != null) {
      _inTime = visit.inTime;
      _outTime = visit.outTime;
      _areaNameController.text = visit.areaName;
      _positionController.text = visit.position ?? '';
      _clientNoteController.text = visit.clientNote ?? '';
      _fieldFindingsController.text = visit.fieldFindings ?? '';
      _fieldActionController.text = visit.fieldAction ?? '';
      _solutionController.text = visit.solution ?? '';

      // Set selected client from loaded options
      _selectedClient = notifier.state.clientOptions
          .where((c) => c.id == visit.clientId)
          .firstOrNull;

      if (_inTime != null) {
        _inTimeController.text = _formatDateTime(_inTime!);
      }
      if (_outTime != null) {
        _outTimeController.text = _formatDateTime(_outTime!);
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _inTimeController.dispose();
    _outTimeController.dispose();
    _areaNameController.dispose();
    _positionController.dispose();
    _clientNoteController.dispose();
    _fieldFindingsController.dispose();
    _fieldActionController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isInTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isInTime ? (_inTime ?? DateTime.now()) : (_outTime ?? _inTime ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isInTime ? (_inTime ?? DateTime.now()) : (_outTime ?? DateTime.now())),
    );

    if (time == null || !mounted) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isInTime) {
        _inTime = dateTime;
        _inTimeController.text = _formatDateTime(dateTime);
      } else {
        _outTime = dateTime;
        _outTimeController.text = _formatDateTime(dateTime);
      }
    });
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    final bytes = await pickedFile.readAsBytes();
    final base64 = base64Encode(bytes);

    setState(() {
      _photoBase64List.add(base64);
    });
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );

    if (pickedFile == null || !mounted) return;

    setState(() {
      _videoPathList.add(pickedFile.path);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photoBase64List.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _videoPathList.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih klien terlebih dahulu')),
      );
      return;
    }

    if (_inTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu masuk wajib diisi')),
      );
      return;
    }

    if (_areaNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama area wajib diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = context.read<KorwilVisitNotifier>();

    if (isEditing) {
      await notifier.updateVisit(
        id: widget.visitId!,
        clientId: _selectedClient!.id,
        inTime: _inTime,
        outTime: _outTime,
        areaName: _areaNameController.text,
        position: _positionController.text.isNotEmpty ? _positionController.text : null,
        clientNote: _clientNoteController.text.isNotEmpty ? _clientNoteController.text : null,
        fieldFindings: _fieldFindingsController.text.isNotEmpty ? _fieldFindingsController.text : null,
        fieldAction: _fieldActionController.text.isNotEmpty ? _fieldActionController.text : null,
        solution: _solutionController.text.isNotEmpty ? _solutionController.text : null,
      );
    } else {
      await notifier.createVisit(
        clientId: _selectedClient!.id,
        inTime: _inTime!,
        outTime: _outTime,
        areaName: _areaNameController.text,
        position: _positionController.text.isNotEmpty ? _positionController.text : null,
        clientNote: _clientNoteController.text.isNotEmpty ? _clientNoteController.text : null,
        fieldFindings: _fieldFindingsController.text.isNotEmpty ? _fieldFindingsController.text : null,
        fieldAction: _fieldActionController.text.isNotEmpty ? _fieldActionController.text : null,
        solution: _solutionController.text.isNotEmpty ? _solutionController.text : null,
        photos: _photoBase64List.isNotEmpty ? _photoBase64List : null,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (notifier.state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notifier.state.error!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Laporan berhasil diperbarui' : 'Laporan berhasil disimpan')),
        );
        context.pop();
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kunjungan' : 'Laporan Kunjungan Baru'),
        actions: [
          TextButton(
            onPressed: context.pop,
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client dropdown
                    _buildSectionTitle('Informasi Klien', 'Pilih klien yang dikunjungi'),
                    const SizedBox(height: 12),
                    Consumer<KorwilVisitNotifier>(
                      builder: (context, notifier, _) {
                        return DropdownButtonFormField<ClientOption>(
                          value: _selectedClient,
                          decoration: const InputDecoration(
                            hintText: 'Pilih Klien',
                            border: OutlineInputBorder(),
                          ),
                          items: notifier.state.clientOptions.map((client) {
                            return DropdownMenuItem(
                              value: client,
                              child: Text(client.name),
                            );
                          }).toList(),
                          onChanged: (client) {
                            setState(() => _selectedClient = client);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Time information
                    _buildSectionTitle('Waktu Kunjungan', 'Catat waktu masuk dan keluar kunjungan'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _inTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Waktu Masuk *',
                              hintText: 'Pilih tanggal & jam',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(IconMap.calendarToday),
                                onPressed: () => _pickDateTime(true),
                              ),
                            ),
                            onTap: () => _pickDateTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _outTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Waktu Pulang',
                              hintText: 'Opsional',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(IconMap.calendarToday),
                                onPressed: () => _pickDateTime(false),
                              ),
                            ),
                            onTap: () => _pickDateTime(false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Location
                    _buildSectionTitle('Lokasi', 'Informasi area dan posisi kunjungan'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _areaNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Area *',
                        hintText: 'Contoh: Area Parkir Lt.2, Lobby Utama',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama area wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Posisi',
                        hintText: 'Contoh: Security Guard Pos A, Resepsionis',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notes
                    _buildSectionTitle('Catatan Kunjungan', 'Tambahkan catatan berdasarkan hasil kunjungan'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientNoteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Klien',
                        hintText: 'Catatan atau permintaan dari klien...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldFindingsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Temuan Lapangan',
                        hintText: 'Temukan masalah atau kondisi di lokasi...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldActionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Tindakan Lapangan',
                        hintText: 'Tindakan yang dilakukan di lokasi...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _solutionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Solusi',
                        hintText: 'Solusi atau rekomendasi yang diberikan...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Photos
                    _buildSectionTitle('Foto', 'Tambahkan foto sebagai bukti kunjungan'),
                    const SizedBox(height: 12),
                    if (_photoBase64List.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photoBase64List.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode(_photoBase64List[index]),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(IconMap.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: Icon(IconMap.cameraAlt),
                      label: const Text('Tambah Foto'),
                    ),

                    const SizedBox(height: 24),

                    // Videos
                    _buildSectionTitle('Video', 'Tambahkan video sebagai bukti kunjungan (opsional)'),
                    const SizedBox(height: 12),
                    if (_videoPathList.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _videoPathList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    color: AppColors.slate200,
                                    child: Icon(IconMap.videocam, size: 40),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeVideo(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(IconMap.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: Icon(IconMap.videocam),
                      label: const Text('Tambah Video'),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }
}
