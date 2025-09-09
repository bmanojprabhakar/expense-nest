import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../providers/stats_providers.dart';

class PeriodDropdown extends StatelessWidget {
  final StatsPeriod selectedPeriod;
  final String periodLabel;
  final DateTime currentDate;
  final Function(StatsPeriod) onPeriodChanged;
  final Function(DateTime) onDateChanged;

  const PeriodDropdown({
    super.key,
    required this.selectedPeriod,
    required this.periodLabel,
    required this.currentDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Period type dropdown - centered
          Expanded(
            flex: 2,
            child: Center(
              child: DropdownButton<StatsPeriod>(
                value: selectedPeriod,
                onChanged: (StatsPeriod? newValue) {
                  if (newValue != null) {
                    onPeriodChanged(newValue);
                  }
                },
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.cardBackground,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: StatsPeriod.values.map<DropdownMenuItem<StatsPeriod>>((StatsPeriod value) {
                  return DropdownMenuItem<StatsPeriod>(
                    value: value,
                    child: Text(_periodToString(value)),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Separator
          Container(
            width: 1,
            height: 24,
            color: AppTheme.textSecondary,
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
          ),
          
          // Period navigation
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous period button
                IconButton(
                  onPressed: () => _navigatePeriod(-1),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppTheme.textPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                
                // Current period label
                Expanded(
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Next period button
                IconButton(
                  onPressed: () => _navigatePeriod(1),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _periodToString(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'Week';
      case StatsPeriod.month:
        return 'Month';
      case StatsPeriod.year:
        return 'Year';
    }
  }

  void _navigatePeriod(int direction) {
    DateTime newDate;

    switch (selectedPeriod) {
      case StatsPeriod.week:
        newDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + (direction * 7),
        );
        break;
      case StatsPeriod.month:
        newDate = DateTime(
          currentDate.year,
          currentDate.month + direction,
          currentDate.day,
        );
        break;
      case StatsPeriod.year:
        newDate = DateTime(
          currentDate.year + direction,
          currentDate.month,
          currentDate.day,
        );
        break;
    }

    onDateChanged(newDate);
  }
}