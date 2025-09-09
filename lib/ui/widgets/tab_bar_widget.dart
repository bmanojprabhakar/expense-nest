import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TabBarWidget extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;
  final List<String>? tabs;

  const TabBarWidget({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.tabs,
  });

  static const List<String> defaultTabs = [
    'Daily',
    'Calendar', 
    'Monthly',
    'Summary',
    'Description',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: (tabs ?? defaultTabs).map((tab) {
          final isSelected = tab == selectedTab;
          
          return Expanded(
            child: InkWell(
              onTap: () => onTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppTheme.activeTabColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textTertiary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}