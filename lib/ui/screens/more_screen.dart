import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../debug/database_debug_helper.dart';
import '../../providers/security_providers.dart';
import 'passcode_setup_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _showDisablePasscodeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disable Passcode'),
          content: const Text('Are you sure you want to disable passcode protection? This will make your app less secure.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(securitySettingsProvider.notifier).disablePasscode();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passcode protection disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Disable', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securitySettings = ref.watch(securitySettingsProvider);
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: AppTheme.primaryBackground,
      ),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          children: [
            // Debug section (only visible in debug mode)
            if (kDebugMode) ...[
              Card(
                child: Padding(
                  padding: AppTheme.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔧 Database Debug Tools',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppTheme.verticalSpaceSmall,
                      const Text(
                        'View and export SQLite database',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      AppTheme.verticalSpaceMedium,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await DatabaseDebugHelper.printAllAccounts();
                            },
                            icon: const Icon(Icons.account_balance_wallet, size: 18),
                            label: const Text('View Accounts'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await DatabaseDebugHelper.exportDatabase();
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Export DB'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await DatabaseDebugHelper.runFullDebugReport();
                            },
                            icon: const Icon(Icons.bug_report, size: 18),
                            label: const Text('Full Report'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppTheme.verticalSpaceLarge,
            ],
            
            // Settings section
            Card(
              child: Padding(
                padding: AppTheme.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚙️ Settings',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppTheme.verticalSpaceMedium,
                    ListTile(
                      leading: const Icon(Icons.lock, color: AppTheme.textPrimary),
                      title: const Text('Passcode & Biometric'),
                      subtitle: Text(securitySettings.isPasscodeEnabled 
                        ? 'App is secured with passcode${securitySettings.isBiometricEnabled ? ' and biometric' : ''}'
                        : 'Secure your app with PIN or biometric authentication'),
                      trailing: Switch(
                        value: securitySettings.isPasscodeEnabled,
                        onChanged: (value) async {
                          if (value) {
                            final result = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) => const PasscodeSetupScreen(),
                              ),
                            );
                            if (result != true && context.mounted) {
                              // User cancelled or setup failed, no action needed
                            }
                          } else {
                            _showDisablePasscodeDialog(context, ref);
                          }
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}