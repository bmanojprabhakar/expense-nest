import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../services/account_service.dart';
import '../../data/models/account.dart';

class HierarchicalAccountTree extends StatefulWidget {
  final List<AccountNode> accountTree;
  final Function(AccountNode)? onAccountTap;
  final bool showBalances;

  const HierarchicalAccountTree({
    super.key,
    required this.accountTree,
    this.onAccountTap,
    this.showBalances = true,
  });

  @override
  State<HierarchicalAccountTree> createState() => _HierarchicalAccountTreeState();
}

class _HierarchicalAccountTreeState extends State<HierarchicalAccountTree> {
  final Set<String> _expandedNodes = <String>{};

  @override
  void initState() {
    super.initState();
    // Expand root level by default
    for (final node in widget.accountTree) {
      _expandedNodes.add(node.account.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: widget.accountTree.map((node) => _buildAccountNode(node, 0)).toList(),
    );
  }

  Widget _buildAccountNode(AccountNode node, int depth) {
    final isExpanded = _expandedNodes.contains(node.account.name);
    final hasChildren = node.children.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeTile(node, depth, hasChildren, isExpanded),
        if (hasChildren && isExpanded) ...[
          ...node.children.map((child) => _buildAccountNode(child, depth + 1)),
        ],
      ],
    );
  }

  Widget _buildNodeTile(AccountNode node, int depth, bool hasChildren, bool isExpanded) {
    final indentation = depth * 24.0;
    final account = node.account;
    final balance = widget.showBalances ? node.aggregatedBalance : account.balance;
    
    return Container(
      margin: EdgeInsets.only(
        left: indentation,
        bottom: 8,
        top: depth == 0 ? 16 : 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (hasChildren) {
              setState(() {
                if (isExpanded) {
                  _expandedNodes.remove(account.name);
                } else {
                  _expandedNodes.add(account.name);
                }
              });
            } else if (widget.onAccountTap != null) {
              widget.onAccountTap!(node);
            }
          },
          borderRadius: AppTheme.cardBorderRadius,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getNodeBackgroundColor(depth, hasChildren),
              borderRadius: AppTheme.cardBorderRadius,
              border: hasChildren && depth == 0 ? Border.all(
                color: AppTheme.dividerColor,
                width: 1,
              ) : null,
            ),
            child: Row(
              children: [
                // Expansion/Account Icon
                if (hasChildren) ...[
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getAccountIconColor(account, depth).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getAccountIcon(account, hasChildren),
                      color: _getAccountIconColor(account, depth),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Account Name
                Expanded(
                  child: Text(
                    account.name,
                    style: TextStyle(
                      color: _getTextColor(depth, hasChildren),
                      fontSize: _getFontSize(depth, hasChildren),
                      fontWeight: _getFontWeight(depth, hasChildren),
                    ),
                  ),
                ),
                
                // Balance
                if (widget.showBalances) ...[
                  Text(
                    AppTheme.formatCurrency(balance, showSign: false),
                    style: TextStyle(
                      color: _getBalanceColor(balance, hasChildren),
                      fontSize: _getFontSize(depth, hasChildren) - 1,
                      fontWeight: hasChildren ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNodeBackgroundColor(int depth, bool hasChildren) {
    if (depth == 0) {
      return AppTheme.cardBackground;
    } else if (hasChildren) {
      return AppTheme.cardBackground.withValues(alpha: 0.5);
    } else {
      return AppTheme.cardBackground.withValues(alpha: 0.3);
    }
  }

  Color _getTextColor(int depth, bool hasChildren) {
    if (depth == 0 || hasChildren) {
      return AppTheme.textPrimary;
    } else {
      return AppTheme.textPrimary.withValues(alpha: 0.9);
    }
  }

  double _getFontSize(int depth, bool hasChildren) {
    if (depth == 0) return 18;
    if (hasChildren) return 16;
    return 15;
  }

  FontWeight _getFontWeight(int depth, bool hasChildren) {
    if (depth == 0) return FontWeight.w700;
    if (hasChildren) return FontWeight.w600;
    return FontWeight.w500;
  }

  Color _getBalanceColor(double balance, bool hasChildren) {
    if (hasChildren) {
      return balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;
    } else {
      return balance >= 0 ? AppTheme.textPrimary : AppTheme.expenseColor;
    }
  }

  IconData _getAccountIcon(Account account, bool hasChildren) {
    if (hasChildren) return Icons.folder;
    
    // Based on account name or type
    final name = account.name.toLowerCase();
    if (name.contains('credit')) return Icons.credit_card;
    if (name.contains('debit')) return Icons.credit_card;
    if (name.contains('bank') || name.contains('icici') || name.contains('hdfc') || name.contains('axis') || name.contains('indusind')) return Icons.account_balance;
    if (name.contains('cash') || name.contains('wallet')) return Icons.account_balance_wallet;
    if (name.contains('savings')) return Icons.savings;
    if (name.contains('meal') || name.contains('food')) return Icons.restaurant;
    if (name.contains('pay') || name.contains('phonepe') || name.contains('amazon')) return Icons.payment;
    
    return Icons.account_circle;
  }

  Color _getAccountIconColor(Account account, int depth) {
    if (depth == 0) return AppTheme.activeTabColor;
    
    final name = account.name.toLowerCase();
    if (name.contains('credit')) return Colors.red;
    if (name.contains('savings') || name.contains('bank')) return Colors.green;
    if (name.contains('cash') || name.contains('wallet')) return Colors.orange;
    if (name.contains('meal')) return Colors.brown;
    if (name.contains('pay')) return Colors.purple;
    
    return AppTheme.textSecondary;
  }
}