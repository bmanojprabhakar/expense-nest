import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class SecuritySettings {
  final bool isPasscodeEnabled;
  final bool isBiometricEnabled;
  final String? passcodeHash;

  SecuritySettings({
    this.isPasscodeEnabled = false,
    this.isBiometricEnabled = false,
    this.passcodeHash,
  });

  SecuritySettings copyWith({
    bool? isPasscodeEnabled,
    bool? isBiometricEnabled,
    String? passcodeHash,
  }) {
    return SecuritySettings(
      isPasscodeEnabled: isPasscodeEnabled ?? this.isPasscodeEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      passcodeHash: passcodeHash ?? this.passcodeHash,
    );
  }
}

class SecuritySettingsNotifier extends StateNotifier<SecuritySettings> {
  SecuritySettingsNotifier() : super(SecuritySettings()) {
    _loadSettings();
  }

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/security_settings.json');
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        state = SecuritySettings(
          isPasscodeEnabled: json['passcode_enabled'] ?? false,
          isBiometricEnabled: json['biometric_enabled'] ?? false,
          passcodeHash: json['passcode_hash'],
        );
      }
    } catch (e) {
      // If loading fails, use default settings
      state = SecuritySettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();
      final json = {
        'passcode_enabled': state.isPasscodeEnabled,
        'biometric_enabled': state.isBiometricEnabled,
        'passcode_hash': state.passcodeHash,
      };
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Handle save error silently for now
      print('Error saving security settings: $e');
    }
  }

  Future<bool> checkBiometricAvailability() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return isAvailable && canCheckBiometrics && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access ExpenseNest',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      return false;
    }
  }

  String _hashPasscode(String passcode) {
    // Simple hash for demo - in production, use proper cryptographic hashing
    return passcode.split('').map((e) => e.codeUnitAt(0)).join();
  }

  Future<void> setPasscode(String passcode, bool enableBiometric) async {
    final hashedPasscode = _hashPasscode(passcode);
    state = state.copyWith(
      isPasscodeEnabled: true,
      isBiometricEnabled: enableBiometric,
      passcodeHash: hashedPasscode,
    );
    await _saveSettings();
  }

  Future<bool> verifyPasscode(String passcode) async {
    if (state.passcodeHash == null) return false;
    return _hashPasscode(passcode) == state.passcodeHash;
  }

  Future<void> disablePasscode() async {
    state = SecuritySettings();
    await _saveSettings();
  }

  Future<void> toggleBiometric(bool enabled) async {
    state = state.copyWith(isBiometricEnabled: enabled);
    await _saveSettings();
  }
}

final securitySettingsProvider = StateNotifierProvider<SecuritySettingsNotifier, SecuritySettings>((ref) {
  return SecuritySettingsNotifier();
});