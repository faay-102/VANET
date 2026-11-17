import 'package:flutter_test/flutter_test.dart';
import 'package:vanet_mobile/features/shared/authentication/presentation/auth_provider.dart';

void main() {
  group('AuthState Model Tests', () {
    test('Default initial AuthState properties', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.hasCompletedSplash, isFalse);
      expect(state.hasSeenOnboarding, isFalse);
      expect(state.email, isNull);
      expect(state.displayName, isNull);
      expect(state.role, equals('Admin'));
      expect(state.isAdmin, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('Role recognition for Admin and Driver', () {
      const adminState = AuthState(role: 'Admin');
      expect(adminState.isAdmin, isTrue);

      const driverState = AuthState(role: 'Driver');
      expect(driverState.isAdmin, isFalse);

      const userState = AuthState(role: 'User');
      expect(userState.isAdmin, isFalse);
    });

    test('CopyWith updates fields accurately', () {
      const initial = AuthState();
      final updated = initial.copyWith(
        isAuthenticated: true,
        email: 'test@vanet.com',
        displayName: 'Test Operator',
        role: 'Driver',
        hasCompletedSplash: true,
        hasSeenOnboarding: true,
      );

      expect(updated.isAuthenticated, isTrue);
      expect(updated.email, equals('test@vanet.com'));
      expect(updated.displayName, equals('Test Operator'));
      expect(updated.role, equals('Driver'));
      expect(updated.isAdmin, isFalse);
      expect(updated.hasCompletedSplash, isTrue);
      expect(updated.hasSeenOnboarding, isTrue);
    });
  });
}
