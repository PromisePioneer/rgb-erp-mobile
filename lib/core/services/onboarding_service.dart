import '../services/storage_service.dart';

/// Service to manage onboarding tutorial
class OnboardingService {
  final StorageService _storage;

  OnboardingService(this._storage);

  /// Check if user has seen onboarding
  Future<bool> hasSeenOnboarding() async {
    return await _storage.hasSeenOnboarding;
  }

  /// Mark onboarding as seen
  Future<void> markOnboardingSeen() async {
    await _storage.setHasSeenOnboarding(true);
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await _storage.setHasSeenOnboarding(false);
  }
}
