import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';
import '../../providers/stats_providers.dart';

class StatsPieChart extends StatelessWidget {
  final List<CategoryStats> categoryStats;
  final double totalAmount;
  final bool isIncome;

  const StatsPieChart({
    super.key,
    required this.categoryStats,
    required this.totalAmount,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          // Compact total amount display
          Text(
            isIncome ? 'Total Income' : 'Total Expenses',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12, // Reduced font size
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            '₹${_formatCurrency(totalAmount)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20, // Reduced from 24
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8), // Reduced from 20
          
          // Pie chart with arrow labels - Flexible container
          SizedBox(
            height: 240, // Increased slightly to accommodate labels
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main pie chart - centered and optimized size
                Center(
                  child: SizedBox(
                    height: 160, // Reduced from 180
                    width: 160,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 35, // Reduced from 40
                        sectionsSpace: 1,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                  ),
                ),
                // Arrow labels removed for now
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = _generateColors(categoryStats.length);
    
    return categoryStats.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: category.percentage,
        title: '', // Remove title as we'll use arrow labels
        radius: 62, // Reduced to match smaller 160px chart
      );
    }).toList();
  }

  List<Color> _generateColors(int count) {
    // Generate a nice color palette for categories
    const baseColors = [
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
    
    List<Color> colors = [];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    
    return colors;
  }

  // Arrow labels method removed temporarily

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

// ArrowPainter class removed temporarily