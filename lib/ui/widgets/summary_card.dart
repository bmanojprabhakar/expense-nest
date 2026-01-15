import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double total;
  final bool showStatementInfo;

  const SummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.total,
    this.showStatementInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to detailed summary
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Income column
              _buildSummaryColumn(
                label: 'Income',
                amount: income,
                color: AppTheme.incomeColor,
                alignment: CrossAxisAlignment.start,
              ),
              
              // Expense column  
              _buildSummaryColumn(
                label: 'Expense',
                amount: expense,
                color: AppTheme.expenseColor,
                alignment: CrossAxisAlignment.center,
              ),
              
              // Total column
              _buildSummaryColumn(
                label: 'Total',
                amount: total,
                color: AppTheme.textPrimary,
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required double amount,
    required Color color,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppTheme.formatCurrency(amount, showSign: false),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}