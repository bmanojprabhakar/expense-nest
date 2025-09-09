import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transactions_screen.dart';
import 'stats_screen.dart';
import 'accounts_screen.dart';
import 'more_screen.dart';

// Provider for managing the current tab index
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    // List of screens corresponding to each tab
    final screens = [
      const TransactionsScreen(),
      const StatsScreen(),
      const AccountsScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF38383A),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF242426),
          selectedItemColor: const Color(0xFF007AFF),
          unselectedItemColor: const Color(0xFF8E8E93),
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(currentTabIndexProvider.notifier).state = index;
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, size: 24),
              activeIcon: Icon(Icons.calendar_today, size: 24),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart, size: 24),
              activeIcon: Icon(Icons.bar_chart, size: 24),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance, size: 24),
              activeIcon: Icon(Icons.account_balance, size: 24),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list, size: 24),
              activeIcon: Icon(Icons.list, size: 24),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}