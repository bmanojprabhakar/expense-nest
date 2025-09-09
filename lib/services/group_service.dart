import '../data/database/database_helper.dart';
import '../data/models/user.dart';
import '../data/models/group.dart';
import '../data/models/group_member.dart';

class GroupService {
  final DatabaseHelper _databaseHelper;

  GroupService(this._databaseHelper);

  // Create a new user
  Future<User> createUser({
    required String name,
    String? email,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('User name cannot be empty');
    }

    // Check if user with same name already exists
    final existingUsers = await _databaseHelper.getAllUsers();
    if (existingUsers.any((u) => u.name.toLowerCase() == name.trim().toLowerCase())) {
      throw ArgumentError('User with name "$name" already exists');
    }

    final user = User(
      name: name.trim(),
      email: email?.trim(),
      createdAt: DateTime.now(),
    );

    final id = await _databaseHelper.insertUser(user);
    return user.copyWith(id: id);
  }

  // Get all active users
  Future<List<User>> getAllUsers({bool includeInactive = false}) async {
    return await _databaseHelper.getAllUsers(activeOnly: !includeInactive);
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    return await _databaseHelper.getUser(id);
  }

  // Update user details
  Future<User> updateUser({
    required int id,
    String? name,
    String? email,
  }) async {
    final existingUser = await _databaseHelper.getUser(id);
    if (existingUser == null) {
      throw ArgumentError('User with ID $id not found');
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('User name cannot be empty');
    }

    // Check for name conflicts if name is being changed
    if (name != null && name.trim().toLowerCase() != existingUser.name.toLowerCase()) {
      final allUsers = await _databaseHelper.getAllUsers();
      if (allUsers.any((u) => u.id != id && u.name.toLowerCase() == name.trim().toLowerCase())) {
        throw ArgumentError('User with name "$name" already exists');
      }
    }

    final updatedUser = existingUser.copyWith(
      name: name?.trim() ?? existingUser.name,
      email: email?.trim() ?? existingUser.email,
    );

    await _databaseHelper.updateUser(updatedUser);
    return updatedUser;
  }

  // Deactivate user (soft delete)
  Future<void> deactivateUser(int id) async {
    final existingUser = await _databaseHelper.getUser(id);
    if (existingUser == null) {
      throw ArgumentError('User with ID $id not found');
    }

    // Check if user is part of any active groups
    final userGroups = await getUserGroups(id);
    if (userGroups.isNotEmpty) {
      // Remove user from all groups first
      for (final group in userGroups) {
        await removeUserFromGroup(group.id!, id);
      }
    }

    await _databaseHelper.deleteUser(id);
  }

  // Create a new expense group
  Future<ExpenseGroup> createGroup({
    required String name,
    String? description,
    List<int> memberIds = const [],
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty');
    }

    // Check if group with same name already exists
    final existingGroups = await _databaseHelper.getAllGroups();
    if (existingGroups.any((g) => g.name.toLowerCase() == name.trim().toLowerCase())) {
      throw ArgumentError('Group with name "$name" already exists');
    }

    // Validate that all member IDs exist
    for (final memberId in memberIds) {
      final user = await _databaseHelper.getUser(memberId);
      if (user == null) {
        throw ArgumentError('User with ID $memberId not found');
      }
    }

    final group = ExpenseGroup(
      name: name.trim(),
      description: description?.trim(),
      createdAt: DateTime.now(),
    );

    final groupId = await _databaseHelper.insertGroup(group);
    final createdGroup = group.copyWith(id: groupId);

    // Add members to the group
    for (final memberId in memberIds) {
      await _addUserToGroup(groupId, memberId);
    }

    return createdGroup;
  }

  // Get all active groups
  Future<List<ExpenseGroup>> getAllGroups({bool includeInactive = false}) async {
    return await _databaseHelper.getAllGroups(activeOnly: !includeInactive);
  }

  // Get group by ID
  Future<ExpenseGroup?> getGroupById(int id) async {
    return await _databaseHelper.getGroup(id);
  }

  // Get groups that a user belongs to
  Future<List<ExpenseGroup>> getUserGroups(int userId) async {
    final allGroups = await _databaseHelper.getAllGroups();
    final userGroups = <ExpenseGroup>[];

    for (final group in allGroups) {
      final members = await _databaseHelper.getGroupMembers(group.id!);
      if (members.any((member) => member.userId == userId)) {
        userGroups.add(group);
      }
    }

    return userGroups;
  }

  // Update group details
  Future<ExpenseGroup> updateGroup({
    required int id,
    String? name,
    String? description,
  }) async {
    final existingGroup = await _databaseHelper.getGroup(id);
    if (existingGroup == null) {
      throw ArgumentError('Group with ID $id not found');
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty');
    }

    // Check for name conflicts if name is being changed
    if (name != null && name.trim().toLowerCase() != existingGroup.name.toLowerCase()) {
      final allGroups = await _databaseHelper.getAllGroups();
      if (allGroups.any((g) => g.id != id && g.name.toLowerCase() == name.trim().toLowerCase())) {
        throw ArgumentError('Group with name "$name" already exists');
      }
    }

    final updatedGroup = existingGroup.copyWith(
      name: name?.trim() ?? existingGroup.name,
      description: description?.trim() ?? existingGroup.description,
    );

    await _databaseHelper.updateGroup(updatedGroup);
    return updatedGroup;
  }

  // Add user to group
  Future<void> addUserToGroup(int groupId, int userId) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null) {
      throw ArgumentError('Group with ID $groupId not found');
    }

    final user = await _databaseHelper.getUser(userId);
    if (user == null) {
      throw ArgumentError('User with ID $userId not found');
    }

    // Check if user is already in the group
    final existingMembers = await _databaseHelper.getGroupMembers(groupId);
    if (existingMembers.any((member) => member.userId == userId)) {
      throw ArgumentError('User is already a member of this group');
    }

    await _addUserToGroup(groupId, userId);
  }

  // Private helper to add user to group
  Future<void> _addUserToGroup(int groupId, int userId) async {
    final groupMember = GroupMember(
      groupId: groupId,
      userId: userId,
      joinedAt: DateTime.now(),
    );

    await _databaseHelper.insertGroupMember(groupMember);
  }

  // Remove user from group
  Future<void> removeUserFromGroup(int groupId, int userId) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null) {
      throw ArgumentError('Group with ID $groupId not found');
    }

    final user = await _databaseHelper.getUser(userId);
    if (user == null) {
      throw ArgumentError('User with ID $userId not found');
    }

    await _databaseHelper.removeUserFromGroup(groupId, userId);
  }

  // Get all members of a group
  Future<List<User>> getGroupMembers(int groupId) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null) {
      throw ArgumentError('Group with ID $groupId not found');
    }

    return await _databaseHelper.getGroupMemberUsers(groupId);
  }

  // Get group membership details (with join dates)
  Future<List<GroupMemberDetail>> getGroupMemberDetails(int groupId) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null) {
      throw ArgumentError('Group with ID $groupId not found');
    }

    final members = await _databaseHelper.getGroupMembers(groupId);
    final memberDetails = <GroupMemberDetail>[];

    for (final member in members) {
      final user = await _databaseHelper.getUser(member.userId);
      if (user != null) {
        memberDetails.add(GroupMemberDetail(
          user: user,
          joinedAt: member.joinedAt,
          isActive: member.isActive,
        ));
      }
    }

    return memberDetails;
  }

  // Deactivate group (soft delete)
  Future<void> deactivateGroup(int id) async {
    final existingGroup = await _databaseHelper.getGroup(id);
    if (existingGroup == null) {
      throw ArgumentError('Group with ID $id not found');
    }

    // Check if group has any shared transactions
    // For now, we'll just deactivate - this could be enhanced to check transactions
    await _databaseHelper.deleteGroup(id);
  }

  // Get group summary statistics
  Future<GroupSummary> getGroupSummary(int groupId) async {
    final group = await _databaseHelper.getGroup(groupId);
    if (group == null) {
      throw ArgumentError('Group with ID $groupId not found');
    }

    final members = await getGroupMembers(groupId);
    
    // This would be enhanced with transaction data
    return GroupSummary(
      group: group,
      memberCount: members.length,
      members: members,
      totalSharedExpenses: 0.0, // To be calculated from transactions
      avgExpensePerMember: 0.0, // To be calculated from transactions
    );
  }

  // Initialize default groups and users (called during app setup)
  Future<void> initializeDefaultData() async {
    final existingGroups = await _databaseHelper.getAllGroups();
    if (existingGroups.isEmpty) {
      // Create default groups
      for (final defaultGroup in ExpenseGroup.getDefaultGroups()) {
        await _databaseHelper.insertGroup(defaultGroup);
      }
    }
  }

  // Check if user can be safely deleted (not part of any active groups with transactions)
  Future<bool> canDeleteUser(int userId) async {
    final userGroups = await getUserGroups(userId);
    // This would be enhanced to check if user has any shared transaction splits
    return userGroups.isEmpty;
  }

  // Check if group can be safely deleted (no active shared transactions)
  Future<bool> canDeleteGroup(int groupId) async {
    // This would be enhanced to check if group has any active shared transactions
    return true;
  }
}

// Data class for group member details
class GroupMemberDetail {
  final User user;
  final DateTime joinedAt;
  final bool isActive;

  GroupMemberDetail({
    required this.user,
    required this.joinedAt,
    required this.isActive,
  });

  @override
  String toString() {
    return 'GroupMemberDetail(user: ${user.name}, joinedAt: $joinedAt, isActive: $isActive)';
  }
}

// Data class for group summary
class GroupSummary {
  final ExpenseGroup group;
  final int memberCount;
  final List<User> members;
  final double totalSharedExpenses;
  final double avgExpensePerMember;

  GroupSummary({
    required this.group,
    required this.memberCount,
    required this.members,
    required this.totalSharedExpenses,
    required this.avgExpensePerMember,
  });

  @override
  String toString() {
    return 'GroupSummary(group: ${group.name}, memberCount: $memberCount, '
           'totalSharedExpenses: $totalSharedExpenses, avgExpensePerMember: $avgExpensePerMember)';
  }
}