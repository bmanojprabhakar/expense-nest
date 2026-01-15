import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class MonthNavigation extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const MonthNavigation({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous month button
          IconButton(
            onPressed: () {
              final previousMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
                1,
              );
              onMonthChanged(previousMonth);
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.textTertiary,
              size: 16,
            ),
          ),
          
          AppTheme.horizontalSpaceSmall,
          
          // Month and year display
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
          
          AppTheme.horizontalSpaceSmall,
          
          // Next month button
          IconButton(
            onPressed: () {
              final nextMonth = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
                1,
              );
              onMonthChanged(nextMonth);
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textTertiary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}