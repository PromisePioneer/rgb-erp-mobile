import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../core/services/auto_start_service.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/banners/banner_carousel.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/toast/app_toast.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../providers/auth_provider.dart';
import '../widgets/biometric_section.dart';

/// Main login screen - auto-detects employee vs client login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _nikError;
  String? _passwordError;
  bool _showNikInput = false;
  bool _isEditingNik = false;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordLogin() async {
    final authNotifier = context.read<AuthNotifier>();

    if (authNotifier.state.isLoading) return;

    setState(() {
      _nikError = null;
      _passwordError = null;
    });

    // Get NIK from controller (if editing) or from savedNik
    String nik;
    if (_isEditingNik || _nikController.text.isNotEmpty) {
      nik = _nikController.text.trim();
    } else {
      nik = authNotifier.state.savedNik ?? '';
    }

    final password = _passwordController.text;

    if (nik.isEmpty) {
      setState(() {
        _nikError = 'NIK wajib diisi';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password wajib diisi';
      });
      return;
    }

    if (password.length < AppConstants.minPasswordLength) {
      setState(() {
        _passwordError = 'Password minimal 6 karakter';
      });
      return;
    }

    try {
      await authNotifier.login(code: nik, password: password);

      if (mounted) {
        AppToast.of(context).show(
          message: 'Login berhasil! Masuk dashboard...',
          style: AppToastStyle.success,
        );

        // Auto-detect user type and redirect accordingly
        final isClient = authNotifier.state.isClient;
        final destination = isClient ? '/client/dashboard' : '/dashboard';

        Future.delayed(Duration(milliseconds: 500), () {
          // Check and show auto-start guide after login
          _checkAndShowAutoStartGuide(context);
          context.go(destination);
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppToast.of(context).show(
          message: e.message,
          style: AppToastStyle.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.of(context).show(
          message: 'Error: ${e.toString()}',
          style: AppToastStyle.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEditingNik = false;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      await context.read<AuthNotifier>().loginWithBiometric();

      if (mounted) {
        // Biometric is only for employees
        // Check and show auto-start guide
        _checkAndShowAutoStartGuide(context);
        context.go('/dashboard');
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppToast.of(context).show(
          message: e.message,
          style: AppToastStyle.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.of(context).show(
          message: 'Biometric login gagal. Silakan coba lagi.',
          style: AppToastStyle.error,
        );
      }
    }
  }

  Future<void> _handleEnableBiometric() async {
    final nik = _nikController.text.trim();
    final password = _passwordController.text;

    if (nik.isEmpty || password.isEmpty) {
      if (mounted) {
        AppToast.of(context).show(
          message: 'Masukkan NIK dan password terlebih dahulu',
          style: AppToastStyle.warning,
        );
      }
      return;
    }

    try {
      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.login(code: nik, password: password);
      await authNotifier.enableBiometric(nik);

      if (mounted) {
        AppToast.of(context).show(
          message: 'Biometric berhasil diaktifkan',
          style: AppToastStyle.success,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppToast.of(context).show(
          message: e.message,
          style: AppToastStyle.error,
        );
      }
    }
  }

  /// Check and show auto-start guide after successful login
  Future<void> _checkAndShowAutoStartGuide(BuildContext context) async {
    // Check if auto-start is likely enabled
    final isEnabled = await AutoStartService.isAutoStartLikelyEnabled();

    if (isEnabled) {
      // Auto-start is already enabled, skip
      return;
    }

    // Get device brand
    final brand = AutoStartService.getDeviceBrand();
    final brandConfig = AutoStartBrandConfigs.getConfig(brand);

    // If it's a known brand (Chinese OEMs), show the guide
    if (brandConfig != null && mounted) {
      // Show the auto-start guide dialog
      _showAutoStartDialog(context, brandConfig);
    }
  }

  /// Show auto-start setup dialog
  void _showAutoStartDialog(BuildContext context, AutoStartBrandConfig config) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.notifications_active,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Aktifkan Auto-Start')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Untuk HP ${config.displayName}, Anda perlu mengaktifkan auto-start agar app tetap berjalan di background.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Langkah-langkah:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...config.steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti Saja'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              AutoStartService.openAutoStartSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top spacer
              const SizedBox(height: 100),

              // Middle: Banner carousel
              BannerCarousel(),

              const SizedBox(height: AppSpacing.xxl),

              // Bottom: Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Saved NIK display or input
                    if (!_showNikInput && authState.savedNik != null && !_isEditingNik) ...[
                      GestureDetector(
                        onTap: () {
                          _nikController.text = authState.savedNik!;
                          setState(() {
                            _showNikInput = true;
                            _isEditingNik = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: AppRadius.radiusMd,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                IconMap.person,
                                color: AppColors.gray600,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'NIK',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                    Text(
                                      authState.savedNik!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                IconMap.pencil,
                                color: AppColors.gray400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'NIK / Email',
                            hint: 'Masukkan NIK atau Email',
                            controller: _nikController,
                            onChanged: (value) {
                              setState(() {
                                _nikError = null;
                                if (!_isEditingNik && value.isNotEmpty) {
                                  _isEditingNik = true;
                                }
                              });
                            },
                            prefixIcon: Icon(IconMap.person),
                            errorText: _nikError,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Password input
                    PasswordTextField(
                      controller: _passwordController,
                      onChanged: (value) {
                        setState(() => _passwordError = null);
                      },
                      errorText: _passwordError,
                      textInputAction: TextInputAction.done,
                      onSubmitted: () => _handlePasswordLogin(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Login button
                    Builder(
                      builder: (context) {
                        final authNotifier = context.watch<AuthNotifier>();
                        final isLoading = authNotifier.state.isLoading;
                        return PrimaryButton(
                          label: 'Masuk',
                          isLoading: isLoading,
                          fullWidth: true,
                          onPressed: () {
                            _handlePasswordLogin();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Forgot password link
                    Center(
                      child: FButton(
                        onPress: () {
                          // Navigate to forgot password screen
                        },
                        variant: FButtonVariant.ghost,
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Biometric section
                    BiometricSection(
                      enabled: authState.biometricEnabled,
                      biometryType: authState.biometryType,
                      hasSavedCredentials: authState.savedNik != null,
                      onBiometricLogin: _handleBiometricLogin,
                      onEnableBiometric: _handleEnableBiometric,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Version info
                    const Text(
                      'Version 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
