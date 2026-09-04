import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Change password screen
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate current password
    if (currentPassword.isEmpty) {
      setState(() => _currentPasswordError = 'Password saat ini wajib diisi');
      return;
    }

    // Validate new password
    if (newPassword.isEmpty) {
      setState(() => _newPasswordError = 'Password baru wajib diisi');
      return;
    }
    if (newPassword.length < 8) {
      setState(() => _newPasswordError = 'Password baru minimal 8 karakter');
      return;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Konfirmasi password wajib diisi');
      return;
    }
    if (confirmPassword != newPassword) {
      setState(() => _confirmPasswordError = 'Password tidak cocok');
      return;
    }

    // Submit
    _submit(currentPassword, newPassword);
  }

  Future<void> _submit(String currentPassword, String newPassword) async {
    final notifier = context.read<AuthNotifier>();
    final success = await notifier.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (success) {
      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMap.checkCircle,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password Berhasil Diubah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Password Anda telah berhasil diperbarui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'OK',
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
              ),
            ),
          ],
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.state.error ?? 'Gagal mengubah password'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final isLoading = authNotifier.state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Ganti Password'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withAlpha(51)),
              ),
              child: Row(
                children: [
                  Icon(
                    IconMap.infoOutline,
                    color: AppColors.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Password baru minimal 8 karakter',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current password
            AppTextField(
              label: 'Password Saat Ini',
              hint: 'Masukkan password saat ini',
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              errorText: _currentPasswordError,
              prefixIcon: Icon(IconMap.lock, color: AppColors.gray400),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.gray400,
                ),
                onPressed: () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                },
              ),
            ),
            const SizedBox(height: 16),

            // New password
            AppTextField(
              label: 'Password Baru',
              hint: 'Masukkan password baru',
              controller: _newPasswordController,
              obscureText: _obscureNew,
              errorText: _newPasswordError,
              prefixIcon: Icon(IconMap.lock, color: AppColors.gray400),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.gray400,
                ),
                onPressed: () {
                  setState(() => _obscureNew = !_obscureNew);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password
            AppTextField(
              label: 'Konfirmasi Password Baru',
              hint: 'Masukkan ulang password baru',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              errorText: _confirmPasswordError,
              prefixIcon: Icon(IconMap.lock, color: AppColors.gray400),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.gray400,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Simpan Password',
                isLoading: isLoading,
                onPressed: isLoading ? null : _validateAndSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
