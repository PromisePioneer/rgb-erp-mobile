import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/banners/banner_carousel.dart';
import '../providers/auth_provider.dart';
import '../widgets/biometric_section.dart';

/// Main login screen
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
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordLogin() async {
    if (_isLoggingIn) return;

    setState(() {
      _nikError = null;
      _passwordError = null;
      _isLoggingIn = true;
    });

    final nik = _nikController.text.trim();
    final password = _passwordController.text;

    if (nik.isEmpty) {
      setState(() {
        _nikError = 'NIK wajib diisi';
        _isLoggingIn = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password wajib diisi';
        _isLoggingIn = false;
      });
      return;
    }

    if (password.length < AppConstants.minPasswordLength) {
      setState(() {
        _passwordError = 'Password minimal 6 karakter';
        _isLoggingIn = false;
      });
      return;
    }

    try {
      final authNotifier = context.read<AuthNotifier>();
      final result = await authNotifier.login(code: nik, password: password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil! Masuk dashboard...'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          context.go('/dashboard');
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      print('LOGIN CATCH ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      print('BIOMETRIC LOGIN START');
      await context.read<AuthNotifier>().loginWithBiometric();
      print('BIOMETRIC LOGIN SUCCESS');

      if (mounted) {
        print('NAVIGATING TO DASHBOARD (BIOMETRIC)');
        context.go('/dashboard');
      }
    } on ApiException catch (e) {
      print('BIOMETRIC LOGIN API ERROR: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      print('BIOMETRIC LOGIN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login gagal. Silakan coba lagi.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleEnableBiometric() async {
    final nik = _nikController.text.trim();
    final password = _passwordController.text;

    if (nik.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan NIK dan password terlebih dahulu'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.login(code: nik, password: password);
      await authNotifier.enableBiometric(nik);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric berhasil diaktifkan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
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
              const BannerCarousel(),

              const SizedBox(height: AppSpacing.xxl),

              // Bottom: Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Saved NIK display or input
                    if (!_showNikInput && authState.savedNik != null) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showNikInput = true),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: AppRadius.radiusMd,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
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
                              const Icon(
                                Icons.edit,
                                color: AppColors.gray400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // NIK input
                      NikTextField(
                        controller: _showNikInput ? _nikController : null,
                        initialValue: _showNikInput ? null : authState.savedNik,
                        onChanged: (value) {
                          setState(() {
                            _nikError = null;
                            _showNikInput = value.isNotEmpty;
                          });
                        },
                        errorText: _nikError,
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
                    ElevatedButton(
                      onPressed: _isLoggingIn ? null : _handlePasswordLogin,
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Forgot password link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Navigate to forgot password screen
                        },
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

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
