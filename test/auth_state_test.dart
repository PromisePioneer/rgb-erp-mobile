import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_erp_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:rgb_erp_mobile/core/core.dart';

void main() {
  group('AuthState', () {
    test('initial state should be unauthenticated', () {
      final state = AuthState();

      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.user, null);
      expect(state.token, null);
      expect(state.error, isNull);
    });

    test('copyWith preserves values correctly', () {
      final state = AuthState();
      final newState = state.copyWith(
        isAuthenticated: true,
        savedNik: '12345',
      );

      expect(newState.isAuthenticated, true);
      expect(newState.savedNik, '12345');
    });

    test('copyWith clears user and token when clearUser is true', () {
      final state = AuthState(
        isAuthenticated: true,
        token: 'test_token',
        user: null,
      );
      final cleared = state.copyWith(clearUser: true);

      expect(cleared.token, isNull);
      expect(cleared.user, isNull);
      // Note: isAuthenticated is NOT cleared - it's preserved in this copyWith call
    });

    test('copyWith clears error when clearError is true', () {
      final state = AuthState(error: 'test error');
      final cleared = state.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });
  });

  group('AppConstants', () {
    test('apiBaseUrl should be correct', () {
      expect(AppConstants.apiBaseUrl, isNotEmpty);
    });

    test('minPasswordLength should be 6', () {
      expect(AppConstants.minPasswordLength, 6);
    });
  });
}
