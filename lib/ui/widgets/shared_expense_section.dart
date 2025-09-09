import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../screens/add_transaction_screen.dart';
import '../../services/group_service.dart';
import '../../data/models/group.dart';
import '../../data/models/user.dart';
import '../../data/database/database_helper.dart';

// Provider for group service
final groupServiceProvider = Provider<GroupService>((ref) {
  final dbHelper = DatabaseHelper();
  return GroupService(dbHelper);
});

// Provider for all expense groups
final expenseGroupsProvider = FutureProvider<List<ExpenseGroup>>((ref) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getAllGroups();
});

// Provider for group members
final groupMembersProvider = FutureProvider.family<List<User>, int>((ref, groupId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupMembers(groupId);
});

class SharedExpenseSection extends ConsumerWidget {
  const SharedExpenseSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = ref.watch(selectedGroupProvider);
    final groupsAsync = ref.watch(expenseGroupsProvider);
    
    return groupsAsync.when(
      data: (groups) => _buildSharedExpenseSection(context, ref, groups, selectedGroup),
      loading: () => _buildLoadingSection(context),
      error: (error, stack) => _buildErrorSection(context, error),
    );
  }

  Widget _buildSharedExpenseSection(BuildContext context, WidgetRef ref, List<ExpenseGroup> groups, int? selectedGroup) {
    final selectedGroupItem = groups.where((g) => g.id == selectedGroup).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group selection
          Row(
            children: [
              const Icon(
                Icons.group,
                color: AppTheme.activeTabColor,
              ),
              AppTheme.horizontalSpaceSmall,
              const Text(
                'Split with Group',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          AppTheme.verticalSpaceMedium,
          
          // Group selector
          InkWell(
            onTap: () {
              _showGroupPicker(context, ref, groups);
            },
            borderRadius: AppTheme.cardBorderRadius,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentBackground,
                borderRadius: AppTheme.cardBorderRadius,
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  if (selectedGroupItem != null) ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.activeTabColor,
                      child: Text(
                        selectedGroupItem.name[0],
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AppTheme.horizontalSpaceMedium,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedGroupItem.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          FutureBuilder<List<User>>(
                            future: ref.read(groupServiceProvider).getGroupMembers(selectedGroupItem.id!),
                            builder: (context, snapshot) {
                              final memberCount = snapshot.data?.length ?? 0;
                              return Text(
                                '$memberCount members',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.group_add, color: AppTheme.textSecondary),
                    AppTheme.horizontalSpaceMedium,
                    const Expanded(
                      child: Text(
                        'Select a group to split with',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          
          if (selectedGroupItem != null) ...[ 
            AppTheme.verticalSpaceMedium,
            
            // Split options
            _buildSplitOptions(context, ref, selectedGroupItem),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading groups...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.cardBorderRadius,
        border: Border.all(color: AppTheme.expenseColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppTheme.expenseColor),
          AppTheme.horizontalSpaceMedium,
          const Expanded(
            child: Text(
              'Failed to load groups',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitOptions(BuildContext context, WidgetRef ref, ExpenseGroup group) {
    final membersAsync = ref.watch(groupMembersProvider(group.id!));
    
    return membersAsync.when(
      data: (members) => _buildSplitOptionsWithMembers(context, ref, group, members),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Text(
        'Failed to load group members',
        style: TextStyle(color: AppTheme.expenseColor),
      ),
    );
  }

  Widget _buildSplitOptionsWithMembers(BuildContext context, WidgetRef ref, ExpenseGroup group, List<User> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Split Method',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        AppTheme.verticalSpaceSmall,
        
        // Equal split option (default)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.activeTabColor.withValues(alpha: 0.1),
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppTheme.activeTabColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.pie_chart,
                color: AppTheme.activeTabColor,
                size: 20,
              ),
              AppTheme.horizontalSpaceSmall,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equal Split',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Split equally among all ${members.length} members',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: AppTheme.activeTabColor,
                size: 20,
              ),
            ],
          ),
        ),
        
        AppTheme.verticalSpaceSmall,
        
        // Group members preview
        Text(
          'Members (${members.length})',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        
        AppTheme.verticalSpaceSmall,
        
        Wrap(
          spacing: 8,
          children: members.map((member) {
            return Chip(
              label: Text(
                member.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
              backgroundColor: AppTheme.accentBackground,
              side: const BorderSide(color: AppTheme.dividerColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showGroupPicker(BuildContext context, WidgetRef ref, List<ExpenseGroup> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppTheme.verticalSpaceMedium,
              
              // Title
              Text(
                'Select Group',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              AppTheme.verticalSpaceMedium,
              
              // Group list
              ...groups.map((group) {
                final isSelected = ref.read(selectedGroupProvider) == group.id;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedGroupProvider.notifier).state = group.id;
                      Navigator.of(context).pop();
                    },
                    borderRadius: AppTheme.cardBorderRadius,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.activeTabColor.withValues(alpha: 0.1) : AppTheme.cardBackground,
                        borderRadius: AppTheme.cardBorderRadius,
                        border: Border.all(
                          color: isSelected ? AppTheme.activeTabColor : AppTheme.dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isSelected ? AppTheme.activeTabColor : AppTheme.iconSecondary,
                            child: Text(
                              group.name[0],
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          AppTheme.horizontalSpaceMedium,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                FutureBuilder<List<User>>(
                                  future: ref.read(groupServiceProvider).getGroupMembers(group.id!),
                                  builder: (context, snapshot) {
                                    final memberCount = snapshot.data?.length ?? 0;
                                    return Text(
                                      '$memberCount members',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.activeTabColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              
              AppTheme.verticalSpaceMedium,
              
              // Create new group button
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Create group feature coming soon!'),
                      backgroundColor: AppTheme.activeTabColor,
                    ),
                  );
                },
                borderRadius: AppTheme.cardBorderRadius,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: AppTheme.cardBorderRadius,
                    border: Border.all(color: AppTheme.activeTabColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_add,
                        color: AppTheme.activeTabColor,
                      ),
                      AppTheme.horizontalSpaceSmall,
                      const Text(
                        'Create New Group',
                        style: TextStyle(
                          color: AppTheme.activeTabColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Extension for nullable firstOrNull
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}