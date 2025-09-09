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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ),
          
          AppTheme.horizontalSpaceMedium,
          
          // Month and year display
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
            ),
          ),
          
          AppTheme.horizontalSpaceMedium,
          
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
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}