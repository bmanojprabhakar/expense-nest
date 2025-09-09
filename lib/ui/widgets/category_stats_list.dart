import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../providers/stats_providers.dart';

class CategoryStatsList extends StatelessWidget {
  final List<CategoryStats> categoryStats;

  const CategoryStatsList({
    super.key,
    required this.categoryStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Category Breakdown',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Category list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryStats.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppTheme.textSecondary,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final category = categoryStats[index];
              final color = _getCategoryColor(index);
              
              return _buildCategoryItem(category, color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryStats category, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Category info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.transactionCount} transaction${category.transactionCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Amount and percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatCurrency(category.totalAmount)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${category.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    // Same colors as used in pie chart
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFFEC4899), // Pink
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF8B5CF6), // Violet
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF97316), // Orange
      Color(0xFF84CC16), // Lime
      Color(0xFF14B8A6), // Teal
    ];
    
    return colors[index % colors.length];
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}