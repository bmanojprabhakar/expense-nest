import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../providers/security_providers.dart';

class PasscodeSetupScreen extends ConsumerStatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  ConsumerState<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends ConsumerState<PasscodeSetupScreen> {
  String _passcode = '';
  String _confirmPasscode = '';
  bool _isConfirming = false;
  bool _enableBiometric = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await ref.read(securitySettingsProvider.notifier).checkBiometricAvailability();
    setState(() {
      _biometricAvailable = available;
    });
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_isConfirming) {
        if (_confirmPasscode.length < 4) {
          _confirmPasscode += number;
          if (_confirmPasscode.length == 4) {
            _validatePasscode();
          }
        }
      } else {
        if (_passcode.length < 4) {
          _passcode += number;
          if (_passcode.length == 4) {
            setState(() {
              _isConfirming = true;
            });
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPasscode.isNotEmpty) {
          _confirmPasscode = _confirmPasscode.substring(0, _confirmPasscode.length - 1);
        }
      } else {
        if (_passcode.isNotEmpty) {
          _passcode = _passcode.substring(0, _passcode.length - 1);
        }
      }
    });
  }

  void _validatePasscode() {
    if (_passcode == _confirmPasscode) {
      _setupPasscode();
    } else {
      _showError('Passcodes do not match. Please try again.');
      _resetPasscodes();
    }
  }

  Future<void> _setupPasscode() async {
    try {
      await ref.read(securitySettingsProvider.notifier).setPasscode(_passcode, _enableBiometric);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passcode set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to set passcode. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetPasscodes() {
    setState(() {
      _passcode = '';
      _confirmPasscode = '';
      _isConfirming = false;
    });
  }

  Widget _buildPasscodeDisplay() {
    final currentPasscode = _isConfirming ? _confirmPasscode : _passcode;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < currentPasscode.length ? AppTheme.activeTabColor : AppTheme.textSecondary,
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 0; col < 3; col++)
                  _buildNumberButton('${row * 3 + col + 1}'),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80),
              _buildNumberButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardBackground,
          border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onDeletePressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardBackground,
          border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
        ),
        child: const Icon(
          Icons.backspace_outlined,
          color: AppTheme.textPrimary,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Setup Passcode'),
        backgroundColor: AppTheme.primaryBackground,
      ),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.security,
              size: 64,
              color: AppTheme.activeTabColor,
            ),
            AppTheme.verticalSpaceLarge,
            Text(
              _isConfirming ? 'Confirm your passcode' : 'Create a 4-digit passcode',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppTheme.verticalSpaceMedium,
            Text(
              _isConfirming 
                ? 'Please enter your passcode again'
                : 'Choose a 4-digit passcode to secure your app',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppTheme.verticalSpaceLarge,
            _buildPasscodeDisplay(),
            AppTheme.verticalSpaceLarge,
            _buildNumberPad(),
            const Spacer(),
            if (_biometricAvailable && !_isConfirming) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: const Text(
                    'Enable Biometric',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Use fingerprint/face for quick access',
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  value: _enableBiometric,
                  onChanged: (value) {
                    setState(() {
                      _enableBiometric = value;
                    });
                  },
                  activeColor: AppTheme.activeTabColor,
                ),
              ),
            ],
            AppTheme.verticalSpaceMedium,
          ],
        ),
      ),
    );
  }
}